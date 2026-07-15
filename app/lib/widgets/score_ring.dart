import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/aurora.dart';

/// Circular score readout — conic gradient ring with the number centered.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 104, this.label});

  final int score;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble().clamp(0, 100)),
      duration: AuroraMotion.scoreReveal,
      curve: AuroraMotion.auroraEase,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(percent: value / 100),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.round().toString(),
                    style: AuroraText.displayL.copyWith(fontSize: size * 0.26),
                  ),
                  if (label != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(label!, style: AuroraText.caption.copyWith(fontSize: 9)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    if (percent <= 0) return;
    // SweepGradient's startAngle/endAngle must satisfy 0 <= startAngle < endAngle
    // <= 2*pi (dart:ui asserts this) — the 12-o'clock start position comes from
    // the GradientRotation transform below, not from a negative startAngle.
    final sweep = (2 * math.pi * percent).clamp(0.0, 2 * math.pi);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: sweep,
        colors: const [AuroraColors.cyan, AuroraColors.violet],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.percent != percent;
}
