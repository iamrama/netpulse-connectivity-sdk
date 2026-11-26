import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Edits the endpoint and test options.
class DiagnosticsSettingsScreen extends StatefulWidget {
  const DiagnosticsSettingsScreen({super.key});

  @override
  State<DiagnosticsSettingsScreen> createState() =>
      _DiagnosticsSettingsScreenState();
}

class _DiagnosticsSettingsScreenState extends State<DiagnosticsSettingsScreen> {
  final _endpoint = TextEditingController();
  double _samples = 5;
  double _timeout = 5;
  bool _verify = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final config = AppScope.of(context).config;
    _endpoint.text = config.probeEndpoint;
    _samples = config.diagnosticSamples.toDouble();
    _timeout = config.timeout.inSeconds.clamp(1, 15).toDouble();
    _verify = config.verifyInternetAccess;
  }

  @override
  void dispose() {
    _endpoint.dispose();
    super.dispose();
  }

  Future<void> _save(AppController app) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await app.applyConfig(
      app.config.copyWith(
        probeEndpoint: _endpoint.text.trim(),
        diagnosticSamples: _samples.round(),
        timeout: Duration(seconds: _timeout.round()),
        verifyInternetAccess: _verify,
      ),
    );
    if (!mounted) return;
    final error = app.error;
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Settings saved')));
    if (error == null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return SubScreen(
      title: 'Diagnostics Settings',
      subtitle: 'Configure test options',
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.lg),
          child: TextField(
            controller: _endpoint,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Probe endpoint'),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connection samples: ${_samples.round()}'),
              Slider(
                value: _samples,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (v) => setState(() => _samples = v),
              ),
              const SizedBox(height: Insets.sm),
              Text('Timeout: ${_timeout.round()} s'),
              Slider(
                value: _timeout,
                min: 1,
                max: 15,
                divisions: 14,
                onChanged: (v) => setState(() => _timeout = v),
              ),
            ],
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Insets.lg,
              vertical: Insets.sm,
            ),
            title: const Text('Verify internet access'),
            subtitle: const Text(
              'Send a HEAD request when the OS cannot confirm access',
            ),
            value: _verify,
            onChanged: (v) => setState(() => _verify = v),
          ),
        ),
        FilledButton(
          onPressed: app.isConfiguring ? null : () => _save(app),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
