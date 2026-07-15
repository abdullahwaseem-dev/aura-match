import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A random per-install identity used to scope the Jobs feed and Application
/// Tracker before real Supabase Auth exists. Not a security boundary — just
/// enough to keep one install's saved jobs separate from another's.
class DeviceIdentity {
  static const _key = 'aura_device_id';
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }
}
