import 'package:flutter/foundation.dart';
import '../models/interview_models.dart';
import '../models/resume_models.dart';
import '../services/api_client.dart';

enum InterviewStage { intro, generating, inProgress, evaluating, results }

/// Drives the Interview Simulator: generate resume-grounded questions, run a
/// chat-style Q&A, then score the transcript. Grounded in the same resume the
/// user scanned in the Resume tab.
class InterviewState extends ChangeNotifier {
  InterviewState(this._api);

  final ApiClient _api;

  InterviewStage stage = InterviewStage.intro;
  List<String> questions = [];
  final List<ChatMessage> messages = [];
  final List<QaAnswer> answers = [];
  int _index = 0;
  InterviewResult? result;
  String? error;

  bool get hasCurrentQuestion => _index < questions.length;
  String? get currentQuestion => hasCurrentQuestion ? questions[_index] : null;
  int get questionNumber => _index + 1;
  int get totalQuestions => questions.length;

  Future<void> start({required String resumeText, required String targetRole}) async {
    stage = InterviewStage.generating;
    error = null;
    _reset();
    notifyListeners();
    try {
      questions = await _api.startInterview(resumeText: resumeText, targetRole: targetRole);
      stage = InterviewStage.inProgress;
      if (currentQuestion != null) messages.add(ChatMessage(text: currentQuestion!, fromAura: true));
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
    final question = currentQuestion;
    if (question == null || answer.trim().isEmpty) return;
    messages.add(ChatMessage(text: answer, fromAura: false));
    answers.add(QaAnswer(question: question, answer: answer));
    _index++;
    if (hasCurrentQuestion) {
      messages.add(ChatMessage(text: currentQuestion!, fromAura: true));
      notifyListeners();
    } else {
      await _evaluate(resumeText: resumeText, targetRole: targetRole);
    }
  }

  Future<void> _evaluate({required String resumeText, required String targetRole}) async {
    stage = InterviewStage.evaluating;
    notifyListeners();
    try {
      result = await _api.evaluateInterview(resumeText: resumeText, targetRole: targetRole, answers: answers);
      stage = InterviewStage.results;
      error = null;
    } catch (e) {
      error = e.toString();
      // Keep the transcript so the user can retry evaluation without redoing the interview.
      stage = InterviewStage.inProgress;
    }
    notifyListeners();
  }

  Future<void> retryEvaluation({required String resumeText, required String targetRole}) =>
      _evaluate(resumeText: resumeText, targetRole: targetRole);

  void reset() {
    stage = InterviewStage.intro;
    error = null;
    _reset();
    notifyListeners();
  }

  void _reset() {
    questions = [];
    messages.clear();
    answers.clear();
    _index = 0;
    result = null;
  }
}
