import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class JobsPlaceholderScreen extends StatelessWidget {
  const JobsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.work_outline,
      eyebrow: 'PHASE 2',
      title: 'Automatic Job Search & Apply',
      description: 'Match Feed, consent-gated auto-apply, and the application tracker ship in the next build phase.',
    );
  }
}
