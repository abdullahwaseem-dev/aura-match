import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/job_models.dart';
import '../../../state/jobs_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/glass_container.dart';

Future<void> showDraftReviewSheet(
  BuildContext context, {
  required ApplicationDraft draft,
  required TrackedApplication application,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DraftReviewSheet(draft: draft, application: application),
  );
}

class _DraftReviewSheet extends StatefulWidget {
  const _DraftReviewSheet({required this.draft, required this.application});
  final ApplicationDraft draft;
  final TrackedApplication application;

  @override
  State<_DraftReviewSheet> createState() => _DraftReviewSheetState();
}

class _DraftReviewSheetState extends State<_DraftReviewSheet> {
  bool _markingApplied = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.application.job;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
            Text('DRAFTED FOR YOU TO REVIEW', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
            const SizedBox(height: AuroraSpacing.sm),
            Text('${job.title} at ${job.companyName}', style: AuroraText.displayM),
            const SizedBox(height: AuroraSpacing.md),
            GlassContainer(
              borderColor: AuroraColors.amber.withValues(alpha: 0.25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AuroraColors.amber),
                  const SizedBox(width: AuroraSpacing.sm),
                  Expanded(
                    child: Text(
                      "Aura drafted this from your resume — nothing is submitted automatically. Review it, then apply yourself on the employer's real posting.",
                      style: AuroraText.bodySm,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.lg),
            _Section(title: 'Tailored summary', body: widget.draft.tailoredSummary),
            if (widget.draft.tailoredHighlights.isNotEmpty) ...[
              const SizedBox(height: AuroraSpacing.lg),
              Text('Reworked highlights', style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
              const SizedBox(height: AuroraSpacing.sm),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.draft.tailoredHighlights
                      .map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $h', style: AuroraText.body.copyWith(fontSize: 13.5, height: 1.5)),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: AuroraSpacing.lg),
            _Section(title: 'Cover note', body: widget.draft.coverNote),
            const SizedBox(height: AuroraSpacing.xl),
            AuroraButton(
              label: 'Open posting & apply',
              icon: Icons.open_in_new,
              expand: true,
              onPressed: () => _openPosting(job.applyUrl),
            ),
            const SizedBox(height: AuroraSpacing.md),
            AuroraButton(
              label: _markingApplied ? 'Marking…' : "I've applied — mark it",
              variant: AuroraButtonVariant.secondary,
              expand: true,
              onPressed: _markingApplied || widget.application.status == ApplicationStatus.applied ? null : _markApplied,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPosting(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _markApplied() async {
    setState(() => _markingApplied = true);
    try {
      await context.read<JobsState>().updateStatus(widget.application.id, ApplicationStatus.applied);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _markingApplied = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update status: $e')));
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
        const SizedBox(height: AuroraSpacing.sm),
        GlassContainer(child: Text(body, style: AuroraText.body.copyWith(fontSize: 14, height: 1.6))),
      ],
    );
  }
}
