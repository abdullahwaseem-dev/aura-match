import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/resume_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aura_orb.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/chat_bubble.dart';

class QaChatView extends StatefulWidget {
  const QaChatView({super.key});

  @override
  State<QaChatView> createState() => _QaChatViewState();
}

class _QaChatViewState extends State<QaChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit(ResumeState state) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    state.answerCurrentQuestion(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AuroraMotion.panel,
          curve: AuroraMotion.auroraEase,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResumeState>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const AuraOrb(size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A few questions to fill the gaps',
                    style: AuroraText.bodySm.copyWith(color: AuroraColors.ink, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${state.qaAnswers.length}/${state.scanResult?.questions.length ?? 0}',
                  style: AuroraText.mono.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: state.qaMessages
                  .map((m) => ChatBubble(text: m.text, fromAura: m.fromAura))
                  .toList(),
            ),
          ),
          // All questions answered but the rebuild call itself failed —
          // there's no current question left to submit against, so the
          // normal input would silently no-op forever. Show a retry
          // affordance instead.
          if (!state.hasNextQuestion && state.error != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(state.error!, style: AuroraText.bodySm.copyWith(color: AuroraColors.danger)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: AuroraButton(
                label: state.loading ? 'Retrying…' : 'Retry',
                icon: Icons.refresh,
                expand: true,
                onPressed: state.loading ? null : () => context.read<ResumeState>().rebuild(),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AuroraText.body,
                      onSubmitted: (_) => _submit(state),
                      decoration: InputDecoration(
                        hintText: 'Type your answer…',
                        hintStyle: AuroraText.body.copyWith(color: AuroraColors.mistDim),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AuroraRadius.control),
                          borderSide: const BorderSide(color: AuroraColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AuroraRadius.control),
                          borderSide: const BorderSide(color: AuroraColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AuroraRadius.control),
                          borderSide: const BorderSide(color: AuroraColors.cyan, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AuroraButton(label: 'Send', onPressed: () => _submit(state)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
