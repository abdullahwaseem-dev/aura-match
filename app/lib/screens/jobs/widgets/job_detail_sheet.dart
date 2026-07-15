import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job_models.dart';
import '../../../state/jobs_state.dart';
import '../../../state/resume_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/score_ring.dart';
import 'draft_review_sheet.dart';

Future<void> showJobDetailSheet(BuildContext context, JobMatch match) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _JobDetailSheet(match: match),
  );
}

class _JobDetailSheet extends StatefulWidget {
  const _JobDetailSheet({required this.match});
  final JobMatch match;

  @override
  State<_JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<_JobDetailSheet> {
  bool _saving = false;
  bool _drafting = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.match.job;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AuroraColors.void2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AuroraRadius.sheet)),
          border: Border(top: BorderSide(color: AuroraColors.line)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AuroraColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: AuroraText.displayM),
                      const SizedBox(height: AuroraSpacing.xs),
                      Text(
                        job.remote ? '${job.companyName} · Remote' : '${job.companyName}${job.location != null ? ' · ${job.location}' : ''}',
                        style: AuroraText.bodySm,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AuroraSpacing.md),
                ScoreRing(score: widget.match.matchScore, size: 64, label: 'MATCH'),
              ],
            ),
            if (job.tags.isNotEmpty) ...[
              const SizedBox(height: AuroraSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.tags.map((t) => _Tag(t)).toList(),
              ),
            ],
            if (widget.match.reasons.isNotEmpty) ...[
              const SizedBox(height: AuroraSpacing.lg),
              GlassContainer(
                borderColor: AuroraColors.cyan.withValues(alpha: 0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WHY IT MATCHES', style: AuroraText.mono.copyWith(fontSize: 11, color: AuroraColors.cyanSoft)),
                    const SizedBox(height: AuroraSpacing.sm),
                    ...widget.match.reasons.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• $r', style: AuroraText.body.copyWith(fontSize: 13.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AuroraSpacing.lg),
            Text('About this role', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
            const SizedBox(height: AuroraSpacing.sm),
            Text(job.description, style: AuroraText.body.copyWith(fontSize: 14, height: 1.6)),
            const SizedBox(height: AuroraSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AuroraButton(
                    label: _saving ? 'Saved' : 'Save for later',
                    variant: AuroraButtonVariant.secondary,
                    onPressed: _saving ? null : _save,
                  ),
                ),
                const SizedBox(width: AuroraSpacing.md),
                Expanded(
                  child: AuroraButton(
                    label: _drafting ? 'Drafting…' : 'Draft application',
                    onPressed: _drafting ? null : _draft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<JobsState>().saveJob(widget.match.job.id);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _draft() async {
    final resume = context.read<ResumeState>();
    if (resume.resumeText == null) return;
    setState(() => _drafting = true);
    try {
      final (draft, application) = await context.read<JobsState>().draftApplication(
            jobId: widget.match.job.id,
            resumeText: resume.rebuiltResume ?? resume.resumeText!,
            targetRole: resume.targetRole,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      await showDraftReviewSheet(context, draft: draft, application: application);
    } catch (e) {
      if (mounted) {
        setState(() => _drafting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not draft: $e')));
      }
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
        border: Border.all(color: AuroraColors.line),
      ),
      child: Text(label, style: AuroraText.mono.copyWith(fontSize: 10.5, color: AuroraColors.mist)),
    );
  }
}
