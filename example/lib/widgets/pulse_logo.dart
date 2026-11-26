import 'package:flutter/material.dart';

import '../theme.dart';

/// The demo's pulse mark.
class PulseLogo extends StatelessWidget {
  const PulseLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.monitor_heart_outlined,
    size: size,
    color: AppColors.blue,
    semanticLabel: 'NetPulse',
  );
}
