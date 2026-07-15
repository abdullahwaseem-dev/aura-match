import 'package:flutter/material.dart';
import '../../theme/aurora.dart';
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
                _SegmentedHeader(index: _tab, onChanged: (i) => setState(() => _tab = i)),
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
