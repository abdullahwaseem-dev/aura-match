import 'package:flutter/material.dart';
import '../theme/aurora.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, required this.fromAura});

  final String text;
  final bool fromAura;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromAura ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: fromAura ? AuroraColors.violet.withValues(alpha: 0.1) : AuroraColors.cyan.withValues(alpha: 0.08),
          border: Border.all(color: fromAura ? AuroraColors.violet.withValues(alpha: 0.26) : AuroraColors.cyan.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(fromAura ? 6 : 20),
            bottomRight: Radius.circular(fromAura ? 20 : 6),
          ),
        ),
        child: Text(text, style: AuroraText.body.copyWith(fontSize: 14.5, height: 1.45)),
      ),
    );
  }
}
