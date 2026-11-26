import 'dart:async';

import '../../netpulse_platform_interface.dart';
import '../errors/netpulse_exception.dart';
import '../models/connectivity_state.dart';
import '../models/diagnostics.dart';
import '../models/history_entry.dart';
import '../models/internet_status.dart';
import '../models/netpulse_config.dart';
import '../models/network_quality.dart';
import 'diagnostics_runner.dart';
import 'history_store.dart';
import 'network_prober.dart';
import 'quality_calculator.dart';

/// One initialized session of NetPulse.
///
/// A client is used once: after [dispose] a new one must be created.
class NetPulseClient {
  NetPulseClient._(
    this.config,
    this._platform,
    this._prober,
    this._history,
    this._clock,
  ) : _runner = DiagnosticsRunner(_prober, clock: _clock);

  /// Validates [config], prepares storage and starts monitoring.
  static Future<NetPulseClient> create(
    NetPulseConfig config, {
    NetpulsePlatform? platform,
    NetworkProber prober = const IoNetworkProber(),
    DateTime Function()? clock,
  }) async {
    config.validate();
    final resolved = platform ?? NetpulsePlatform.instance;
    final now = clock ?? DateTime.now;
    final directory = config.persistHistory
        ? await resolved.getStorageDirectory()
        : null;
    final history = HistoryStore(
      directory: directory,
      maxEntries: config.maxHistoryEntries,
      retention: config.historyRetention,
      clock: now,
    );
    final client = NetPulseClient._(config, resolved, prober, history, now);
    await client._start();
    return client;
  }

  /// The configuration of this session.
  final NetPulseConfig config;

  final NetpulsePlatform _platform;
  final NetworkProber _prober;
  final HistoryStore _history;
  final DateTime Function() _clock;
  final DiagnosticsRunner _runner;

  final StreamController<ConnectivityState> _controller =
      StreamController<ConnectivityState>.broadcast();
  final Map<Uri, Future<DiagnosticsResult>> _running = {};
  StreamSubscription<ConnectivityState>? _subscription;
  ConnectivityState? _latest;
  ConnectivityState? _lastRecorded;
  NetworkQuality? _quality;
  Timer? _recheck;
  int _generation = 0;
  bool _disposed = false;

  /// How long [getNetworkQuality] reuses a measurement by default.
  static const Duration defaultQualityMaxAge = Duration(minutes: 1);

  Future<void> _start() async {
    if (!config.enableMonitoring) return;
    try {
      final entries = await _history.read();
      for (final entry in entries.reversed) {
        if (entry.type != HistoryEventType.diagnostics) {
          _lastRecorded = entry.state;
          break;
        }
      }
    } on NetPulseException catch (error, stackTrace) {
      // Monitoring still works if history is unreadable.
      scheduleMicrotask(() => _emitError(error, stackTrace));
    }
    _subscription = _platform.connectivityChanges.listen(
      _onPlatformState,
      onError: _emitError,
    );
  }

