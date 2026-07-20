import 'package:flutter/foundation.dart';
import '../models/profile_models.dart';
import '../services/api_client.dart';

/// Saved resume snapshots — separate from the live pipeline in [ResumeState],
/// which holds only the resume currently being worked on.
class ResumeLibraryState extends ChangeNotifier {
  ResumeLibraryState(this._api);

  final ApiClient _api;

  List<SavedResume> resumes = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      resumes = await _api.listSavedResumes();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<SavedResumeDetail> fetch(String id) => _api.fetchSavedResume(id);

  Future<void> save({
    required String fileName,
    required String resumeText,
    required String targetRole,
    int? atsScore,
  }) async {
    final saved = await _api.saveResumeToLibrary(
      fileName: fileName,
      resumeText: resumeText,
      targetRole: targetRole,
      atsScore: atsScore,
    );
    resumes.insert(0, saved);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _api.deleteSavedResume(id);
    resumes.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// Called on sign-out so the next signed-in user doesn't see stale data.
  void clear() {
    resumes = [];
    error = null;
    notifyListeners();
  }
}
