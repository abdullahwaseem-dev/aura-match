import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Account-level settings and privacy actions — separate from [AuthState]
/// (which owns the session itself) since these are app data, not auth.
class ProfileState extends ChangeNotifier {
  ProfileState(this._api);

  final ApiClient _api;

  bool autoDraftEnabled = false;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final profile = await _api.fetchProfile();
      autoDraftEnabled = profile.autoDraftEnabled;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setAutoDraftEnabled(bool enabled) async {
    final previous = autoDraftEnabled;
    autoDraftEnabled = enabled; // optimistic
    notifyListeners();
    try {
      final profile = await _api.setAutoDraftEnabled(enabled);
      autoDraftEnabled = profile.autoDraftEnabled;
    } catch (e) {
      autoDraftEnabled = previous; // roll back
      error = e.toString();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> exportData() => _api.exportPrivacyData();

  Future<void> deleteAllData() => _api.deleteAllMyData();

  /// Called on sign-out so the next signed-in user doesn't see stale settings.
  void clear() {
    autoDraftEnabled = false;
    error = null;
    notifyListeners();
  }
}