  /// Emits the latest known state to each new listener, then every change.
  Stream<ConnectivityState> get connectivityStream {
    _ensureActive();
    return Stream<ConnectivityState>.multi((listener) {
      if (_disposed) {
        listener.close();
        return;
      }
      final latest = _latest;
      if (latest != null) listener.add(latest);
      final subscription = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  /// A fresh snapshot, verified if configured and necessary.
  ///
  /// While monitoring, the snapshot also updates [connectivityStream].
  Future<ConnectivityState> getCurrentState() async {
    _ensureActive();
    final generation = _generation;
    var state = await _platform.getCurrentState();
    _ensureActive();
    if (_needsVerification(state)) {
      state = await _verify(state);
      _ensureActive();
    }
    if (config.enableMonitoring && generation == _generation) {
      await _settle(state);
    }
    return state;
  }

  /// Runs diagnostics. Concurrent calls for one endpoint share a single run.
  Future<DiagnosticsResult> runDiagnostics({Uri? endpoint}) {
    _ensureActive();
    final target = endpoint ?? config.probeUri;
    if (!NetPulseConfig.isValidEndpoint(target)) {
      throw const NetPulseException(
        NetPulseErrorCode.invalidArgument,
        'endpoint must be an absolute http or https URL.',
      );
    }
    return _running[target] ??= _diagnose(target).whenComplete(() {
      _running.remove(target);
    });
  }

  Future<DiagnosticsResult> _diagnose(Uri endpoint) async {
    final connectivity = await _platform.getCurrentState();
    final result = await _runner.run(
      endpoint: endpoint,
      connectivity: connectivity,
      samples: config.diagnosticSamples,
      timeout: config.timeout,
    );
    if (_disposed) return result;

    final quality = QualityCalculator.fromDiagnostics(result);
    // Only the configured endpoint, measured on the network that is still
    // active, represents "network quality".
    final sameNetwork =
        _latest == null ||
        _latest!.connectionType == connectivity.connectionType;
    if (endpoint == config.probeUri && sameNetwork) _quality = quality;

    final reached =
        result.step(DiagnosticTest.internetReachability).status ==
        DiagnosticStatus.passed;
    await _record(
      HistoryEntry(
        type: HistoryEventType.diagnostics,
        state: connectivity.copyWith(
          internetStatus: reached
              ? InternetStatus.available
              : connectivity.isConnected
              ? connectivity.internetStatus
              : InternetStatus.unavailable,
          timestamp: result.completedAt,
        ),
        qualityScore: quality.score,
        latency: quality.averageLatency,
        passed: result.passed,
      ),
    );
    return result;
  }

  /// The latest measurement if newer than [maxAge], otherwise a new one.
  Future<NetworkQuality> getNetworkQuality({
    Duration maxAge = defaultQualityMaxAge,
  }) async {
    _ensureActive();
    final cached = _quality;
    if (cached != null && _clock().difference(cached.measuredAt) < maxAge) {
      return cached;
    }
    final result = await runDiagnostics();
    _ensureActive();
    return QualityCalculator.fromDiagnostics(result);
  }

  /// Stored entries, newest first.
  Future<List<HistoryEntry>> getHistory({DateTime? since, int? limit}) async {
    _ensureActive();
    if (limit != null && limit < 0) {
      throw const NetPulseException(
        NetPulseErrorCode.invalidArgument,
        'limit must not be negative.',
      );
    }
    final entries = await _history.read();
    final matches = entries.reversed.where(
      (e) => since == null || !e.timestamp.isBefore(since),
    );
    return List.unmodifiable(limit == null ? matches : matches.take(limit));
  }

  /// Deletes all stored entries.
  Future<void> clearHistory() async {
    _ensureActive();
    await _history.clear();
  }

  /// Stops monitoring and closes the stream. Safe to call repeatedly.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _recheck?.cancel();
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    // Not awaited: a paused listener would otherwise delay disposal forever.
    unawaited(_controller.close());
    await _history.flush();
  }

  Future<void> _onPlatformState(ConnectivityState state) async {
    if (_disposed) return;
    // Any newer event makes earlier verification results obsolete.
    final generation = ++_generation;
    _recheck?.cancel();
    if (!_needsVerification(state)) {
      await _settle(state);
      return;
    }
    // Avoid flickering to "unknown" while re-verifying the same network.
    final latest = _latest;
    if (latest == null || latest.connectionType != state.connectionType) {
      _publish(state);
    }
    final verified = await _verify(state);
    if (_disposed || generation != _generation) return;
    await _settle(verified);
    _scheduleRecheck(state, verified);
  }

  /// Repeats verification of [raw] until the internet is confirmed or the
  /// platform reports a change.
  void _scheduleRecheck(ConnectivityState raw, ConnectivityState verified) {
    _recheck?.cancel();
    if (verified.hasInternet || config.recheckInterval == Duration.zero) return;
    final generation = _generation;
    _recheck = Timer(config.recheckInterval, () async {
      final next = await _verify(raw);
      if (_disposed || generation != _generation) return;
      await _settle(next);
      _scheduleRecheck(raw, next);
    });
  }

  /// Publishes a settled state and records any resulting history event.
  Future<void> _settle(ConnectivityState state) {
    _publish(state);
    // The transition is computed synchronously so that events stay ordered.
    return _record(_transition(state));
  }

  bool _needsVerification(ConnectivityState state) =>
      config.verifyInternetAccess &&
      state.isConnected &&
      state.internetStatus == InternetStatus.unknown;

  Future<ConnectivityState> _verify(ConnectivityState state) async {
    var status = InternetStatus.unavailable;
    try {
      final code = await _prober.head(config.probeUri, config.timeout);
      if (DiagnosticsRunner.isSuccessStatus(code)) {
        status = InternetStatus.available;
      } else {
        // A server answered but not as expected: nothing can be concluded.
        status = InternetStatus.unknown;
      }
    } on Exception {
      status = InternetStatus.unavailable;
    }
    return state.copyWith(internetStatus: status, timestamp: _clock());
  }

  void _publish(ConnectivityState state) {
    final latest = _latest;
    if (latest != null && latest.isSameAs(state)) return;
    // A measurement of another network is no longer meaningful.
    if (latest != null && latest.connectionType != state.connectionType) {
      _quality = null;
    }
    _latest = state;
    if (!_controller.isClosed) _controller.add(state);
  }

  /// The history entry for moving from the last recorded state to [next].
  HistoryEntry? _transition(ConnectivityState next) {
    final previous = _lastRecorded;
    final HistoryEventType? type;
    if (previous == null) {
      type = next.isConnected
          ? HistoryEventType.connected
          : HistoryEventType.connectionLost;
    } else if (previous.isConnected != next.isConnected) {
      type = next.isConnected
          ? HistoryEventType.connected
          : HistoryEventType.connectionLost;
    } else if (!next.isConnected) {
      type = null;
    } else if (previous.connectionType != next.connectionType) {
      type = HistoryEventType.networkChanged;
    } else if (next.internetStatus == InternetStatus.unknown) {
      type = null;
    } else if (!previous.hasInternet && next.hasInternet) {
      // "unknown" to "available" is confirmation, not a restoration.
      type = previous.internetStatus == InternetStatus.unknown
          ? null
          : HistoryEventType.internetRestored;
    } else if (previous.hasInternet && !next.hasInternet) {
      type = HistoryEventType.internetLost;
    } else {
      type = null;
    }
    // Remember every settled state, even those that create no entry.
    if (previous == null ||
        previous.connectionType != next.connectionType ||
        next.internetStatus != InternetStatus.unknown) {
      _lastRecorded = next;
    }
    return type == null ? null : HistoryEntry(type: type, state: next);
  }

  Future<void> _record(HistoryEntry? entry) async {
    if (entry == null) return;
    try {
      await _history.add(entry);
    } on NetPulseException catch (error, stackTrace) {
      _emitError(error, stackTrace);
    }
  }

  void _emitError(Object error, StackTrace stackTrace) {
    if (!_disposed && !_controller.isClosed) {
      _controller.addError(error, stackTrace);
    }
  }

  void _ensureActive() {
    if (_disposed) {
      throw const NetPulseException(
        NetPulseErrorCode.notInitialized,
        'NetPulse has been disposed.',
      );
    }
  }
}
