import 'package:flutter/material.dart';
import '../../../models/job_models.dart';
import '../../../theme/aurora.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/score_ring.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.match, required this.onTap});

  final JobMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final job = match.job;
    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSpacing.md),
      child: GlassContainer(
        interactive: true,
        onTap: onTap,
        glow: match.matchScore >= 70 ? AuroraColors.cyanGlow : AuroraColors.violetGlow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScoreRing(score: match.matchScore, size: 56, label: null),
            const SizedBox(width: AuroraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: AuroraText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AuroraSpacing.xs),
                  Text(
                    job.remote ? '${job.companyName} · Remote' : '${job.companyName}${job.location != null ? ' · ${job.location}' : ''}',
                    style: AuroraText.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (match.reasons.isNotEmpty) ...[
                    const SizedBox(height: AuroraSpacing.sm),
                    Text(
                      match.reasons.first,
                      style: AuroraText.bodySm.copyWith(color: AuroraColors.cyanSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
