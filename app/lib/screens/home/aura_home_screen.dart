import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/resume_state.dart';
import '../../theme/aurora.dart';
import '../../widgets/aura_orb.dart';
import '../../widgets/bento_tile.dart';

class AuraHomeScreen extends StatelessWidget {
  const AuraHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResumeState>();
    final hasResume = state.resumeText != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AuraOrb(size: 40),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good to see you', style: AuroraText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('AURA MATCH', style: AuroraText.caption),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AuroraSpacing.xl),

            // Hero bento tile — Aura's live suggestion, always the biggest tile on screen.
            BentoTile(
              label: 'AURA',
              glow: AuroraColors.violetGlow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AuroraColors.violet),
                      ),
                      Text('AURA', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
                    ],
                  ),
                  const SizedBox(height: AuroraSpacing.sm),
                  Text(_statusMessage(state), style: AuroraText.bodyL.copyWith(fontSize: 17, height: 1.5, fontWeight: FontWeight.w700)),
                  if (state.error != null) ...[
                    const SizedBox(height: AuroraSpacing.smd),
                    Text(state.error!, style: AuroraText.bodySm.copyWith(color: AuroraColors.danger)),
                  ],
                ],
              ),
            ),

            if (hasResume) ...[
              const SizedBox(height: AuroraSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BentoTile(
                      label: 'ATS Score',
                      glow: AuroraColors.cyanGlow,
                      child: _valueTile(
                        label: 'ATS Score',
                        value: state.scanResult?.atsScore.toString() ?? '—',
                        sub: state.scanResult != null ? '${state.scanResult!.missingKeywords.length} gaps found' : 'Not scanned yet',
                        gradient: state.scanResult != null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.md),
                  Expanded(
                    child: BentoTile(
                      label: 'Manager Grade',
                      glow: AuroraColors.violetGlow,
                      child: _valueTile(
                        label: 'Manager Grade',
                        value: state.scorecard?.overallScore.toString() ?? '—',
                        sub: state.scorecard != null ? 'Top ${state.scorecard!.benchmarkPercentile}%' : 'Not scored yet',
                        gradient: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AuroraSpacing.md),
              BentoTile(
                label: 'Resume Pipeline',
                glow: AuroraColors.cyanGlow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resume Pipeline', style: AuroraText.caption),
                    const SizedBox(height: AuroraSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.fileName ?? 'Untitled resume',
                            style: AuroraText.body.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _stagePill(state.stage),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _valueTile({required String label, required String value, required String sub, required bool gradient}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AuroraText.caption),
        const SizedBox(height: AuroraSpacing.sm),
        gradient ? GradientValueText(value) : Text(value, style: AuroraText.tileValue),
        const SizedBox(height: AuroraSpacing.xs),
        Text(sub, style: AuroraText.bodySm),
      ],
    );
  }

  Widget _stagePill(PipelineStage stage) {
    final label = switch (stage) {
      PipelineStage.empty => 'Not started',
      PipelineStage.scanning => 'Scanning…',
      PipelineStage.scanned => 'Scanned',
      PipelineStage.qa => 'Q&A',
      PipelineStage.rebuilding => 'Rebuilding…',
      PipelineStage.rebuilt => 'Rebuilt',
      PipelineStage.scoring => 'Scoring…',
      PipelineStage.scored => 'Scored',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
        border: Border.all(color: AuroraColors.line),
      ),
      child: Text(label, style: AuroraText.mono.copyWith(fontSize: 11, color: AuroraColors.mist)),
    );
  }

  String _statusMessage(ResumeState state) {
    if (state.resumeText == null) {
      return "Upload a resume in the Resume tab and I'll scan it against real ATS parsers, then rebuild it with you.";
    }
    switch (state.stage) {
      case PipelineStage.scanned:
        return 'Scan is in. There are ${state.scanResult?.missingKeywords.length ?? 0} gaps I can help you close — head to the Resume tab.';
      case PipelineStage.rebuilt:
        return "Your resume is rebuilt. Ready to see how a real hiring manager would score it?";
      case PipelineStage.scored:
        return 'Scored as ${state.scorecard?.overallScore}/100. Top ${state.scorecard?.benchmarkPercentile}% for this persona.';
      default:
        return "I'm on it — check the Resume tab for progress.";
    }
  }
}
