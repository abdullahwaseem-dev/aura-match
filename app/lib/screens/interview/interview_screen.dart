import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/interview_state.dart';
import '../../state/resume_state.dart';
import '../../theme/aurora.dart';
import '../../widgets/aura_orb.dart';
import '../../widgets/aurora_button.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/meter_bar.dart';
import '../../widgets/score_ring.dart';

class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resume = context.watch<ResumeState>();
    final interview = context.watch<InterviewState>();

    if (resume.resumeText == null) {
      return const _NeedsResume();
    }

    return ColoredBox(
      color: AuroraColors.void_,
      child: AnimatedSwitcher(
        duration: AuroraMotion.screen,
        child: KeyedSubtree(
          key: ValueKey(interview.stage),
          child: switch (interview.stage) {
            InterviewStage.intro => const _IntroView(),
            InterviewStage.generating => const _BusyView(message: 'Aura is preparing questions from your resume…'),
            InterviewStage.inProgress => const _ChatView(),
            InterviewStage.evaluating => const _BusyView(message: 'Scoring how you did…'),
            InterviewStage.results => const _ResultsView(),
          },
        ),
      ),
    );
  }
}

class _NeedsResume extends StatelessWidget {
  const _NeedsResume();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AuroraSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_none_outlined, size: 36, color: AuroraColors.mistDim),
              const SizedBox(height: AuroraSpacing.md),
              Text('Scan a resume first', style: AuroraText.displayM, textAlign: TextAlign.center),
              const SizedBox(height: AuroraSpacing.sm),
              Text(
                'Aura runs a mock interview grounded in your resume — scan one in the Resume tab, then come back to practice.',
                style: AuroraText.body.copyWith(color: AuroraColors.mist),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView();

  @override
  Widget build(BuildContext context) {
    final resume = context.read<ResumeState>();
    final interview = context.watch<InterviewState>();
    final job = interview.jobContext;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PREP', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
            const SizedBox(height: AuroraSpacing.sm),
            Text(job != null ? 'Interview prep' : 'Interview Simulator', style: AuroraText.displayM),
            const SizedBox(height: AuroraSpacing.lg),
            const Center(child: AuraOrb(size: 76)),
            const SizedBox(height: AuroraSpacing.lg),
            if (job != null) ...[
              GlassContainer(
                borderColor: AuroraColors.cyan.withValues(alpha: 0.25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.work_outline, size: 18, color: AuroraColors.cyanSoft),
                    const SizedBox(width: AuroraSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GROUNDED IN THIS JOB', style: AuroraText.caption.copyWith(color: AuroraColors.cyanSoft, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName != null ? '${job.jobTitle} at ${job.companyName}' : job.jobTitle,
                            style: AuroraText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AuroraSpacing.md),
            ],
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How it works', style: AuroraText.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AuroraSpacing.smd),
                  _step('1', job != null
                      ? "Aura asks questions grounded in your resume and this job's real posting."
                      : "Aura asks questions tailored to your resume and target role."),
                  _step('2', 'You answer each one in your own words — Aura adapts: probing deeper on weak answers, moving on from strong ones.'),
                  _step('3', 'After 5-8 exchanges you get a scored readout — strengths, gaps, and a readiness verdict.'),
                ],
              ),
            ),
            if (interview.error != null) ...[
              const SizedBox(height: AuroraSpacing.md),
              Text(interview.error!, style: AuroraText.bodySm.copyWith(color: AuroraColors.danger)),
            ],
            const SizedBox(height: AuroraSpacing.lg),
            AuroraButton(
              label: 'Start interview',
              icon: Icons.play_arrow_rounded,
              expand: true,
              onPressed: () => context.read<InterviewState>().start(
                    resumeText: resume.rebuiltResume ?? resume.resumeText!,
                    targetRole: resume.targetRole.isEmpty ? (job?.jobTitle ?? 'this role') : resume.targetRole,
                    job: job,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSpacing.smd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AuroraColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AuroraRadius.pill),
              border: Border.all(color: AuroraColors.cyan.withValues(alpha: 0.3)),
            ),
            child: Text(n, style: AuroraText.mono.copyWith(fontSize: 11, color: AuroraColors.cyanSoft)),
          ),
          const SizedBox(width: AuroraSpacing.smd),
          Expanded(child: Text(text, style: AuroraText.body.copyWith(fontSize: 13.5, height: 1.5))),
        ],
      ),
    );
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuraOrb(size: 56),
          const SizedBox(height: AuroraSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, style: AuroraText.body.copyWith(color: AuroraColors.mist), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final interview = context.read<InterviewState>();
    if (interview.currentQuestion == null) return; // already waiting on the next question
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final resume = context.read<ResumeState>();
    interview.answerCurrent(
          answer: text,
          resumeText: resume.rebuiltResume ?? resume.resumeText!,
          targetRole: resume.targetRole.isEmpty ? (interview.jobContext?.jobTitle ?? 'this role') : resume.targetRole,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AuroraMotion.panel,
          curve: AuroraMotion.auroraEase,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final interview = context.watch<InterviewState>();
    final needsRetry = interview.needsEvaluationRetry;
    final waiting = interview.currentQuestion == null && !needsRetry;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const AuraOrb(size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Interview in progress',
                    style: AuroraText.bodySm.copyWith(color: AuroraColors.ink, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'Turn ${interview.turnNumber}',
                  style: AuroraText.mono.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                ...interview.messages.map((m) => ChatBubble(text: m.text, fromAura: m.fromAura)),
                if (waiting)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: ChatBubble(text: 'Aura is thinking…', fromAura: true),
                  ),
              ],
            ),
          ),
          if (interview.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(interview.error!, style: AuroraText.bodySm.copyWith(color: AuroraColors.danger)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: needsRetry ? _retryRow(context) : _inputRow(waiting),
          ),
        ],
      ),
    );
  }

  Widget _retryRow(BuildContext context) {
    return AuroraButton(
      label: 'Retry scoring',
      icon: Icons.refresh,
      expand: true,
      onPressed: () {
        final resume = context.read<ResumeState>();
        final interview = context.read<InterviewState>();
        interview.retryEvaluation(
          resumeText: resume.rebuiltResume ?? resume.resumeText!,
          targetRole: resume.targetRole.isEmpty ? (interview.jobContext?.jobTitle ?? 'this role') : resume.targetRole,
        );
      },
    );
  }

  Widget _inputRow(bool waiting) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: AuroraText.body,
            minLines: 1,
            maxLines: 4,
            enabled: !waiting,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: waiting ? 'Waiting for the next question…' : 'Type your answer…',
              hintStyle: AuroraText.body.copyWith(color: AuroraColors.mistDim),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AuroraRadius.control),
                borderSide: const BorderSide(color: AuroraColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AuroraRadius.control),
                borderSide: const BorderSide(color: AuroraColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AuroraRadius.control),
                borderSide: const BorderSide(color: AuroraColors.cyan, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AuroraButton(label: 'Send', onPressed: waiting ? null : _submit),
      ],
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView();

  @override
  Widget build(BuildContext context) {
    final result = context.watch<InterviewState>().result!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PREP · RESULTS', style: AuroraText.caption.copyWith(color: AuroraColors.violetSoft)),
            const SizedBox(height: 10),
            Text('Interview readout', style: AuroraText.displayM),
            const SizedBox(height: 20),
            Center(child: ScoreRing(score: result.overallScore, size: 140, label: 'READY')),
            const SizedBox(height: 16),
            if (result.verdict.isNotEmpty)
              GlassContainer(
                borderColor: AuroraColors.cyan.withValues(alpha: 0.25),
                child: Text(result.verdict, style: AuroraText.body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.categories.map((c) => MeterBar(label: c.name, score: c.score)).toList(),
              ),
            ),
            if (result.strengths.isNotEmpty) ...[
              const SizedBox(height: 16),
              _FeedbackCard(title: 'Strengths', items: result.strengths, color: AuroraColors.success),
            ],
            if (result.improvements.isNotEmpty) ...[
              const SizedBox(height: 16),
              _FeedbackCard(title: 'Work on', items: result.improvements, color: AuroraColors.amber),
            ],
            const SizedBox(height: 24),
            AuroraButton(
              label: 'Practice again',
              expand: true,
              variant: AuroraButtonVariant.secondary,
              onPressed: () => context.read<InterviewState>().reset(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.title, required this.items, required this.color});
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AuroraText.bodySm.copyWith(color: color)),
          const SizedBox(height: 12),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: SizedBox(
                      width: 5,
                      height: 5,
                      child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ),
                  ),
                  Expanded(child: Text(t, style: AuroraText.body.copyWith(fontSize: 13.5, height: 1.5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
