import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pulse_logo.dart';

/// Keep in step with the package version in pubspec.yaml.
const netPulseVersion = '0.1.0';

/// Information about the SDK.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubScreen(
      title: 'About NetPulse',
      children: [
        const SizedBox(height: Insets.xl),
        const Center(child: PulseLogo(size: 72)),
        const SizedBox(height: Insets.lg),
        const Text(
          'NetPulse',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const Text('Connectivity Intelligence', textAlign: TextAlign.center),
        const SizedBox(height: Insets.xl),
        const Text(
          'Open-source connectivity monitoring and diagnostics SDK for '
          'Flutter.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: Insets.xl),
        AppCard(
          child: Column(
            children: [
              for (final feature in const [
                'Works on Android & iOS',
                'No backend required',
                'Offline-first, data stays on device',
                'Apache 2.0 License',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.green,
                        size: 20,
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'NetPulse',
            applicationVersion: netPulseVersion,
          ),
          icon: const Icon(Icons.description_rounded),
          label: const Text('Open-source Licenses'),
        ),
        const SizedBox(height: Insets.lg),
        const Text(
          'Version $netPulseVersion',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}
