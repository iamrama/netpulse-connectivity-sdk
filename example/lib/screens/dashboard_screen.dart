import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netpulse/netpulse.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/formatting.dart';
import '../widgets/pulse_logo.dart';
import '../widgets/ring_gauge.dart';
import '../widgets/trend_chart.dart';
import 'quality_screen.dart';

/// Live network status.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final state = app.connectivity;
    final quality = app.quality;
    final color = statusColor(state);

    void openQuality() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const QualityScreen()),
      );
    }

    return ScreenBody(
      onRefresh: app.refresh,
      children: [
        ScreenHeader(
          leading: const PulseLogo(),
          title: 'NetPulse',
          subtitle: 'Connectivity Intelligence',
          trailing: _LivePill(
            monitoring: app.config.enableMonitoring,
            updatedAt: app.updatedAt,
          ),
        ),
        ErrorBanner(app.error),
        RingGauge(
          progress: state == null ? 0 : 1,
          color: color,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connectionIcon(state?.connectionType ?? ConnectionType.unknown),
                size: 48,
                color: color,
              ),
              const SizedBox(height: Insets.md),
              Text(
                state == null
                    ? 'Checking…'
                    : state.isConnected
                    ? 'Connected'
                    : 'Offline',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state != null) ...[
                const SizedBox(height: Insets.xs),
                Text(
                  internetLabel(state.internetStatus),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        ActionCard(
          icon: connectionIcon(state?.connectionType ?? ConnectionType.unknown),
          title: state == null ? '—' : connectionLabel(state.connectionType),
          subtitle: 'Connection Type',
          onTap: state == null ? null : () => _showDetails(context, state),
        ),
        const SizedBox(height: Insets.xs),
        StatRow(
          tiles: [
            StatTile(
              icon: Icons.bolt_rounded,
              color: AppColors.green,
              value: formatLatency(quality?.averageLatency),
              label: 'Latency',
              onTap: openQuality,
            ),
            StatTile(
              icon: Icons.star_rounded,
              color: AppColors.amber,
              value: quality == null ? '—' : '${quality.score}%',
              label: 'Quality',
              onTap: openQuality,
            ),
            StatTile(
              icon: Icons.shield_rounded,
              color: AppColors.blue,
              value: quality == null
                  ? '—'
                  : formatPercent(quality.probeLossRatio),
              label: 'Probe Loss',
              onTap: openQuality,
            ),
          ],
        ),
        if (app.isMeasuring)
          const Padding(
            padding: EdgeInsets.only(bottom: Insets.lg),
            child: LinearProgressIndicator(),
          ),
        AppCard(
          onTap: openQuality,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Network Overview',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Insets.lg),
              TrendChart(entries: app.history.take(100).toList()),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, ConnectivityState state) {
    String flag(bool? value) => value == null
        ? 'Not reported'
        : value
        ? 'Yes'
        : 'No';
    final rows = {
      'Connection': connectionLabel(state.connectionType),
      'Internet': internetLabel(state.internetStatus),
      'Metered': flag(state.isMetered),
      'Data restricted': flag(state.isConstrained),
      'VPN': flag(state.isVpn),
      'Updated': formatDateTime(state.timestamp),
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: Insets.screen,
          child: Column(
            children: [
              for (final row in rows.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.key,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      Text(row.value),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows how long ago the last connectivity update arrived.
class _LivePill extends StatefulWidget {
  const _LivePill({required this.monitoring, required this.updatedAt});

  final bool monitoring;
  final DateTime? updatedAt;

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.monitoring) {
      return const Pill(label: 'Paused', color: AppColors.muted);
    }
    final updated = widget.updatedAt;
    if (updated == null) {
      return const Pill(label: 'Starting', color: AppColors.amber);
    }
    final age = DateTime.now().difference(updated);
    final text = age.inSeconds < 60
        ? '${age.inSeconds}s'
        : age.inMinutes < 60
        ? '${age.inMinutes}m'
        : '${age.inHours}h';
    return Pill(label: 'Live • $text', color: AppColors.green);
  }
}
