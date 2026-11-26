import 'core/netpulse_client.dart';
import 'errors/netpulse_exception.dart';
import 'models/connectivity_state.dart';
import 'models/diagnostics.dart';
import 'models/history_entry.dart';
import 'models/netpulse_config.dart';
import 'models/network_quality.dart';

/// The entry point of the NetPulse SDK.
///
/// Call [initialize] once before using any other member, and [dispose] when
/// connectivity intelligence is no longer needed. All failures surface as
/// [NetPulseException].
abstract final class NetPulse {
  static NetPulseClient? _client;
  static Future<void>? _initializing;
  static Future<void>? _disposing;

  /// Whether [initialize] has completed and [dispose] has not been called.
  static bool get isInitialized => _client != null;

  /// The active configuration.
  static NetPulseConfig get config => _require().config;

  /// Prepares storage and, unless disabled, starts monitoring.
  ///
  /// Throws [NetPulseErrorCode.alreadyInitialized] if already initialized or
  /// initializing. To change settings, call [dispose] first.
  static Future<void> initialize([
    NetPulseConfig config = const NetPulseConfig(),
  ]) {
    if (_client != null || _initializing != null) {
      return Future<void>.error(
        const NetPulseException(
          NetPulseErrorCode.alreadyInitialized,
          'NetPulse is already initialized. Call dispose() first.',
        ),
        StackTrace.current,
      );
    }
    return _initializing = _initialize(config).whenComplete(() {
      _initializing = null;
    });
  }

  static Future<void> _initialize(NetPulseConfig config) async {
    await _disposing;
    _client = await NetPulseClient.create(config);
  }

  /// Stops monitoring and releases resources. Safe to call at any time.
  static Future<void> dispose() {
    final current = _disposing;
    if (current != null && _initializing == null) return current;
    late final Future<void> next;
    next = _dispose().whenComplete(() {
      if (identical(_disposing, next)) _disposing = null;
    });
    return _disposing = next;
  }

  static Future<void> _dispose() async {
    final pending = _initializing;
    if (pending != null) {
      try {
        await pending;
      } on Object {
        // A failed initialization leaves nothing to release; its caller
        // receives the error.
      }
    }
    final client = _client;
    _client = null;
    await client?.dispose();
  }

  /// Connectivity changes, starting with the latest known state.
  ///
  /// This is a broadcast stream that closes on [dispose]. It emits nothing
  /// when [NetPulseConfig.enableMonitoring] is false.
  static Stream<ConnectivityState> get connectivityStream =>
      _require().connectivityStream;

  /// Takes a snapshot of current connectivity.
  static Future<ConnectivityState> getCurrentState() =>
      _require().getCurrentState();

  /// Tests reachability, DNS, TCP and HTTP against [endpoint], which defaults
  /// to [NetPulseConfig.probeEndpoint].
  ///
  /// Network failures are described in the result rather than thrown.
  static Future<DiagnosticsResult> runDiagnostics({Uri? endpoint}) =>
      _require().runDiagnostics(endpoint: endpoint);

  /// Returns the quality of the connection to the configured endpoint.
  ///
  /// A measurement newer than [maxAge] is reused; otherwise diagnostics run.
  /// Pass [Duration.zero] to force a new measurement.
  static Future<NetworkQuality> getNetworkQuality({
    Duration maxAge = NetPulseClient.defaultQualityMaxAge,
  }) => _require().getNetworkQuality(maxAge: maxAge);

  /// Returns locally stored events, newest first.
  static Future<List<HistoryEntry>> getHistory({DateTime? since, int? limit}) =>
      _require().getHistory(since: since, limit: limit);

  /// Permanently deletes locally stored history.
  static Future<void> clearHistory() => _require().clearHistory();

  static NetPulseClient _require() =>
      _client ??
      (throw const NetPulseException(
        NetPulseErrorCode.notInitialized,
        'Call NetPulse.initialize() before using NetPulse.',
      ));
}
