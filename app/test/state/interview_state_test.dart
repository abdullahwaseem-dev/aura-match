import 'package:flutter_test/flutter_test.dart';

import 'package:aura_match/models/interview_models.dart';
import 'package:aura_match/services/api_client.dart';
import 'package:aura_match/state/interview_state.dart';

/// Fails the first call to a given method, then behaves normally — lets
/// tests exercise the retry path deterministically without real network I/O.
class _FlakyApiClient extends ApiClient {
  _FlakyApiClient() : super(baseUrl: 'http://unused.invalid');

  bool nextShouldFail = false;
  bool evaluateShouldFail = false;

  @override
  Future<String> startInterview({
    required String resumeText,
    required String targetRole,
    InterviewJobContext? job,
  }) async => 'Opening question?';

  @override
  Future<(bool done, String question)> nextInterviewQuestion({
    required String resumeText,
    required String targetRole,
    InterviewJobContext? job,
    required List<dynamic> transcript,
  }) async {
    if (nextShouldFail) {
      nextShouldFail = false;
      throw ApiException('network blip');
    }
    return (true, '');
  }

  @override
  Future<InterviewResult> evaluateInterview({
    required String resumeText,
    required String targetRole,
    InterviewJobContext? job,
    required List<dynamic> answers,
  }) async {
    if (evaluateShouldFail) {
      evaluateShouldFail = false;
      throw ApiException('scoring service down');
    }
    return InterviewResult(overallScore: 80, categories: const [], strengths: const [], improvements: const [], verdict: 'ok');
  }
}

void main() {
  test('a failed /next call restores the pending question instead of soft-locking', () async {
    final api = _FlakyApiClient()..nextShouldFail = true;
    final state = InterviewState(api);

    await state.start(resumeText: 'resume', targetRole: 'role');
    expect(state.currentQuestion, 'Opening question?');

    await state.answerCurrent(answer: 'my answer', resumeText: 'resume', targetRole: 'role');

    // Before the fix: currentQuestion stayed null forever here, and the
    // chat UI's input box stayed disabled with no way to recover.
    expect(state.error, isNotNull);
    expect(state.currentQuestion, 'Opening question?', reason: 'must restore the question so Send re-enables');
    expect(state.transcript, isEmpty, reason: 'the failed answer must not be recorded as if it succeeded');

    // Retry should now go through since the flaky client only fails once.
    await state.answerCurrent(answer: 'my answer again', resumeText: 'resume', targetRole: 'role');
    expect(state.stage, InterviewStage.results);
  });

  test('a failed evaluation exposes a retry path instead of soft-locking', () async {
    final api = _FlakyApiClient()..evaluateShouldFail = true;
    final state = InterviewState(api);

    await state.start(resumeText: 'resume', targetRole: 'role');
    await state.answerCurrent(answer: 'final answer', resumeText: 'resume', targetRole: 'role');

    // Evaluation failed: stage reverts to inProgress, but there's no pending
    // question (the interview was genuinely done) — this must be
    // distinguishable so the UI can show "Retry scoring" instead of an
    // infinite "Aura is thinking" spinner.
    expect(state.stage, InterviewStage.inProgress);
    expect(state.currentQuestion, isNull);
    expect(state.needsEvaluationRetry, isTrue);

    await state.retryEvaluation(resumeText: 'resume', targetRole: 'role');
    expect(state.stage, InterviewStage.results);
    expect(state.needsEvaluationRetry, isFalse);
  });
}
