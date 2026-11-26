import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A glowing circular gauge with an opening at the bottom.
class RingGauge extends StatelessWidget {
  const RingGauge({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
    this.size = 220,
  });

  /// From 0 to 1.
  final double progress;
  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.xxl),
      child: Center(
        child: SizedBox.square(
          dimension: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, inner) => CustomPaint(
              painter: _RingPainter(value, color),
              child: inner,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Insets.xxl),
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  static const _start = math.pi * 0.70;
  static const _sweep = math.pi * 1.60;
  static const _width = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      base..color = color.withValues(alpha: 0.12),
    );
    if (progress <= 0) return;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width * 1.6
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawArc(rect, _start, _sweep * progress, false, glow);
    canvas.drawArc(rect, _start, _sweep * progress, false, base..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
