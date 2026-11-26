import 'package:flutter/foundation.dart';

import 'connection_type.dart';
import 'internet_status.dart';

/// An immutable snapshot of device connectivity.
@immutable
class ConnectivityState {
  /// Creates a snapshot.
  const ConnectivityState({
    required this.connectionType,
    required this.internetStatus,
    required this.timestamp,
    this.isMetered,
    this.isConstrained,
    this.isVpn,
  });

  /// Reads a snapshot from a platform channel or storage map.
  ///
  /// A missing timestamp defaults to the current time.
  factory ConnectivityState.fromMap(Map<Object?, Object?> map) {
    final millis = map['timestamp'];
    return ConnectivityState(
      connectionType: ConnectionType.parse(map['connectionType']),
      internetStatus: InternetStatus.parse(map['internetStatus']),
      timestamp: millis is int
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : DateTime.now(),
      isMetered: map['isMetered'] as bool?,
      isConstrained: map['isConstrained'] as bool?,
      isVpn: map['isVpn'] as bool?,
    );
  }

  /// The transport of the default network.
  final ConnectionType connectionType;

  /// Whether the internet can be reached.
  final InternetStatus internetStatus;

  /// When this snapshot was taken.
  final DateTime timestamp;

  /// Whether the network is metered or expensive. Null if not reported.
  final bool? isMetered;

  /// Whether data saving (Android Data Saver, iOS Low Data Mode) restricts
  /// this network. Null if not reported.
  final bool? isConstrained;

  /// Whether traffic goes through a VPN. Null when the OS cannot say (iOS).
  final bool? isVpn;

  /// Whether a network link exists. This does not imply internet access.
  bool get isConnected => connectionType != ConnectionType.none;

  /// Whether internet access has been confirmed.
  bool get hasInternet => internetStatus == InternetStatus.available;

  /// Returns a copy with the given fields replaced.
  ConnectivityState copyWith({
    ConnectionType? connectionType,
    InternetStatus? internetStatus,
    DateTime? timestamp,
  }) {
    return ConnectivityState(
      connectionType: connectionType ?? this.connectionType,
      internetStatus: internetStatus ?? this.internetStatus,
      timestamp: timestamp ?? this.timestamp,
      isMetered: isMetered,
      isConstrained: isConstrained,
      isVpn: isVpn,
    );
  }

  /// Serialises this snapshot.
  Map<String, Object?> toMap() => <String, Object?>{
    'connectionType': connectionType.name,
    'internetStatus': internetStatus.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isMetered': isMetered,
    'isConstrained': isConstrained,
    'isVpn': isVpn,
  };

  /// Whether [other] describes the same network, ignoring [timestamp].
  bool isSameAs(ConnectivityState other) =>
      connectionType == other.connectionType &&
      internetStatus == other.internetStatus &&
      isMetered == other.isMetered &&
      isConstrained == other.isConstrained &&
      isVpn == other.isVpn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityState &&
          isSameAs(other) &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    connectionType,
    internetStatus,
    timestamp,
    isMetered,
    isConstrained,
    isVpn,
  );

  @override
  String toString() =>
      'ConnectivityState(${connectionType.name}, ${internetStatus.name}, '
      '$timestamp)';
}
