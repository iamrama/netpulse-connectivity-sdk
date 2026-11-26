import 'package:flutter/foundation.dart';

import '../errors/netpulse_exception.dart';

/// Settings applied by `NetPulse.initialize()`.
///
/// NetPulse has no backend. The only network traffic it creates is directed at
/// [probeEndpoint] (or an endpoint you pass to `runDiagnostics`).
@immutable
class NetPulseConfig {
  /// Creates a configuration.
  const NetPulseConfig({
    this.probeEndpoint = defaultProbeEndpoint,
    this.enableMonitoring = true,
    this.verifyInternetAccess = true,
    this.recheckInterval = const Duration(seconds: 15),
    this.timeout = const Duration(seconds: 5),
    this.diagnosticSamples = 5,
    this.persistHistory = true,
    this.maxHistoryEntries = 500,
    this.historyRetention = const Duration(days: 30),
  });

  /// The default value of [probeEndpoint].
  static const String defaultProbeEndpoint = 'https://example.com';

  /// The `http` or `https` URL used for verification and diagnostics.
  final String probeEndpoint;

  /// Whether to observe network changes while initialized.
  final bool enableMonitoring;

  /// Whether to send an HTTP `HEAD` request to [probeEndpoint] when the OS
  /// cannot confirm internet access (always the case on iOS).
  final bool verifyInternetAccess;

  /// How often to repeat verification while a network is connected but the
  /// internet has not been confirmed. [Duration.zero] disables rechecking.
  final Duration recheckInterval;

  /// The time limit for each network operation.
  final Duration timeout;

  /// How many TCP connection samples each diagnostics run takes (1 to 20).
  final int diagnosticSamples;

  /// Whether history survives app restarts. When false it is kept in memory.
  final bool persistHistory;

  /// The most history entries retained (1 to 5000).
  final int maxHistoryEntries;

  /// How long history entries are retained.
  final Duration historyRetention;

  /// [probeEndpoint] as a [Uri].
  Uri get probeUri => Uri.parse(probeEndpoint);

  /// Whether [uri] can be used as a probe endpoint.
  static bool isValidEndpoint(Uri uri) =>
      (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;

  /// Throws a [NetPulseException] if any value is invalid.
  void validate() {
    final uri = Uri.tryParse(probeEndpoint);
    if (uri == null || !isValidEndpoint(uri)) {
      _fail('probeEndpoint must be an absolute http or https URL.');
    }
    if (timeout <= Duration.zero) _fail('timeout must be positive.');
    if (recheckInterval.isNegative) {
      _fail('recheckInterval must not be negative.');
    }
    if (diagnosticSamples < 1 || diagnosticSamples > 20) {
      _fail('diagnosticSamples must be between 1 and 20.');
    }
    if (maxHistoryEntries < 1 || maxHistoryEntries > 5000) {
      _fail('maxHistoryEntries must be between 1 and 5000.');
    }
    if (historyRetention <= Duration.zero) {
      _fail('historyRetention must be positive.');
    }
  }

  Never _fail(String message) =>
      throw NetPulseException(NetPulseErrorCode.invalidArgument, message);

  /// Returns a copy with the given fields replaced.
  NetPulseConfig copyWith({
    String? probeEndpoint,
    bool? enableMonitoring,
    bool? verifyInternetAccess,
    Duration? recheckInterval,
    Duration? timeout,
    int? diagnosticSamples,
    bool? persistHistory,
    int? maxHistoryEntries,
    Duration? historyRetention,
  }) {
    return NetPulseConfig(
      probeEndpoint: probeEndpoint ?? this.probeEndpoint,
      enableMonitoring: enableMonitoring ?? this.enableMonitoring,
      verifyInternetAccess: verifyInternetAccess ?? this.verifyInternetAccess,
      recheckInterval: recheckInterval ?? this.recheckInterval,
      timeout: timeout ?? this.timeout,
      diagnosticSamples: diagnosticSamples ?? this.diagnosticSamples,
      persistHistory: persistHistory ?? this.persistHistory,
      maxHistoryEntries: maxHistoryEntries ?? this.maxHistoryEntries,
      historyRetention: historyRetention ?? this.historyRetention,
    );
  }
}
