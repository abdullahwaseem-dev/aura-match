import 'package:flutter/material.dart';
import '../../widgets/placeholder_screen.dart';

class InterviewPlaceholderScreen extends StatelessWidget {
  const InterviewPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.mic_none_outlined,
      eyebrow: 'PHASE 3',
      title: 'Interview Practice Simulator',
      description: 'Triggers automatically once an application reaches Interview. Ships after the job-search engine.',
    );
  }
}
