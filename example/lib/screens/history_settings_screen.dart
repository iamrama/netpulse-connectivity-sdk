import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Manages stored history.
class HistorySettingsScreen extends StatelessWidget {
  const HistorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final config = app.config;

    Widget choices(
      String title,
      List<int> values,
      int selected,
      String Function(int) label,
      ValueChanged<int> onSelected,
    ) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: Insets.md),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.sm,
              children: [
                for (final value in values)
                  ChoiceChip(
                    label: Text(label(value)),
                    selected: value == selected,
                    onSelected: app.isConfiguring
                        ? null
                        : (_) => onSelected(value),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return SubScreen(
      title: 'History Settings',
      subtitle: '${app.history.length} events stored',
      children: [
        ErrorBanner(app.error),
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Insets.lg,
              vertical: Insets.sm,
            ),
            title: const Text('Keep history after restart'),
            subtitle: const Text('Stored only on this device'),
            value: config.persistHistory,
            onChanged: app.isConfiguring
                ? null
                : (v) => app.applyConfig(config.copyWith(persistHistory: v)),
          ),
        ),
        choices(
          'Maximum events',
          const [100, 500, 1000],
          config.maxHistoryEntries,
          (v) => '$v',
          (v) => app.applyConfig(config.copyWith(maxHistoryEntries: v)),
        ),
        choices(
          'Retention',
          const [7, 30, 90],
          config.historyRetention.inDays,
          (v) => '$v days',
          (v) => app.applyConfig(
            config.copyWith(historyRetention: Duration(days: v)),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: app.history.isEmpty ? null : () => _confirm(context, app),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Clear History'),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, AppController app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('All stored events will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await app.clearHistory();
  }
}
