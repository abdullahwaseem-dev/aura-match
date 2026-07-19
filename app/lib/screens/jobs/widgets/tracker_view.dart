import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/interview_models.dart';
import '../../../models/job_models.dart';
import '../../../state/interview_state.dart';
import '../../../state/jobs_state.dart';
import '../../../state/navigation_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aura_orb.dart';
import '../../../widgets/aurora_button.dart';
import '../../../widgets/glass_container.dart';

class TrackerView extends StatefulWidget {
  const TrackerView({super.key});

  @override
  State<TrackerView> createState() => _TrackerViewState();
}

class _TrackerViewState extends State<TrackerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobs = context.read<JobsState>();
      if (jobs.applications.isEmpty && !jobs.loadingApplications) jobs.loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobsState>();

    if (jobs.loadingApplications && jobs.applications.isEmpty) {
      return const Center(child: AuraOrb(size: 48));
    }

    if (jobs.applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AuroraSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 36, color: AuroraColors.mistDim),
              const SizedBox(height: AuroraSpacing.md),
              Text('Nothing tracked yet', style: AuroraText.displayM, textAlign: TextAlign.center),
              const SizedBox(height: AuroraSpacing.sm),
              Text(
                'Save or draft a job from the Feed tab and it shows up here.',
                style: AuroraText.body.copyWith(color: AuroraColors.mist),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<JobsState>().loadApplications(),
      color: AuroraColors.cyan,
      backgroundColor: AuroraColors.void2,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        itemCount: jobs.applications.length,
        itemBuilder: (context, i) => _ApplicationRow(application: jobs.applications[i]),
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({required this.application});
  final TrackedApplication application;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSpacing.md),
      child: GlassContainer(
        interactive: true,
        onTap: () => _showStatusPicker(context),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.job.title,
                    style: AuroraText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AuroraSpacing.xs),
                  Text(application.job.companyName, style: AuroraText.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.sm),
            _StatusPill(status: application.status),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          color: AuroraColors.void2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AuroraRadius.sheet)),
          border: Border(top: BorderSide(color: AuroraColors.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(application.job.title, style: AuroraText.displayM),
            const SizedBox(height: AuroraSpacing.lg),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ApplicationStatus.values.map((s) {
                final active = s == application.status;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (!active) context.read<JobsState>().updateStatus(application.id, s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AuroraColors.cyan.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AuroraRadius.pill),
                      border: Border.all(color: active ? AuroraColors.cyan.withValues(alpha: 0.4) : AuroraColors.line),
                    ),
                    child: Text(
                      s.label,
                      style: AuroraText.bodySm.copyWith(color: active ? AuroraColors.cyanSoft : AuroraColors.mist),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AuroraSpacing.lg),
            AuroraButton(
              label: 'Prep for the interview',
              icon: Icons.mic_none_outlined,
              variant: AuroraButtonVariant.ghost,
              expand: true,
              onPressed: () {
                context.read<InterviewState>().prepareForJob(
                      InterviewJobContext(
                        jobTitle: application.job.title,
                        companyName: application.job.companyName,
                        jobDescription: application.job.description,
                      ),
                    );
                context.read<NavigationState>().goTo(3);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ApplicationStatus status;

  Color get _color {
    switch (status) {
      case ApplicationStatus.applied:
      case ApplicationStatus.interviewing:
        return AuroraColors.cyan;
      case ApplicationStatus.offer:
        return AuroraColors.success;
      case ApplicationStatus.rejected:
        return AuroraColors.danger;
      case ApplicationStatus.saved:
      case ApplicationStatus.drafting:
      case ApplicationStatus.ready:
        return AuroraColors.mist;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(status.label, style: AuroraText.mono.copyWith(fontSize: 10, color: _color)),
    );
  }
}
