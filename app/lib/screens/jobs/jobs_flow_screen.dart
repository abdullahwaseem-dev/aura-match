import 'package:flutter/material.dart';
import '../../theme/aurora.dart';
import 'custom_job_screen.dart';
import 'widgets/match_feed_view.dart';
import 'widgets/tracker_view.dart';

class JobsFlowScreen extends StatefulWidget {
  const JobsFlowScreen({super.key});

  @override
  State<JobsFlowScreen> createState() => _JobsFlowScreenState();
}

class _JobsFlowScreenState extends State<JobsFlowScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JOBS', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
                const SizedBox(height: AuroraSpacing.sm),
                Text(_tab == 0 ? 'Match Feed' : 'Application Tracker', style: AuroraText.displayM),
                const SizedBox(height: AuroraSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SegmentedHeader(index: _tab, onChanged: (i) => setState(() => _tab = i)),
                    _AddJobButton(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CustomJobScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AuroraMotion.screen,
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: _tab == 0 ? const MatchFeedView() : const TrackerView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddJobButton extends StatelessWidget {
  const _AddJobButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AuroraRadius.pill),
          border: Border.all(color: AuroraColors.line),
        ),
        child: const Icon(Icons.add, size: 20, color: AuroraColors.cyanSoft),
      ),
    );
  }
}

class _SegmentedHeader extends StatelessWidget {
  const _SegmentedHeader({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['Feed', 'Tracker'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
        border: Border.all(color: AuroraColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_labels.length, (i) {
          final active = i == index;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: AuroraMotion.micro,
              curve: AuroraMotion.auroraEase,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AuroraColors.cyan.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(AuroraRadius.pill),
              ),
              child: Text(
                _labels[i],
                style: AuroraText.bodySm.copyWith(color: active ? AuroraColors.cyanSoft : AuroraColors.mist),
              ),
            ),
          );
        }),
      ),
    );
  }
}
