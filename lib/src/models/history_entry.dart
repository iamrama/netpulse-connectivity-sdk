import 'package:flutter/foundation.dart';

import 'connectivity_state.dart';

/// What a [HistoryEntry] records.
enum HistoryEventType {
  /// A network became available.
  connected,

  /// All networks were lost.
  connectionLost,

  /// The default transport changed.
  networkChanged,

  /// Internet access returned on an existing network.
  internetRestored,

  /// Internet access was lost while the network stayed up.
  internetLost,

  /// A diagnostics run completed.
  diagnostics,
}

/// One locally stored event.
@immutable
class HistoryEntry {
  /// Creates an entry.
  const HistoryEntry({
    required this.type,
    required this.state,
    this.qualityScore,
    this.latency,
    this.passed,
  });

  /// Reads an entry written by [toMap]. Throws [FormatException] if invalid.
  factory HistoryEntry.fromMap(Map<Object?, Object?> map) {
    final type = HistoryEventType.values.asNameMap()[map['type']];
    final state = map['state'];
    if (type == null || state is! Map || state['timestamp'] is! int) {
      throw const FormatException('Invalid history entry.');
    }
    final latency = map['latencyMicros'];
    return HistoryEntry(
      type: type,
      state: ConnectivityState.fromMap(state.cast<Object?, Object?>()),
      qualityScore: map['qualityScore'] as int?,
      latency: latency is int ? Duration(microseconds: latency) : null,
      passed: map['passed'] as bool?,
    );
  }

  /// The kind of event.
  final HistoryEventType type;

  /// Connectivity at the time of the event.
  final ConnectivityState state;

  /// Quality score, for diagnostics entries.
  final int? qualityScore;

  /// Average latency, for diagnostics entries.
  final Duration? latency;

  /// Whether every check passed, for diagnostics entries.
  final bool? passed;

  /// When the event happened.
  DateTime get timestamp => state.timestamp;

  /// Serialises this entry.
  Map<String, Object?> toMap() => <String, Object?>{
    'type': type.name,
    'state': state.toMap(),
    'qualityScore': qualityScore,
    'latencyMicros': latency?.inMicroseconds,
    'passed': passed,
  };
}
