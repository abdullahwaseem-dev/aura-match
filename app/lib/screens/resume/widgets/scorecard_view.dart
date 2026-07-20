import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/resume_library_state.dart';
import '../../../state/resume_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/meter_bar.dart';
import '../../../widgets/score_ring.dart';

class ScorecardView extends StatefulWidget {
  const ScorecardView({super.key});

  @override
  State<ScorecardView> createState() => _ScorecardViewState();
}

class _ScorecardViewState extends State<ScorecardView> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveToLibrary(ResumeState state) async {
    setState(() => _saving = true);
    try {
      await context.read<ResumeLibraryState>().save(
            fileName: state.fileName ?? 'Untitled resume',
            resumeText: state.rebuiltResume ?? state.resumeText!,
            targetRole: state.targetRole,
            atsScore: state.scanResult?.atsScore,
          );
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResumeState>();
    final card = state.scorecard!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HIRING MANAGER · ${state.persona?.toUpperCase() ?? ''}', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
            const SizedBox(height: 10),
            Text('Scorecard', style: AuroraText.displayM),
            const SizedBox(height: 20),
            Center(child: ScoreRing(score: card.overallScore, size: 140, label: 'OVERALL')),
            const SizedBox(height: 24),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: card.categories.map((c) => MeterBar(label: c.name, score: c.score)).toList(),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              borderColor: AuroraColors.violet.withValues(alpha: 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GLOBAL BENCHMARK', style: AuroraText.mono.copyWith(fontSize: 11, color: AuroraColors.violetSoft)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: AuroraText.body.copyWith(fontSize: 14.5),
                      children: [
                        const TextSpan(text: 'Top '),
                        TextSpan(
                          text: '${card.benchmarkPercentile}%',
                          style: const TextStyle(color: AuroraColors.ink, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' of resumes reviewed for ${state.persona ?? "this persona"}.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Feedback', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
                  const SizedBox(height: 12),
                  ...card.feedback.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 10),
                            child: SizedBox(
                              width: 5,
                              height: 5,
                              child: DecoratedBox(decoration: BoxDecoration(color: AuroraColors.violet, shape: BoxShape.circle)),
                            ),
                          ),
                          Expanded(child: Text(f, style: AuroraText.body.copyWith(fontSize: 13.5, height: 1.5))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AuroraButton(
              label: _saved ? 'Saved to library' : (_saving ? 'Saving…' : 'Save to resume library'),
              icon: _saved ? Icons.check : Icons.bookmark_add_outlined,
              expand: true,
              onPressed: (_saving || _saved) ? null : () => _saveToLibrary(state),
            ),
            const SizedBox(height: 12),
            AuroraButton(
              label: 'Start a new resume',
              expand: true,
              variant: AuroraButtonVariant.secondary,
              onPressed: () => context.read<ResumeState>().reset(),
            ),
          ],
        ),
      ),
    );
  }
}
