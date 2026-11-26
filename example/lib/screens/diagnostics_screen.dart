import 'package:flutter/material.dart';
import 'package:netpulse/netpulse.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/formatting.dart';
import 'diagnostics_settings_screen.dart';

/// Runs and presents network diagnostics.
class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final result = app.diagnostics;

    return ScreenBody(
      children: [
        const ScreenHeader(
          title: 'Diagnostics',
          subtitle: 'Run comprehensive network tests',
        ),
        ErrorBanner(app.error),
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.xl),
          child: FilledButton.icon(
            onPressed: app.isMeasuring || app.isConfiguring
                ? null
                : app.measure,
            icon: app.isMeasuring
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(app.isMeasuring ? 'Running…' : 'Run Diagnostics'),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Results',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: Insets.xs),
                        Text(
                          result == null
                              ? 'No results for this network yet'
                              : 'Last run: '
                                    '${formatDateTime(result.completedAt)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (result != null)
                    Pill(
                      icon: Icons.bolt_rounded,
                      label: result.passed ? 'Passed' : 'Failed',
                      color: result.passed ? AppColors.green : AppColors.red,
                    ),
                ],
              ),
              const SizedBox(height: Insets.md),
              for (final test in DiagnosticTest.values)
                _TestRow(test: test, step: result?.step(test)),
            ],
          ),
        ),
        if (result != null)
          AppCard(
            child: Row(
              children: [
                IconBadge(
                  icon: result.passed
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  color: result.passed ? AppColors.green : AppColors.red,
                ),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Insets.xs),
                      Text(
                        _summary(result),
                        style: TextStyle(
                          color: result.passed
                              ? AppColors.green
                              : AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ActionCard(
          icon: Icons.link_rounded,
          title: 'Endpoint',
          subtitle: app.config.probeEndpoint,
          trailing: const Icon(Icons.edit_rounded, size: 20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DiagnosticsSettingsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  String _summary(DiagnosticsResult result) {
    final failed = result.steps
        .where((s) => s.status == DiagnosticStatus.failed)
        .length;
    if (failed == 0) return 'All tests passed successfully';
    return failed == 1 ? '1 test failed' : '$failed tests failed';
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({required this.test, required this.step});

  final DiagnosticTest test;
  final DiagnosticStep? step;

  @override
  Widget build(BuildContext context) {
    final (title, icon) = switch (test) {
      DiagnosticTest.internetReachability => (
        'Internet Reachability',
        Icons.language_rounded,
      ),
      DiagnosticTest.dnsResolution => ('DNS Resolution', Icons.dns_rounded),
      DiagnosticTest.tcpConnection => ('TCP Connection', Icons.storage_rounded),
      DiagnosticTest.httpLatency => ('HTTP Latency', Icons.cloud_rounded),
    };
    final current = step;
    final (color, mark) = switch (current?.status) {
      DiagnosticStatus.passed => (AppColors.green, Icons.check_circle_rounded),
      DiagnosticStatus.failed => (AppColors.red, Icons.cancel_rounded),
      DiagnosticStatus.skipped => (
        AppColors.muted,
        Icons.remove_circle_rounded,
      ),
      null => (AppColors.muted, Icons.radio_button_unchecked_rounded),
    };
    final detail = switch (current?.status) {
      DiagnosticStatus.passed =>
        current!.duration == null ? 'Success' : formatLatency(current.duration),
      DiagnosticStatus.failed => current!.message ?? 'Failed',
      DiagnosticStatus.skipped => current!.message ?? 'Skipped',
      null => 'Not run',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 28),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: Insets.xs),
                Text(detail, style: TextStyle(color: color, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: Insets.md),
          Icon(mark, color: color, semanticLabel: current?.status.name),
        ],
      ),
    );
  }
}
