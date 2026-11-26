import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:netpulse/netpulse.dart';

/// Presentation state of the demo. All data comes from the NetPulse package.
class AppController extends ChangeNotifier {
  AppController({required NetPulseConfig config, this.autoMeasure = true})
    : _config = config;

  final bool autoMeasure;

  NetPulseConfig _config;
  NetPulseConfig get config => _config;

  ConnectivityState? connectivity;
  DateTime? updatedAt;
  DiagnosticsResult? diagnostics;
  NetworkQuality? quality;
  List<HistoryEntry> history = const [];
  String? error;
  bool isMeasuring = false;
  bool isConfiguring = false;

  StreamSubscription<ConnectivityState>? _subscription;
  bool _disposed = false;

  /// Initializes the SDK.
  Future<void> start() => _configure(_config);

  /// Restarts the SDK with [next], restoring the old settings on failure.
  Future<void> applyConfig(NetPulseConfig next) => _configure(next);

  Future<void> _configure(NetPulseConfig next) async {
    if (isConfiguring) return;
    isConfiguring = true;
    error = null;
    _notify();
    final previous = _config;
    try {
      next.validate();
      await _subscription?.cancel();
      _subscription = null;
      await NetPulse.dispose();
      if (_disposed) return;
      await NetPulse.initialize(next);
      _config = next;
      if (next.probeEndpoint != previous.probeEndpoint) _clearMeasurement();
    } on NetPulseException catch (e) {
      error = e.message;
      if (!_disposed && !NetPulse.isInitialized) {
        await _guard(() => NetPulse.initialize(previous));
      }
    } finally {
      isConfiguring = false;
    }
    if (_disposed || !NetPulse.isInitialized) {
      _notify();
      return;
    }
    await _subscription?.cancel();
    _subscription = NetPulse.connectivityStream.listen(
      _onState,
      onError: (Object e) {
        error = e is NetPulseException ? e.message : '$e';
        _notify();
      },
    );
    if (!_config.enableMonitoring) {
      await _guard(() async => _onState(await NetPulse.getCurrentState()));
    }
    await loadHistory();
  }

  void _onState(ConnectivityState state) {
    final networkChanged =
        connectivity?.connectionType != state.connectionType;
    connectivity = state;
    updatedAt = DateTime.now();
    if (networkChanged) {
      // Measurements of the previous network no longer apply.
      _clearMeasurement();
      if (autoMeasure && state.isConnected) unawaited(measure());
    }
    _notify();
    unawaited(loadHistory());
  }

  void _clearMeasurement() {
    diagnostics = null;
    quality = null;
  }

  /// Runs diagnostics against the configured endpoint.
  Future<void> measure() async {
    if (isMeasuring || !NetPulse.isInitialized) return;
    isMeasuring = true;
    error = null;
    _notify();
    final network = connectivity?.connectionType;
    await _guard(() async {
      final result = await NetPulse.runDiagnostics();
      // Reuses the run above.
      final measured = await NetPulse.getNetworkQuality();
      if (network == connectivity?.connectionType) {
        diagnostics = result;
        quality = measured;
      }
    });
    isMeasuring = false;
    _notify();
    await loadHistory();
    // The network changed during the run, so measure the new one.
    if (autoMeasure &&
        network != connectivity?.connectionType &&
        (connectivity?.isConnected ?? false)) {
      await measure();
    }
  }

  /// Takes a new snapshot and measurement.
  Future<void> refresh() async {
    await _guard(() async => _onState(await NetPulse.getCurrentState()));
    await measure();
  }

  Future<void> loadHistory() => _guard(() async {
    history = await NetPulse.getHistory();
  });

  Future<void> clearHistory() => _guard(() async {
    await NetPulse.clearHistory();
    history = const [];
  });

  Future<void> _guard(Future<void> Function() action) async {
    if (_disposed) return;
    try {
      await action();
    } on NetPulseException catch (e) {
      // Reconfiguring disposes the SDK; ignore calls that raced with it.
      if (e.code != NetPulseErrorCode.notInitialized) error = e.message;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    unawaited(NetPulse.dispose());
    super.dispose();
  }
}

/// Provides the [AppController] to the widget tree.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller; the caller rebuilds when it changes.
  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
