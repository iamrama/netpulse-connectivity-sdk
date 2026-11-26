import 'package:flutter/material.dart';
import 'package:netpulse_connectivity_sdk/netpulse_connectivity_sdk.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/formatting.dart';
import '../widgets/ring_gauge.dart';
import '../widgets/trend_chart.dart';
import 'time_range.dart';

/// The quality score, its metrics and its trend.
class QualityScreen extends StatefulWidget {
  const QualityScreen({super.key});

  @override
  State<QualityScreen> createState() => _QualityScreenState();
}

class _QualityScreenState extends State<QualityScreen> {
  TimeRange _range = TimeRange.hour;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final quality = app.quality;
    final color = qualityColor(quality);

    return SubScreen(
      title: 'Network Quality',
      subtitle: 'Measured network performance',
      children: [
        ErrorBanner(app.error),
        RingGauge(
          progress: (quality?.score ?? 0) / 100,
          color: color,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.amber,
                size: 32,
              ),
              const SizedBox(height: Insets.sm),
              Text(
                quality == null ? '—' : '${quality.score}%',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _title(quality?.level),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Center(
            child: Text(
              _description(quality?.level),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        StatRow(
          tiles: [
            StatTile(
              icon: Icons.schedule_rounded,
              color: AppColors.blue,
              value: formatLatency(quality?.averageLatency),
              label: 'Avg Latency',
            ),
            StatTile(
              icon: Icons.verified_user_rounded,
              color: AppColors.green,
              value: quality == null
                  ? '—'
                  : formatPercent(quality.probeLossRatio),
              label: 'Probe Loss',
            ),
            StatTile(
              icon: Icons.bar_chart_rounded,
              color: AppColors.green,
              value: quality == null ? '—' : formatPercent(quality.reliability),
              label: 'Reliability',
            ),
          ],
        ),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Quality Trend',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  PopupMenuButton<TimeRange>(
                    initialValue: _range,
                    onSelected: (range) => setState(() => _range = range),
                    itemBuilder: (_) => [
                      for (final range in TimeRange.values)
                        PopupMenuItem(value: range, child: Text(range.title)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(Insets.sm),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_range.title),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.lg),
              TrendChart(entries: _range.filter(app.history), height: 130),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: app.isMeasuring ? null : app.measure,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(app.isMeasuring ? 'Measuring…' : 'Measure Again'),
        ),
      ],
    );
  }

  String _title(QualityLevel? level) => switch (level) {
    null => 'Not measured',
    QualityLevel.excellent => 'Excellent',
    QualityLevel.good => 'Good',
    QualityLevel.fair => 'Fair',
    QualityLevel.poor => 'Poor',
    QualityLevel.offline => 'Offline',
  };

  String _description(QualityLevel? level) => switch (level) {
    null => 'Run a measurement to rate this network.',
    QualityLevel.excellent =>
      'Connections to your endpoint are fast and stable.',
    QualityLevel.good => 'Your connection is responsive and mostly stable.',
    QualityLevel.fair => 'You may notice delays on this network.',
    QualityLevel.poor => 'This connection is slow or unreliable.',
    QualityLevel.offline => 'The endpoint could not be reached.',
  };
}
