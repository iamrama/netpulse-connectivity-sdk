import 'package:flutter/material.dart';
import 'package:netpulse/netpulse.dart';

import '../theme.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// The time, prefixed by the date when it is not today.
String formatDateTime(DateTime time) {
  final now = DateTime.now();
  final today =
      now.year == time.year && now.month == time.month && now.day == time.day;
  return today
      ? formatTime(time)
      : '${_months[time.month - 1]} ${time.day}, ${formatTime(time)}';
}

String formatLatency(Duration? latency) {
  if (latency == null) return '—';
  final millis = latency.inMicroseconds / 1000;
  return millis < 1 ? '<1 ms' : '${millis.round()} ms';
}

String formatPercent(double ratio) {
  final percent = ratio * 100;
  return percent == percent.roundToDouble()
      ? '${percent.round()}%'
      : '${percent.toStringAsFixed(1)}%';
}

String connectionLabel(ConnectionType type) => switch (type) {
  ConnectionType.wifi => 'Wi-Fi',
  ConnectionType.cellular => 'Mobile Data',
  ConnectionType.ethernet => 'Ethernet',
  ConnectionType.vpn => 'VPN',
  ConnectionType.bluetooth => 'Bluetooth',
  ConnectionType.other => 'Other Network',
  ConnectionType.none => 'No Network',
  ConnectionType.unknown => 'Unknown',
};

IconData connectionIcon(ConnectionType type) => switch (type) {
  ConnectionType.wifi => Icons.wifi_rounded,
  ConnectionType.cellular => Icons.cell_tower_rounded,
  ConnectionType.ethernet => Icons.settings_ethernet_rounded,
  ConnectionType.vpn => Icons.vpn_lock_rounded,
  ConnectionType.bluetooth => Icons.bluetooth_rounded,
  ConnectionType.other => Icons.lan_rounded,
  ConnectionType.none => Icons.wifi_off_rounded,
  ConnectionType.unknown => Icons.help_outline_rounded,
};

String internetLabel(InternetStatus status) => switch (status) {
  InternetStatus.available => 'Internet Available',
  InternetStatus.unavailable => 'No Internet',
  InternetStatus.captivePortal => 'Sign-in Required',
  InternetStatus.unknown => 'Internet Unverified',
};

Color statusColor(ConnectivityState? state) {
  if (state == null) return AppColors.muted;
  if (!state.isConnected) return AppColors.red;
  return switch (state.internetStatus) {
    InternetStatus.available => AppColors.green,
    InternetStatus.unavailable => AppColors.red,
    InternetStatus.captivePortal ||
    InternetStatus.unknown => AppColors.amber,
  };
}

Color qualityColor(NetworkQuality? quality) => switch (quality?.level) {
  null => AppColors.muted,
  QualityLevel.excellent || QualityLevel.good => AppColors.green,
  QualityLevel.fair || QualityLevel.poor => AppColors.amber,
  QualityLevel.offline => AppColors.red,
};
