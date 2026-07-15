import 'package:flutter/material.dart';
import '../theme/aurora.dart';

/// The Aura brand mark — the real AURA MATCH logo, breathing inside a
/// cyan/violet glow halo. Used as the FAB, avatar, and loading indicator
/// across the app. Set [pulseRings] for the Interview Simulator's
/// "listening" state — expanding rings around the mark.
class AuraOrb extends StatefulWidget {
  const AuraOrb({super.key, this.size = 44, this.animate = true, this.pulseRings = false});

  final double size;
  final bool animate;
  final bool pulseRings;

  @override
  State<AuraOrb> createState() => _AuraOrbState();
}

class _AuraOrbState extends State<AuraOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AuroraMotion.orbPulse)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringBox = widget.size * 2.1;
    return SizedBox(
      width: widget.pulseRings ? ringBox : widget.size,
      height: widget.pulseRings ? ringBox : widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulseRings) ...[
            _ExpandingRing(size: widget.size, controller: _controller, color: AuroraColors.cyan, delay: 0),
            _ExpandingRing(size: widget.size, controller: _controller, color: AuroraColors.violet, delay: 0.5),
          ],
          if (!widget.animate)
            _mark(1)
          else
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _mark(1 + _controller.value * 0.05),
            ),
        ],
      ),
    );
  }

  Widget _mark(double scale) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(widget.size * 0.14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AuroraColors.void2,
          boxShadow: [
            BoxShadow(color: AuroraColors.cyan.withValues(alpha: 0.45), blurRadius: widget.size * 0.5),
            BoxShadow(color: AuroraColors.violet.withValues(alpha: 0.3), blurRadius: widget.size * 0.8),
          ],
        ),
        child: ClipOval(
          child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _ExpandingRing extends StatelessWidget {
  const _ExpandingRing({required this.size, required this.controller, required this.color, required this.delay});

  final double size;
  final AnimationController controller;
  final Color color;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Reconstruct a 0..1 progress with a phase offset so the two rings stagger.
        final t = (controller.value + delay) % 1.0;
        final scale = 0.85 + t * 0.7;
        final opacity = (1 - t).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity * 0.8,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size * 1.35,
              height: size * 1.35,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.2)),
            ),
          ),
        );
      },
    );
  }
}
