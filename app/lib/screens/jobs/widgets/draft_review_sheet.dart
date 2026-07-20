import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/interview_models.dart';
import '../../../models/job_models.dart';
import '../../../services/resume_pdf.dart';
import '../../../state/interview_state.dart';
import '../../../state/jobs_state.dart';
import '../../../state/navigation_state.dart';
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
  bool _exporting = false;

  TailoredResume get _resume => widget.draft.resume;

  @override
  Widget build(BuildContext context) {
    final job = widget.application.job;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
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
            Text('TAILORED RESUME · REVIEW', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
            const SizedBox(height: AuroraSpacing.sm),
            Text(job.companyName.isEmpty ? job.title : '${job.title} at ${job.companyName}', style: AuroraText.displayM),
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
                      "Aura rewrote your resume for this job using only facts from your original — nothing is invented or auto-submitted. Review it, download the PDF, then apply yourself on the employer's real posting.",
                      style: AuroraText.bodySm,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.lg),

            // Full tailored resume preview.
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_resume.fullName.isNotEmpty)
                    Text(_resume.fullName, style: AuroraText.displayM.copyWith(fontSize: 19)),
                  if (_resume.headline.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(_resume.headline, style: AuroraText.body.copyWith(color: AuroraColors.cyanSoft, fontSize: 13.5)),
                    ),
                  if (_resume.contact.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_resume.contact, style: AuroraText.bodySm.copyWith(color: AuroraColors.mist)),
                    ),
                  if (_resume.summary.isNotEmpty) ...[
                    _resumeHeading('Summary'),
                    Text(_resume.summary, style: AuroraText.body.copyWith(fontSize: 13.5, height: 1.55)),
                  ],
                  if (_resume.skills.isNotEmpty) ...[
                    _resumeHeading('Skills'),
                    Text(_resume.skills.join('  ·  '), style: AuroraText.body.copyWith(fontSize: 13, height: 1.5)),
                  ],
                  if (_resume.experience.isNotEmpty) ...[
                    _resumeHeading('Experience'),
                    ..._resume.experience.map(_experienceBlock),
                  ],
                  if (_resume.education.isNotEmpty) ...[
                    _resumeHeading('Education'),
                    ..._resume.education.map(
                      (ed) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          [
                            [ed.credential, ed.institution].where((s) => s.isNotEmpty).join(' — '),
                            if (ed.dates.isNotEmpty) ed.dates,
                          ].join('  ·  '),
                          style: AuroraText.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.md),
            AuroraButton(
              label: _exporting ? 'Preparing PDF…' : 'Download resume PDF',
              icon: Icons.picture_as_pdf_outlined,
              expand: true,
              onPressed: _exporting ? null : _exportPdf,
            ),

            const SizedBox(height: AuroraSpacing.lg),
            _Section(title: 'Cover note', body: widget.draft.coverNote),
            const SizedBox(height: AuroraSpacing.xl),
            if (job.applyUrl.isNotEmpty) ...[
              AuroraButton(
                label: 'Open posting & apply',
                icon: Icons.open_in_new,
                variant: AuroraButtonVariant.secondary,
                expand: true,
                onPressed: () => _openPosting(job.applyUrl),
              ),
              const SizedBox(height: AuroraSpacing.md),
            ],
            AuroraButton(
              label: _markingApplied ? 'Marking…' : "I've applied — mark it",
              variant: AuroraButtonVariant.ghost,
              expand: true,
              onPressed: _markingApplied || widget.application.status == ApplicationStatus.applied ? null : _markApplied,
            ),
            const SizedBox(height: AuroraSpacing.md),
            AuroraButton(
              label: 'Prep for the interview',
              icon: Icons.mic_none_outlined,
              variant: AuroraButtonVariant.ghost,
              expand: true,
              onPressed: _prepInterview,
            ),
          ],
        ),
      ),
    );
  }

  void _prepInterview() {
    final job = widget.application.job;
    context.read<InterviewState>().prepareForJob(
          InterviewJobContext(jobTitle: job.title, companyName: job.companyName, jobDescription: job.description),
        );
    context.read<NavigationState>().goTo(3); // Prep tab
    Navigator.of(context).pop();
  }

  Widget _resumeHeading(String text) => Padding(
        padding: const EdgeInsets.only(top: AuroraSpacing.md, bottom: AuroraSpacing.xs),
        child: Text(text.toUpperCase(), style: AuroraText.caption.copyWith(color: AuroraColors.mist)),
      );

  Widget _experienceBlock(ResumeExperience e) {
    final header = [e.role, e.company].where((s) => s.isNotEmpty).join(' — ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSpacing.smd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(header, style: AuroraText.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700))),
              if (e.dates.isNotEmpty) Text(e.dates, style: AuroraText.bodySm.copyWith(color: AuroraColors.mistDim)),
            ],
          ),
          const SizedBox(height: 4),
          ...e.bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 4),
              child: Text('•  $b', style: AuroraText.body.copyWith(fontSize: 12.5, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      await ResumePdf.shareTailoredResume(
        resume: _resume,
        jobTitle: widget.application.job.title,
        company: widget.application.job.companyName,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export PDF: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
