import 'package:netpulse/netpulse.dart';

/// History filters.
enum TimeRange {
  hour('1h', 'Last 1 Hour', Duration(hours: 1)),
  day('24h', 'Last 24 Hours', Duration(hours: 24)),
  week('7d', 'Last 7 Days', Duration(days: 7)),
  month('30d', 'Last 30 Days', Duration(days: 30));

  const TimeRange(this.label, this.title, this.duration);

  final String label;
  final String title;
  final Duration duration;

  List<HistoryEntry> filter(List<HistoryEntry> entries) {
    final since = DateTime.now().subtract(duration);
    return entries.where((e) => !e.timestamp.isBefore(since)).toList();
  }
}
