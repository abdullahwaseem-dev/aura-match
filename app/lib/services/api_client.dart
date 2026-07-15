import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/resume_models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the local AURA MATCH backend (see /server).
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  final String baseUrl;

  static String _defaultBaseUrl() {
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
