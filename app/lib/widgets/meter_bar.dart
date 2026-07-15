import 'package:flutter/material.dart';
import '../theme/aurora.dart';

/// Horizontal category meter — used on the Hiring Manager scorecard.
class MeterBar extends StatelessWidget {
  const MeterBar({super.key, required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AuroraText.bodySm.copyWith(color: AuroraColors.mist))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AuroraRadius.pill),
              child: Container(
                height: 8,
                color: Colors.white.withValues(alpha: 0.06),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
                  duration: AuroraMotion.scoreReveal,
                  curve: AuroraMotion.auroraEase,
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(decoration: const BoxDecoration(gradient: AuroraColors.aurora)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.smd),
          SizedBox(
            width: 30,
            child: Text(score.toString(), textAlign: TextAlign.right, style: AuroraText.mono.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
