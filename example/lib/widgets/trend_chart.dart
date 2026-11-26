import 'package:flutter/material.dart';
import 'package:netpulse_connectivity_sdk/netpulse_connectivity_sdk.dart';

import '../theme.dart';
import 'formatting.dart';

/// A chart of the quality scores recorded by diagnostics runs.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.entries, this.height = 110});

  /// History entries in any order; those without a score are ignored.
  final List<HistoryEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final points = entries.where((e) => e.qualityScore != null).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    const axis = TextStyle(color: AppColors.muted, fontSize: 11);

    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Run diagnostics to start a quality trend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('100', style: axis),
                  Text('50', style: axis),
                  Text('0', style: axis),
                ],
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Semantics(
                  label:
                      'Quality trend, latest score '
                      '${points.last.qualityScore}',
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _TrendPainter(points),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDateTime(points.first.timestamp), style: axis),
            if (points.length > 1)
              Text(formatDateTime(points.last.timestamp), style: axis),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.points);

  final List<HistoryEntry> points;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 5.0;
    final first = points.first.timestamp.millisecondsSinceEpoch;
    final span = points.last.timestamp.millisecondsSinceEpoch - first;

    Offset position(HistoryEntry e) {
      final x = span == 0
          ? 0.5
          : (e.timestamp.millisecondsSinceEpoch - first) / span;
      final y = 1 - e.qualityScore!.clamp(0, 100) / 100;
      return Offset(
        inset + x * (size.width - inset * 2),
        inset + y * (size.height - inset * 2),
      );
    }

    final offsets = points.map(position).toList();
    final stroke = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    if (offsets.length > 1) {
      final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final point in offsets.skip(1)) {
        line.lineTo(point.dx, point.dy);
      }
      final area = Path.from(line)
        ..lineTo(offsets.last.dx, size.height)
        ..lineTo(offsets.first.dx, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.green.withValues(alpha: 0.35),
              AppColors.green.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(line, stroke);
    }
    canvas.drawCircle(offsets.last, 4, Paint()..color = AppColors.green);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.points != points;
}
