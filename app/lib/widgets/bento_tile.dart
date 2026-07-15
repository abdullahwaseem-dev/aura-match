import 'package:flutter/material.dart';
import '../theme/aurora.dart';
import 'glass_container.dart';

/// A single bento-grid cell — a hover-interactive [GlassContainer] with the
/// label/value/sub-label slots used across every dashboard. Compose several
/// inside a [Row]/[Column]/[Wrap] to build a bento layout; Flutter has no
/// native spanning grid, so screens hand-compose spans with Expanded/flex
/// rather than a generic grid-span engine.
class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.label,
    this.value,
    this.valueStyle,
    this.sub,
    this.child,
    this.glow = AuroraColors.cyanGlow,
    this.onTap,
    this.height,
    this.alignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final String label;
  final String? value;
  final TextStyle? valueStyle;
  final String? sub;
  final Widget? child;
  final BoxShadow glow;
  final VoidCallback? onTap;
  final double? height;
  final CrossAxisAlignment alignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GlassContainer(
        interactive: true,
        glow: glow,
        onTap: onTap,
        padding: const EdgeInsets.all(AuroraSpacing.lg),
        child: child ??
            Column(
              crossAxisAlignment: alignment,
              mainAxisAlignment: mainAxisAlignment,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AuroraText.caption),
                if (value != null) ...[
                  const SizedBox(height: AuroraSpacing.sm),
                  Text(value!, style: valueStyle ?? AuroraText.tileValue),
                ],
                if (sub != null) ...[
                  const SizedBox(height: AuroraSpacing.xs),
                  Text(sub!, style: AuroraText.bodySm),
                ],
              ],
            ),
      ),
    );
  }
}

/// The gradient-clipped numeral used for the single most important stat
/// on a screen — e.g. the ATS score. Pairs with [BentoTile.valueStyle].
class GradientValueText extends StatelessWidget {
  const GradientValueText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AuroraColors.aurora.createShader(bounds),
      child: Text(text, style: (style ?? AuroraText.tileValue).copyWith(color: Colors.white)),
    );
  }
}
