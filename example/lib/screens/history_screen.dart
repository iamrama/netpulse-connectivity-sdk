import 'package:flutter/material.dart';
import 'package:netpulse_connectivity_sdk/netpulse_connectivity_sdk.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/formatting.dart';
import 'time_range.dart';

/// A timeline of locally stored events.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  TimeRange _range = TimeRange.day;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final entries = _range.filter(app.history);

    return ScreenBody(
      onRefresh: app.loadHistory,
      children: [
        const ScreenHeader(
          leading: Icon(
            Icons.calendar_month_rounded,
            size: 36,
            color: AppColors.blue,
          ),
          title: 'Network History',
          subtitle: 'Connection events & diagnostics',
        ),
        ErrorBanner(app.error),
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.xl),
          child: SegmentedButton<TimeRange>(
            showSelectedIcon: false,
            segments: [
              for (final range in TimeRange.values)
                ButtonSegment(value: range, label: Text(range.label)),
            ],
            selected: {_range},
            onSelectionChanged: (selection) =>
                setState(() => _range = selection.first),
          ),
        ),
        if (entries.isEmpty)
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(Insets.xl),
                child: Text(
                  'No events in this period.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          ),
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(entry: entries[i], isLast: i == entries.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final HistoryEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final state = entry.state;
    final network = connectionLabel(state.connectionType);
    final internet = internetLabel(state.internetStatus);
    final (title, detail, icon, color) = switch (entry.type) {
      HistoryEventType.connected => (
        '$network Connected',
        internet,
        connectionIcon(state.connectionType),
        statusColor(state),
      ),
      HistoryEventType.connectionLost => (
        'Connection Lost',
        'No Network',
        Icons.priority_high_rounded,
        AppColors.red,
      ),
      HistoryEventType.networkChanged => (
        'Network Switched',
        '$network • $internet',
        connectionIcon(state.connectionType),
        AppColors.blue,
      ),
      HistoryEventType.internetRestored => (
        'Internet Restored',
        network,
        Icons.check_rounded,
        AppColors.green,
      ),
      HistoryEventType.internetLost => (
        'Internet Lost',
        '$network • $internet',
        Icons.cloud_off_rounded,
        AppColors.red,
      ),
      HistoryEventType.diagnostics => (
        'Diagnostics ${entry.passed == true ? 'Passed' : 'Failed'}',
        'Quality: ${entry.qualityScore ?? 0}% • '
            '${formatLatency(entry.latency)}',
        Icons.troubleshoot_rounded,
        entry.passed == true ? AppColors.green : AppColors.amber,
      ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              IconBadge(icon: icon, color: color),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.cardBorder),
                ),
            ],
          ),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Insets.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDateTime(entry.timestamp),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(detail, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
