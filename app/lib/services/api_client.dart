import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/resume_models.dart';
import '../models/job_models.dart';
import '../models/interview_models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the AURA MATCH backend (see /server).
///
/// Defaults to the local dev server. Point at the deployed backend with:
///   flutter run --dart-define=API_BASE_URL=https://aura-match.onrender.com
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  final String baseUrl;

  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String _defaultBaseUrl() {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost:8787';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8787';
    } catch (_) {
      // Platform is unavailable on some targets (web already handled above).
    }
    return 'http://localhost:8787';
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/health')).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['aiConfigured'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<(String text, String fileName)> parseResume({
    required List<int> bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/resume/parse');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decode(res);
    return (body['text'] as String, body['fileName'] as String);
  }

  Future<AtsScanResult> scanResume({required String resumeText, required String targetRole}) async {
    final body = await _post('/api/resume/scan', {'resumeText': resumeText, 'targetRole': targetRole});
    return AtsScanResult.fromJson(body);
  }

  Future<String> rebuildResume({
    required String resumeText,
    required String targetRole,
    required List<QaAnswer> qaAnswers,
  }) async {
    final body = await _post('/api/resume/rebuild', {
      'resumeText': resumeText,
      'targetRole': targetRole,
      'qaAnswers': qaAnswers.map((e) => e.toJson()).toList(),
    });
    return body['rebuiltResume'] as String;
  }

  Future<HiringManagerScorecard> scoreResume({required String resumeText, required String persona}) async {
    final body = await _post('/api/hiring-manager/score', {'resumeText': resumeText, 'persona': persona});
    return HiringManagerScorecard.fromJson(body);
  }

  Future<List<JobMatch>> fetchJobFeed({
    required String deviceId,
    required String resumeText,
    required String targetRole,
  }) async {
    final body = await _post(
      '/api/jobs/feed',
      {'deviceId': deviceId, 'resumeText': resumeText, 'targetRole': targetRole},
    );
    return (body['matches'] as List).map((e) => JobMatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<(ApplicationDraft draft, TrackedApplication application)> draftApplication({
    required String jobId,
    required String deviceId,
    required String resumeText,
    required String targetRole,
  }) async {
    final body = await _post(
      '/api/jobs/$jobId/draft',
      {'deviceId': deviceId, 'resumeText': resumeText, 'targetRole': targetRole},
    );
    return (
      ApplicationDraft.fromJson(body),
      TrackedApplication.fromJson(body['application'] as Map<String, dynamic>),
    );
  }

  Future<List<TrackedApplication>> listApplications({required String deviceId}) async {
    final uri = Uri.parse('$baseUrl/api/applications').replace(queryParameters: {'deviceId': deviceId});
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final body = _decode(res);
    return (body['applications'] as List).map((e) => TrackedApplication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TrackedApplication> saveJob({required String deviceId, required String jobId}) async {
    final body = await _post('/api/applications', {'deviceId': deviceId, 'jobId': jobId});
    return TrackedApplication.fromJson(body['application'] as Map<String, dynamic>);
  }

  Future<TrackedApplication> updateApplicationStatus({
    required String applicationId,
    required String deviceId,
    required ApplicationStatus status,
  }) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl/api/applications/$applicationId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'deviceId': deviceId, 'status': status.name}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decode(res);
    return TrackedApplication.fromJson(body['application'] as Map<String, dynamic>);
  }

  Future<String> startInterview({
    required String resumeText,
    required String targetRole,
    InterviewJobContext? job,
  }) async {
    final body = await _post('/api/interview/start', {
      'resumeText': resumeText,
      'targetRole': targetRole,
      ...?job?.toJson(),
    });
    return body['question'] as String;
  }

  /// Returns (done, nextQuestion) — nextQuestion is empty once done is true.
  Future<(bool done, String question)> nextInterviewQuestion({
    required String resumeText,
    required String targetRole,
    InterviewJobContext? job,
    required List<QaAnswer> transcript,
  }) async {
    final body = await _post('/api/interview/next', {
      'resumeText': resumeText,
      'targetRole': targetRole,
      ...?job?.toJson(),
      'transcript': transcript.map((e) => e.toJson()).toList(),
    });
    return (body['done'] as bool, body['question'] as String? ?? '');
  }

  Future<InterviewResult> evaluateInterview({
    required String resumeText,
    required String targetRole,
    InterviewJobContext? job,
    required List<QaAnswer> answers,
  }) async {
    final body = await _post('/api/interview/evaluate', {
      'resumeText': resumeText,
      'targetRole': targetRole,
      ...?job?.toJson(),
      'answers': answers.map((e) => e.toJson()).toList(),
    });
    return InterviewResult.fromJson(body);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 90));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Aura server returned an unreadable response (${res.statusCode}).');
    }
    if (res.statusCode >= 400) {
      throw ApiException(body['error']?.toString() ?? 'Request failed (${res.statusCode}).');
    }
    return body;
  }
}
