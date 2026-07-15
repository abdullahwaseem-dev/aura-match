import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resume_models.dart';
import '../../../state/resume_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/glass_container.dart';

class DraftPreviewView extends StatelessWidget {
  const DraftPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResumeState>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REBUILT & ATS-SAFE', style: AuroraText.caption.copyWith(color: AuroraColors.cyanSoft)),
            const SizedBox(height: 10),
            Text('Your new resume', style: AuroraText.displayM),
            const SizedBox(height: 18),
            GlassContainer(
              child: Text(
                state.rebuiltResume ?? '',
                style: AuroraText.body.copyWith(fontSize: 13.5, height: 1.6),
              ),
            ),
            const SizedBox(height: 28),
            Text('Get a real hiring manager\'s read', style: AuroraText.displayM.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Pick the kind of company you\'re targeting — Aura calibrates the rubric to that persona.',
              style: AuroraText.body.copyWith(color: AuroraColors.mist, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: HiringManagerPersona.all.map((p) {
                return GestureDetector(
                  onTap: state.loading ? null : () => context.read<ResumeState>().scoreWithPersona(p.rubric),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AuroraRadius.control),
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: AuroraColors.violet.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.label, style: AuroraText.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        Text(p.region, style: AuroraText.mono.copyWith(fontSize: 10, color: AuroraColors.violetSoft)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (state.loading) ...[
              const SizedBox(height: 20),
              Center(
                child: Text('Aura is reviewing as your hiring manager…', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
              ),
            ],
            const SizedBox(height: 20),
            AuroraButton(
              label: 'Start over',
              variant: AuroraButtonVariant.ghost,
              onPressed: () => context.read<ResumeState>().reset(),
            ),
          ],
        ),
      ),
    );
  }
}
