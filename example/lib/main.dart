import 'package:flutter/material.dart';
import 'package:netpulse/netpulse.dart';

import 'app_controller.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

void main() {
  runApp(const NetPulseExampleApp());
}

/// The NetPulse demo application.
class NetPulseExampleApp extends StatefulWidget {
  const NetPulseExampleApp({
    super.key,
    this.config = const NetPulseConfig(),
    this.autoMeasure = true,
  });

  /// The configuration the SDK starts with.
  final NetPulseConfig config;

  /// Whether to run diagnostics on start and when the network changes.
  final bool autoMeasure;

  @override
  State<NetPulseExampleApp> createState() => _NetPulseExampleAppState();
}

class _NetPulseExampleAppState extends State<NetPulseExampleApp> {
  late final AppController _controller = AppController(
    config: widget.config,
    autoMeasure: widget.autoMeasure,
  );

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'NetPulse',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
