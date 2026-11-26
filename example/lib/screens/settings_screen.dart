import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'diagnostics_settings_screen.dart';
import 'history_settings_screen.dart';
import 'privacy_screen.dart';

/// SDK configuration.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    void open(Widget screen) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    void toggle(bool value) =>
        app.applyConfig(app.config.copyWith(enableMonitoring: value));

    return ScreenBody(
      children: [
        const ScreenHeader(
          leading: Icon(
            Icons.settings_rounded,
            size: 36,
            color: AppColors.blue,
          ),
          title: 'Settings',
          subtitle: 'Configure NetPulse SDK',
        ),
        ErrorBanner(app.error),
        ActionCard(
          icon: Icons.sensors_rounded,
          title: 'Monitoring Settings',
          subtitle: 'Enable connectivity monitoring',
          trailing: Switch(
            value: app.config.enableMonitoring,
            onChanged: app.isConfiguring ? null : toggle,
          ),
        ),
        ActionCard(
          icon: Icons.tune_rounded,
          title: 'Diagnostics Settings',
          subtitle: 'Configure test options',
          onTap: () => open(const DiagnosticsSettingsScreen()),
        ),
        ActionCard(
          icon: Icons.inventory_2_rounded,
          title: 'History Settings',
          subtitle: 'Manage local data',
          onTap: () => open(const HistorySettingsScreen()),
        ),
        ActionCard(
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy & Permissions',
          subtitle: 'Learn about data usage',
          onTap: () => open(const PrivacyScreen()),
        ),
        ActionCard(
          icon: Icons.info_rounded,
          title: 'About NetPulse',
          subtitle: 'Version $netPulseVersion',
          onTap: () => open(const AboutScreen()),
        ),
      ],
    );
  }
}
