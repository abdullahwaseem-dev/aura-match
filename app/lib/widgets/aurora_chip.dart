import 'package:flutter/material.dart';
import '../theme/aurora.dart';

enum ChipTone { match, missing, flag, neutral }

class AuroraChip extends StatelessWidget {
  const AuroraChip({super.key, required this.label, this.tone = ChipTone.neutral});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border) = switch (tone) {
      ChipTone.match => (AuroraColors.success, AuroraColors.success.withValues(alpha: 0.1), AuroraColors.success.withValues(alpha: 0.35)),
      ChipTone.missing => (const Color(0xFFFFB2B2), AuroraColors.danger.withValues(alpha: 0.08), AuroraColors.danger.withValues(alpha: 0.3)),
      ChipTone.flag => (AuroraColors.amber, AuroraColors.amber.withValues(alpha: 0.08), AuroraColors.amber.withValues(alpha: 0.3)),
      ChipTone.neutral => (AuroraColors.mist, Colors.white.withValues(alpha: 0.03), AuroraColors.line),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: AuroraText.mono.copyWith(color: fg, fontSize: 12),
      ),
    );
  }
}
