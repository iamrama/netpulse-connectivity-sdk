import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../widgets/common.dart';

/// Explains permissions and data use.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final endpoint = AppScope.of(context).config.probeEndpoint;
    return SubScreen(
      title: 'Privacy & Permissions',
      subtitle: 'How NetPulse uses data',
      children: [
        const ActionCard(
          icon: Icons.network_check_rounded,
          title: 'Network state',
          subtitle: 'Android ACCESS_NETWORK_STATE reads connectivity.',
          trailing: SizedBox.shrink(),
        ),
        ActionCard(
          icon: Icons.public_rounded,
          title: 'Internet',
          subtitle: 'Probes and diagnostics contact only $endpoint.',
          trailing: const SizedBox.shrink(),
        ),
        const ActionCard(
          icon: Icons.phone_android_rounded,
          title: 'Local storage',
          subtitle: 'History stays in private app storage on this device.',
          trailing: SizedBox.shrink(),
        ),
        const ActionCard(
          icon: Icons.block_rounded,
          title: 'No tracking',
          subtitle: 'No analytics, accounts or backend. No location access.',
          trailing: SizedBox.shrink(),
        ),
      ],
    );
  }
}
