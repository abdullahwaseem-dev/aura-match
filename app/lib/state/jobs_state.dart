import 'package:flutter/foundation.dart';
import '../models/job_models.dart';
import '../services/api_client.dart';
import '../services/device_identity.dart';

/// Drives the Jobs tab: the AI-scored Match Feed and the Application
/// Tracker. Scoped to this install via [DeviceIdentity] — there's no auth
/// system yet, so "my applications" means "this device's applications".
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
      final deviceId = await DeviceIdentity.get();
      feed = await _api.fetchJobFeed(deviceId: deviceId, resumeText: resumeText, targetRole: targetRole);
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
      final deviceId = await DeviceIdentity.get();
      applications = await _api.listApplications(deviceId: deviceId);
    } catch (e) {
      applicationsError = e.toString();
    }
    loadingApplications = false;
    notifyListeners();
  }

  Future<void> saveJob(String jobId) async {
    final deviceId = await DeviceIdentity.get();
    final application = await _api.saveJob(deviceId: deviceId, jobId: jobId);
    _upsertApplication(application);
    notifyListeners();
  }

  Future<(ApplicationDraft, TrackedApplication)> draftApplication({
    required String jobId,
    required String resumeText,
    required String targetRole,
  }) async {
    final deviceId = await DeviceIdentity.get();
    final (draft, application) =
        await _api.draftApplication(jobId: jobId, deviceId: deviceId, resumeText: resumeText, targetRole: targetRole);
    _upsertApplication(application);
    notifyListeners();
    return (draft, application);
  }

  Future<void> updateStatus(String applicationId, ApplicationStatus status) async {
    final deviceId = await DeviceIdentity.get();
    final application = await _api.updateApplicationStatus(applicationId: applicationId, deviceId: deviceId, status: status);
    _upsertApplication(application);
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
