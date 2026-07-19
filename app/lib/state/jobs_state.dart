import 'package:flutter/foundation.dart';
import '../models/job_models.dart';
import '../services/api_client.dart';

/// Drives the Jobs tab: the AI-scored Match Feed and the Application
/// Tracker. Scoped to the signed-in user — the server derives identity from
/// the caller's verified auth token, not anything sent from the client.
class JobsState extends ChangeNotifier {
  JobsState(this._api);

  final ApiClient _api;

  List<JobMatch> feed = [];
  List<TrackedApplication> applications = [];

  bool loadingFeed = false;
  bool loadingApplications = false;
  String? feedError;
  String? applicationsError;

  Future<void> loadFeed({required String resumeText, required String targetRole}) async {
    loadingFeed = true;
    feedError = null;
    notifyListeners();
    try {
      feed = await _api.fetchJobFeed(resumeText: resumeText, targetRole: targetRole);
    } catch (e) {
      feedError = e.toString();
    }
    loadingFeed = false;
    notifyListeners();
  }

  Future<void> loadApplications() async {
    loadingApplications = true;
    applicationsError = null;
    notifyListeners();
    try {
      applications = await _api.listApplications();
    } catch (e) {
      applicationsError = e.toString();
    }
    loadingApplications = false;
    notifyListeners();
  }

  Future<void> saveJob(String jobId) async {
    final application = await _api.saveJob(jobId: jobId);
    _upsertApplication(application);
    notifyListeners();
  }

  Future<(ApplicationDraft, TrackedApplication)> draftApplication({
    required String jobId,
    required String resumeText,
    required String targetRole,
  }) async {
    final (draft, application) =
        await _api.draftApplication(jobId: jobId, resumeText: resumeText, targetRole: targetRole);
    _upsertApplication(application);
    notifyListeners();
    return (draft, application);
  }

  Future<void> updateStatus(String applicationId, ApplicationStatus status) async {
    final application = await _api.updateApplicationStatus(applicationId: applicationId, status: status);
    _upsertApplication(application);
    notifyListeners();
  }

  /// Called on sign-out so the next signed-in user doesn't see stale data.
  void clear() {
    feed = [];
    applications = [];
    feedError = null;
    applicationsError = null;
    notifyListeners();
  }

  void _upsertApplication(TrackedApplication application) {
    final index = applications.indexWhere((a) => a.id == application.id);
    if (index >= 0) {
      applications[index] = application;
    } else {
      applications.insert(0, application);
    }
  }
}
