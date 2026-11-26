import 'dart:async';
import 'dart:io';

import '../models/connectivity_state.dart';
import '../models/diagnostics.dart';
import 'network_prober.dart';
import 'quality_calculator.dart';

/// Runs the DNS, TCP and HTTP checks against one endpoint.
class DiagnosticsRunner {
  /// Creates a runner.
  DiagnosticsRunner(this._prober, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final NetworkProber _prober;
  final DateTime Function() _clock;

  /// Tests [endpoint]. Network failures are reported in the result, not thrown.
  Future<DiagnosticsResult> run({
    required Uri endpoint,
    required ConnectivityState connectivity,
    required int samples,
    required Duration timeout,
  }) async {
    final startedAt = _clock();

    // DNS.
    List<InternetAddress> addresses;
    DiagnosticStep dns;
    final literal = InternetAddress.tryParse(endpoint.host);
    if (literal != null) {
      addresses = [literal];
      dns = const DiagnosticStep(
        test: DiagnosticTest.dnsResolution,
        status: DiagnosticStatus.skipped,
        message: 'The endpoint is an IP address.',
      );
    } else {
      final stopwatch = Stopwatch()..start();
      try {
        addresses = await _prober.resolve(endpoint.host, timeout);
        dns = addresses.isEmpty
            ? _failed(DiagnosticTest.dnsResolution, 'No addresses returned.')
            : DiagnosticStep(
                test: DiagnosticTest.dnsResolution,
                status: DiagnosticStatus.passed,
                duration: stopwatch.elapsed,
              );
      } on Exception catch (error) {
        addresses = const [];
        dns = _failed(DiagnosticTest.dnsResolution, describe(error));
      }
    }

    // TCP. Samples run one after another so they do not compete.
    final tcpSamples = <Duration>[];
    var attempted = 0;
    final DiagnosticStep tcp;
    if (addresses.isEmpty) {
      attempted = samples;
      tcp = const DiagnosticStep(
        test: DiagnosticTest.tcpConnection,
        status: DiagnosticStatus.skipped,
        message: 'The host could not be resolved.',
      );
    } else {
      var address = addresses.first;
      String? lastError;
      // Pick the first address that accepts a connection, so that an
      // unreachable IPv6 route does not count as loss.
      for (final candidate in addresses) {
        try {
          tcpSamples.add(
            await _prober.connect(candidate, endpoint.port, timeout),
          );
          address = candidate;
          attempted = 1;
          break;
        } on Exception catch (error) {
          lastError = describe(error);
        }
      }
      if (attempted == 0) {
        // Every address failed: that is one attempted sample.
        attempted = 1;
      }
      while (attempted < samples) {
        attempted++;
        try {
          tcpSamples.add(
            await _prober.connect(address, endpoint.port, timeout),
          );
        } on Exception catch (error) {
          lastError = describe(error);
        }
      }
      tcp = tcpSamples.isEmpty
          ? _failed(
              DiagnosticTest.tcpConnection,
              lastError ?? 'Connection failed.',
            )
          : DiagnosticStep(
              test: DiagnosticTest.tcpConnection,
              status: DiagnosticStatus.passed,
              duration: QualityCalculator.median(tcpSamples),
              message: tcpSamples.length < attempted
                  ? '${attempted - tcpSamples.length} of $attempted '
                        'samples failed.'
                  : null,
            );
    }

    // HTTP. Always attempted: behind a proxy it can succeed when direct
    // sockets cannot.
    int? statusCode;
    DiagnosticStep http;
    final stopwatch = Stopwatch()..start();
    try {
      statusCode = await _prober.head(endpoint, timeout);
      http = isSuccessStatus(statusCode)
          ? DiagnosticStep(
              test: DiagnosticTest.httpLatency,
              status: DiagnosticStatus.passed,
              duration: stopwatch.elapsed,
              message: 'HTTP $statusCode',
            )
          : _failed(DiagnosticTest.httpLatency, 'HTTP $statusCode');
    } on Exception catch (error) {
      http = _failed(DiagnosticTest.httpLatency, describe(error));
    }

    final reachability = statusCode != null
        ? const DiagnosticStep(
            test: DiagnosticTest.internetReachability,
            status: DiagnosticStatus.passed,
          )
        : _failed(
            DiagnosticTest.internetReachability,
            connectivity.isConnected
                ? 'The endpoint did not respond.'
                : 'No network connection.',
          );

    return DiagnosticsResult(
      endpoint: endpoint,
      startedAt: startedAt,
      completedAt: _clock(),
      connectivity: connectivity,
      steps: [reachability, dns, tcp, http],
      tcpSamples: tcpSamples,
      attemptedSamples: attempted,
      httpStatusCode: statusCode,
    );
  }

  /// Whether an HTTP status counts as a successful probe.
  static bool isSuccessStatus(int status) => status >= 200 && status < 400;

  /// A short description of a network [error].
  static String describe(Object error) => switch (error) {
    TimeoutException() => 'Timed out.',
    SocketException(:final message) => message,
    HandshakeException() => 'TLS handshake failed.',
    HttpException(:final message) => message,
    _ => error.toString(),
  };

  static DiagnosticStep _failed(DiagnosticTest test, String message) =>
      DiagnosticStep(
        test: test,
        status: DiagnosticStatus.failed,
        message: message,
      );
}
