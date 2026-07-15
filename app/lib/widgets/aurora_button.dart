import 'package:flutter/material.dart';
import '../theme/aurora.dart';

enum AuroraButtonVariant { primary, secondary, ghost, danger }

class AuroraButton extends StatefulWidget {
  const AuroraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AuroraButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AuroraButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  State<AuroraButton> createState() => _AuroraButtonState();
}

class _AuroraButtonState extends State<AuroraButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: _fg()),
          const SizedBox(width: AuroraSpacing.sm),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: _fg(),
          ),
        ),
      ],
    );

    final lift = !disabled && (_hover || _pressed);

    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: disabled ? null : widget.onPressed,
          child: AnimatedContainer(
            // A non-overshooting curve here is required: Curves.elasticOut
            // pushes its animated t past 1.0 during the bounce-settle, and
            // when boxShadow lists change length (see _decoration) Flutter's
            // BoxShadow.lerpList scales the extra shadow by (1 - t), which
            // goes negative once t > 1 — that produces a negative blurRadius
            // and trips dart:ui's Shadow assertion on every affected frame.
            // The spring/bounce feel is preserved below on the transform,
            // which has no such domain constraint.
            duration: AuroraMotion.micro,
            curve: AuroraMotion.auroraEase,
            height: 52,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
            alignment: Alignment.center,
            decoration: _decoration(lift),
            child: AnimatedContainer(
              duration: AuroraMotion.micro,
              curve: _pressed ? Curves.easeOut : AuroraMotion.spring,
              transform: _pressed
                  ? (Matrix4.identity()..scaleByDouble(0.97, 0.97, 0.97, 1))
                  : (lift
                      ? (Matrix4.identity()..translateByDouble(0.0, -3.0, 0.0, 1.0))
                      : Matrix4.identity()),
              transformAlignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Color _fg() {
    switch (widget.variant) {
      case AuroraButtonVariant.primary:
        return const Color(0xFF04040A);
      case AuroraButtonVariant.secondary:
        return AuroraColors.cyanSoft;
      case AuroraButtonVariant.ghost:
        return _hover ? AuroraColors.ink : AuroraColors.mist;
      case AuroraButtonVariant.danger:
        return const Color(0xFFFFB2C0);
    }
  }

  BoxDecoration _decoration(bool lift) {
    switch (widget.variant) {
      case AuroraButtonVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AuroraRadius.pill),
          gradient: AuroraColors.aurora,
          boxShadow: lift
              ? [
                  BoxShadow(color: AuroraColors.cyan.withValues(alpha: 0.5), blurRadius: 34, offset: const Offset(0, 14)),
                  BoxShadow(color: AuroraColors.violet.withValues(alpha: 0.32), blurRadius: 50),
                ]
              : [BoxShadow(color: AuroraColors.cyan.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 8))],
        );
      case AuroraButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AuroraRadius.pill),
          color: Colors.white.withValues(alpha: lift ? 0.08 : 0.04),
          border: Border.all(color: AuroraColors.violet.withValues(alpha: lift ? 0.55 : 0.3)),
          boxShadow: lift ? [BoxShadow(color: AuroraColors.violet.withValues(alpha: 0.22), blurRadius: 40)] : null,
        );
      case AuroraButtonVariant.ghost:
        return const BoxDecoration();
      case AuroraButtonVariant.danger:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AuroraRadius.pill),
          color: AuroraColors.danger.withValues(alpha: lift ? 0.16 : 0.09),
          border: Border.all(color: AuroraColors.danger.withValues(alpha: 0.4)),
        );
    }
  }
}
