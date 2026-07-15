import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/resume_state.dart';
import '../../theme/aurora.dart';
import 'widgets/draft_preview_view.dart';
import 'widgets/loading_view.dart';
import 'widgets/qa_chat_view.dart';
import 'widgets/scan_result_view.dart';
import 'widgets/scorecard_view.dart';
import 'widgets/upload_view.dart';

class ResumeFlowScreen extends StatelessWidget {
  const ResumeFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stage = context.watch<ResumeState>().stage;

    return ColoredBox(
      color: AuroraColors.void_,
      child: AnimatedSwitcher(
        duration: AuroraMotion.screen,
        child: KeyedSubtree(
          key: ValueKey(stage),
          child: _forStage(stage),
        ),
      ),
    );
  }

  Widget _forStage(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.empty:
        return const UploadView();
      case PipelineStage.scanning:
        return const LoadingView(message: 'Scanning against real ATS parsers…');
      case PipelineStage.scanned:
        return const ScanResultView();
      case PipelineStage.qa:
        return const QaChatView();
      case PipelineStage.rebuilding:
        return const LoadingView(message: 'Rebuilding your resume…');
      case PipelineStage.rebuilt:
        return const DraftPreviewView();
      case PipelineStage.scoring:
        return const DraftPreviewView();
      case PipelineStage.scored:
        return const ScorecardView();
    }
  }
}
