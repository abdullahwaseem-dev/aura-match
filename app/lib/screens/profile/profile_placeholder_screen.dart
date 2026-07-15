import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.person_outline,
      eyebrow: 'PHASE 4',
      title: 'Profile & Settings',
      description: 'Resume library, plan & billing, privacy controls, and the auto-apply master switch.',
    );
  }
}
