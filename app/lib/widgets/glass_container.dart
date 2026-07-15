import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/aurora.dart';

/// The base glass panel — blur + soft gradient fill + layered shadow.
/// No border by default; depth comes from [AuroraColors.glassShadow], not a
/// hairline. Set [interactive] to add the hover-lift + glow used on bento
/// tiles (desktop/web hover via [MouseRegion], press feedback everywhere).
class GlassContainer extends StatefulWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AuroraSpacing.lg),
    this.radius = AuroraRadius.card,
    this.blur = 26,
    this.borderColor,
    this.interactive = false,
    this.glow = AuroraColors.cyanGlow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color? borderColor;
  final bool interactive;
  final BoxShadow glow;
  final VoidCallback? onTap;

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.interactive && (_hover || _pressed);
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: AnimatedContainer(
          duration: AuroraMotion.panel,
          curve: AuroraMotion.auroraEase,
          padding: widget.padding,
          transform: lifted ? (Matrix4.identity()..translateByDouble(0.0, -6.0, 0.0, 1.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.055),
                Colors.white.withValues(alpha: 0.012),
              ],
            ),
            color: AuroraColors.void2.withValues(alpha: 0.55),
            border: Border.all(
              color: lifted ? widget.glow.color.withValues(alpha: 0.35) : (widget.borderColor ?? AuroraColors.line),
              width: 1,
            ),
            boxShadow: [
              ...AuroraColors.glassShadow,
              if (lifted) widget.glow,
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    if (!widget.interactive && widget.onTap == null) return content;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: content,
      ),
    );
  }
}
