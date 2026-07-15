import 'package:flutter/material.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aura_orb.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuraOrb(size: 56),
          const SizedBox(height: AuroraSpacing.lg),
          Text(message, style: AuroraText.body.copyWith(color: AuroraColors.mist)),
        ],
      ),
    );
  }
}
