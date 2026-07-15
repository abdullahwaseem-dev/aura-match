import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/jobs_state.dart';
import '../../../state/resume_state.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/aura_orb.dart';
import '../../../widgets/aurora_button.dart';
import 'job_card.dart';
import 'job_detail_sheet.dart';

class MatchFeedView extends StatefulWidget {
  const MatchFeedView({super.key});

  @override
  State<MatchFeedView> createState() => _MatchFeedViewState();
}

class _MatchFeedViewState extends State<MatchFeedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoLoad());
  }

  void _maybeAutoLoad() {
    final resume = context.read<ResumeState>();
    final jobs = context.read<JobsState>();
    if (resume.resumeText != null && jobs.feed.isEmpty && !jobs.loadingFeed) {
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    final resume = context.read<ResumeState>();
    if (resume.resumeText == null) return;
    await context.read<JobsState>().loadFeed(
          resumeText: resume.rebuiltResume ?? resume.resumeText!,
          targetRole: resume.targetRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final resume = context.watch<ResumeState>();
    final jobs = context.watch<JobsState>();

    if (resume.resumeText == null) {
      return _EmptyState(
        icon: Icons.description_outlined,
        title: 'Scan a resume first',
        message: 'Aura matches jobs against your resume — head to the Resume tab and run a scan, then come back here.',
      );
    }

    if (jobs.loadingFeed && jobs.feed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraOrb(size: 56),
            SizedBox(height: AuroraSpacing.lg),
            Text('Scanning live listings for your best matches…', style: AuroraText.body, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (jobs.feedError != null && jobs.feed.isEmpty) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: "Couldn't load matches",
        message: jobs.feedError!,
        action: AuroraButton(label: 'Try again', onPressed: _loadFeed),
      );
    }

    if (jobs.feed.isEmpty) {
      return _EmptyState(
        icon: Icons.work_outline,
        title: 'No matches yet',
        message: 'Tap refresh to pull the latest live listings and score them against your resume.',
        action: AuroraButton(label: 'Find matches', onPressed: _loadFeed),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      color: AuroraColors.cyan,
      backgroundColor: AuroraColors.void2,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        itemCount: jobs.feed.length,
        itemBuilder: (context, i) {
          final match = jobs.feed[i];
          return JobCard(match: match, onTap: () => showJobDetailSheet(context, match));
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AuroraColors.mistDim),
            const SizedBox(height: AuroraSpacing.md),
            Text(title, style: AuroraText.displayM, textAlign: TextAlign.center),
            const SizedBox(height: AuroraSpacing.sm),
            Text(message, style: AuroraText.body.copyWith(color: AuroraColors.mist), textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AuroraSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
