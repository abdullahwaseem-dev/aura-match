import 'package:flutter/foundation.dart';
import '../models/interview_models.dart';
import '../models/resume_models.dart';
import '../services/api_client.dart';

enum InterviewStage { intro, generating, inProgress, evaluating, results }

/// Drives the Interview Simulator: an adaptive, turn-by-turn mock interview.
/// Each answer is sent back to the server, which decides whether to probe
/// deeper on a weak answer, move to a fresh topic, or end the interview
/// (bounded 5-8 turns) — then the full transcript is scored. Optionally
/// grounded in a specific job posting via [jobContext].
class InterviewState extends ChangeNotifier {
  InterviewState(this._api);

  final ApiClient _api;

  InterviewStage stage = InterviewStage.intro;
  InterviewJobContext? jobContext;
  final List<ChatMessage> messages = [];
  final List<QaAnswer> transcript = [];
  String? _pendingQuestion;
  InterviewResult? result;
  String? error;

  String? get currentQuestion => _pendingQuestion;
  int get turnNumber => transcript.length + (_pendingQuestion != null ? 1 : 0);

  /// Sets the job to ground the next session in, without starting it yet —
  /// call from a job card/tracker entry, then navigate to the Prep tab so
  /// the intro screen shows this job before the user taps Start.
  void prepareForJob(InterviewJobContext job) {
    stage = InterviewStage.intro;
    error = null;
    jobContext = job;
    _resetSession();
    notifyListeners();
  }

  Future<void> start({
    required String resumeText,
    required String targetRole,
    InterviewJobContext? job,
  }) async {
    stage = InterviewStage.generating;
    error = null;
    jobContext = job;
    _resetSession();
    notifyListeners();
    try {
      final question = await _api.startInterview(resumeText: resumeText, targetRole: targetRole, job: job);
      _pendingQuestion = question;
      messages.add(ChatMessage(text: question, fromAura: true));
      stage = InterviewStage.inProgress;
    } catch (e) {
      error = e.toString();
      stage = InterviewStage.intro;
    }
    notifyListeners();
  }

  Future<void> answerCurrent({
    required String answer,
    required String resumeText,
    required String targetRole,
  }) async {
    final question = _pendingQuestion;
    if (question == null || answer.trim().isEmpty) return;
    messages.add(ChatMessage(text: answer, fromAura: false));
    transcript.add(QaAnswer(question: question, answer: answer));
    _pendingQuestion = null;
    notifyListeners();

    try {
      final (done, nextQuestion) = await _api.nextInterviewQuestion(
        resumeText: resumeText,
        targetRole: targetRole,
        job: jobContext,
        transcript: transcript,
      );
      if (done) {
        await _evaluate(resumeText: resumeText, targetRole: targetRole);
      } else {
        _pendingQuestion = nextQuestion;
        messages.add(ChatMessage(text: nextQuestion, fromAura: true));
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      // Leave the transcript intact so retrying doesn't lose progress —
      // the last answer is recorded, just re-show the send affordance.
      notifyListeners();
    }
  }

  Future<void> _evaluate({required String resumeText, required String targetRole}) async {
    stage = InterviewStage.evaluating;
    notifyListeners();
    try {
      result = await _api.evaluateInterview(
        resumeText: resumeText,
        targetRole: targetRole,
        job: jobContext,
        answers: transcript,
      );
      stage = InterviewStage.results;
      error = null;
    } catch (e) {
      error = e.toString();
      stage = InterviewStage.inProgress;
    }
    notifyListeners();
  }

  void reset() {
    stage = InterviewStage.intro;
    error = null;
    jobContext = null;
    _resetSession();
    notifyListeners();
  }

  void _resetSession() {
    messages.clear();
    transcript.clear();
    _pendingQuestion = null;
    result = null;
  }
}
