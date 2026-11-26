import 'dart:math' as math;

import '../models/diagnostics.dart';
import '../models/network_quality.dart';

/// Turns connection samples into a [NetworkQuality].
///
/// The score is a weighted sum of three components, each from 0 to 100:
///
/// * latency (50%): 100 at 50 ms or less, falling linearly to 0 at 1000 ms,
///   based on the average connect time;
/// * loss (35%): 100 with no failed samples, falling linearly to 0 when half
///   of the samples fail;
/// * jitter (15%): 100 at 5 ms or less, falling linearly to 0 at 200 ms.
class QualityCalculator {
  const QualityCalculator._();

  /// Scores the samples of a diagnostics [result].
  static NetworkQuality fromDiagnostics(DiagnosticsResult result) => calculate(
    samples: result.tcpSamples,
    attempted: result.attemptedSamples,
    measuredAt: result.completedAt,
  );

  /// Scores [samples] successful connections out of [attempted].
  static NetworkQuality calculate({
    required List<Duration> samples,
    required int attempted,
    required DateTime measuredAt,
  }) {
    final loss = attempted <= 0
        ? 1.0
        : ((attempted - samples.length) / attempted).clamp(0.0, 1.0);
    if (samples.isEmpty) {
      return NetworkQuality(
        score: 0,
        level: QualityLevel.offline,
        probeLossRatio: 1,
        sampleCount: math.max(attempted, 0),
        measuredAt: measuredAt,
      );
    }

    final averageMicros =
        samples.fold<int>(0, (sum, s) => sum + s.inMicroseconds) ~/
        samples.length;
    Duration? jitter;
    if (samples.length > 1) {
      var total = 0;
      for (var i = 1; i < samples.length; i++) {
        total += (samples[i].inMicroseconds - samples[i - 1].inMicroseconds)
            .abs();
      }
      jitter = Duration(microseconds: total ~/ (samples.length - 1));
    }

    final latencyScore = _scale(averageMicros / 1000, best: 50, worst: 1000);
    final lossScore = _scale(loss, best: 0, worst: 0.5);
    final jitterScore = _scale(
      (jitter?.inMicroseconds ?? 0) / 1000,
      best: 5,
      worst: 200,
    );
    final score =
        (0.5 * latencyScore + 0.35 * lossScore + 0.15 * jitterScore).round();

    return NetworkQuality(
      score: score,
      level: levelFor(score),
      averageLatency: Duration(microseconds: averageMicros),
      jitter: jitter,
      probeLossRatio: loss,
      sampleCount: attempted,
      measuredAt: measuredAt,
    );
  }

  /// The level of a score from a measurement with successful samples.
  static QualityLevel levelFor(int score) {
    if (score >= 90) return QualityLevel.excellent;
    if (score >= 70) return QualityLevel.good;
    if (score >= 50) return QualityLevel.fair;
    return QualityLevel.poor;
  }

  /// The median of a non-empty list.
  static Duration median(List<Duration> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) ~/ 2;
  }

  static double _scale(
    double value, {
    required double best,
    required double worst,
  }) => (100 * (worst - value) / (worst - best)).clamp(0.0, 100.0);
}
