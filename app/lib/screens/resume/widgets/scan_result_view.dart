import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/resume_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/aurora_chip.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/score_ring.dart';

class ScanResultView extends StatelessWidget {
  const ScanResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResumeState>();
    final result = state.scanResult!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text('ATS SCAN COMPLETE', style: AuroraText.caption.copyWith(color: AuroraColors.mistDim)),
                  const SizedBox(height: 16),
                  ScoreRing(score: result.atsScore, size: 140, label: 'ATS MATCH'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parser breakdown', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
                  const SizedBox(height: 12),
                  ...result.parserBreakdown.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.parser, style: AuroraText.body.copyWith(fontSize: 13.5)),
                          Text('${p.score}', style: AuroraText.mono.copyWith(fontSize: 13)),
                        ],
                      ),
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
                  Text('Keyword coverage', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...result.matchedKeywords.map((k) => AuroraChip(label: '✓ $k', tone: ChipTone.match)),
                      ...result.missingKeywords.map((k) => AuroraChip(label: '+ $k', tone: ChipTone.missing)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AuroraButton(
              label: 'Fix these gaps',
              expand: true,
              onPressed: () => context.read<ResumeState>().beginQa(),
            ),
          ],
        ),
      ),
    );
  }
}
