import 'package:flutter/material.dart';
import '../theme/aurora.dart';

/// Shared scaffold for tabs outside this build's Phase 1 scope
/// (Job Search & Apply, Interview Simulator, Profile & Settings).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.eyebrow, required this.description, required this.icon});

  final String title;
  final String eyebrow;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AuroraSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AuroraColors.mistDim),
              const SizedBox(height: AuroraSpacing.md),
              Text(eyebrow, style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
              const SizedBox(height: AuroraSpacing.sm),
              Text(title, style: AuroraText.displayM, textAlign: TextAlign.center),
              const SizedBox(height: AuroraSpacing.smd),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AuroraText.body.copyWith(color: AuroraColors.mist),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
