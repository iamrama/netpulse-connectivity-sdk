import 'package:flutter/foundation.dart';

import 'connectivity_state.dart';

/// The individual checks of a diagnostics run.
enum DiagnosticTest {
  /// Whether the endpoint answered at all.
  internetReachability,

  /// Resolving the endpoint's host name.
  dnsResolution,

  /// Opening TCP connections to the endpoint.
  tcpConnection,

  /// Time until the response headers of an HTTP `HEAD` request.
  httpLatency,
}

/// The outcome of a [DiagnosticTest].
enum DiagnosticStatus {
  /// The check succeeded.
  passed,

  /// The check failed.
  failed,

  /// The check did not run, because it was unnecessary or a prerequisite
  /// failed.
  skipped,
}

/// The result of one check.
@immutable
class DiagnosticStep {
  /// Creates a step result.
  const DiagnosticStep({
    required this.test,
    required this.status,
    this.duration,
    this.message,
  });

  /// Which check this is.
  final DiagnosticTest test;

  /// Whether it passed.
  final DiagnosticStatus status;

  /// The measured duration, when the check succeeded and was timed. For
  /// [DiagnosticTest.tcpConnection] this is the median of successful samples.
  final Duration? duration;

  /// Extra detail, usually the reason for a failure or a skip.
  final String? message;
}

/// The complete result of `NetPulse.runDiagnostics()`.
@immutable
class DiagnosticsResult {
  /// Creates a result.
  DiagnosticsResult({
    required this.endpoint,
    required this.startedAt,
    required this.completedAt,
    required this.connectivity,
    required List<DiagnosticStep> steps,
    required List<Duration> tcpSamples,
    required this.attemptedSamples,
    this.httpStatusCode,
  }) : steps = List.unmodifiable(steps),
       tcpSamples = List.unmodifiable(tcpSamples);

  /// The endpoint that was tested.
  final Uri endpoint;

  /// When the run began.
  final DateTime startedAt;

  /// When the run finished.
  final DateTime completedAt;

  /// Connectivity reported by the OS when the run began.
  final ConnectivityState connectivity;

  /// Results in [DiagnosticTest] order.
  final List<DiagnosticStep> steps;

  /// Durations of the successful TCP connection samples.
  final List<Duration> tcpSamples;

  /// How many TCP samples were requested.
  final int attemptedSamples;

  /// The HTTP status received, if any.
  final int? httpStatusCode;

  /// Whether no check failed.
  bool get passed =>
      steps.every((step) => step.status != DiagnosticStatus.failed);

  /// The result of [test].
  DiagnosticStep step(DiagnosticTest test) =>
      steps.firstWhere((step) => step.test == test);
}
