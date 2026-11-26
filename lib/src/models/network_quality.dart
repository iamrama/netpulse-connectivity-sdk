import 'package:flutter/foundation.dart';

/// A coarse rating derived from [NetworkQuality.score].
enum QualityLevel {
  /// Score 90 to 100.
  excellent,

  /// Score 70 to 89.
  good,

  /// Score 50 to 69.
  fair,

  /// Score below 50 with at least one successful sample.
  poor,

  /// No sample succeeded.
  offline,
}

/// A quality measurement computed from real TCP connection samples.
@immutable
class NetworkQuality {
  /// Creates a measurement.
  const NetworkQuality({
    required this.score,
    required this.level,
    required this.probeLossRatio,
    required this.sampleCount,
    required this.measuredAt,
    this.averageLatency,
    this.jitter,
  });

  /// 0 (unusable) to 100 (excellent).
  final int score;

  /// The rating for [score].
  final QualityLevel level;

  /// Mean TCP connect time of successful samples. Null if none succeeded.
  final Duration? averageLatency;

  /// Mean difference between consecutive samples. Null with fewer than two.
  final Duration? jitter;

  /// The fraction (0 to 1) of connection samples that failed.
  ///
  /// This is an application-level measure. It is not ICMP or IP packet loss,
  /// which mobile apps cannot measure without extra privileges.
  final double probeLossRatio;

  /// How many samples were attempted.
  final int sampleCount;

  /// When the samples were taken.
  final DateTime measuredAt;

  /// The fraction (0 to 1) of samples that succeeded.
  double get reliability => sampleCount == 0 ? 0 : 1 - probeLossRatio;
}
