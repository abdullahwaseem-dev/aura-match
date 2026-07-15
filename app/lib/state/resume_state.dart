import 'package:flutter/foundation.dart';
import '../models/resume_models.dart';
import '../services/api_client.dart';

enum PipelineStage { empty, scanning, scanned, qa, rebuilding, rebuilt, scoring, scored }

/// Holds the Smart Resume Builder + AI Hiring Manager pipeline state and
/// drives it through the ApiClient. One instance is shared across the
/// Resume Builder and Hiring Manager screens via Provider.
class ResumeState extends ChangeNotifier {
  ResumeState(this._api);

  final ApiClient _api;

  PipelineStage stage = PipelineStage.empty;
  String? fileName;
  String? resumeText;
  String targetRole = '';

  AtsScanResult? scanResult;
  final List<ChatMessage> qaMessages = [];
  final List<QaAnswer> qaAnswers = [];
  int _questionIndex = 0;

  String? rebuiltResume;
  String? persona;
  HiringManagerScorecard? scorecard;

  bool loading = false;
  String? error;

  bool get hasNextQuestion => scanResult != null && _questionIndex < scanResult!.questions.length;
  String? get currentQuestion => hasNextQuestion ? scanResult!.questions[_questionIndex] : null;

  Future<void> uploadResume({required List<int> bytes, required String name, required String role}) async {
    _setLoading(true);
    try {
      final (text, parsedName) = await _api.parseResume(bytes: bytes, fileName: name);
      fileName = parsedName;
      resumeText = text;
      targetRole = role;
      error = null;
      await runScan();
    } catch (e) {
      error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> runScan() async {
    if (resumeText == null || targetRole.isEmpty) return;
    stage = PipelineStage.scanning;
    _setLoading(true);
    try {
      scanResult = await _api.scanResume(resumeText: resumeText!, targetRole: targetRole);
      stage = PipelineStage.scanned;
      error = null;
    } catch (e) {
      error = e.toString();
      stage = PipelineStage.empty;
    }
    _setLoading(false);
  }

  void beginQa() {
    stage = PipelineStage.qa;
    qaMessages.clear();
    qaAnswers.clear();
    _questionIndex = 0;
    if (currentQuestion != null) {
      qaMessages.add(ChatMessage(text: currentQuestion!, fromAura: true));
    }
    notifyListeners();
  }

  Future<void> answerCurrentQuestion(String answer) async {
    final question = currentQuestion;
    if (question == null || answer.trim().isEmpty) return;
    qaMessages.add(ChatMessage(text: answer, fromAura: false));
    qaAnswers.add(QaAnswer(question: question, answer: answer));
    _questionIndex++;
    if (hasNextQuestion) {
      qaMessages.add(ChatMessage(text: currentQuestion!, fromAura: true));
      notifyListeners();
    } else {
      await rebuild();
    }
  }

  Future<void> rebuild() async {
    if (resumeText == null) return;
    stage = PipelineStage.rebuilding;
    _setLoading(true);
    try {
      rebuiltResume = await _api.rebuildResume(resumeText: resumeText!, targetRole: targetRole, qaAnswers: qaAnswers);
      stage = PipelineStage.rebuilt;
      error = null;
    } catch (e) {
      error = e.toString();
      stage = PipelineStage.qa;
    }
    _setLoading(false);
  }

  Future<void> scoreWithPersona(String personaRubric) async {
    final text = rebuiltResume ?? resumeText;
    if (text == null) return;
    persona = personaRubric;
    stage = PipelineStage.scoring;
    _setLoading(true);
    try {
      scorecard = await _api.scoreResume(resumeText: text, persona: personaRubric);
      stage = PipelineStage.scored;
      error = null;
    } catch (e) {
      error = e.toString();
      stage = PipelineStage.rebuilt;
    }
    _setLoading(false);
  }

  void reset() {
    stage = PipelineStage.empty;
    fileName = null;
    resumeText = null;
    targetRole = '';
    scanResult = null;
    qaMessages.clear();
    qaAnswers.clear();
    _questionIndex = 0;
    rebuiltResume = null;
    persona = null;
    scorecard = null;
    error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    loading = value;
    notifyListeners();
  }
}
