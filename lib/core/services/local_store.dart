import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A thin, typed wrapper over [SharedPreferences] used as the app's local
/// persistence layer. It is initialised once at startup and then accessed
/// synchronously, so cubits and stores can read/write without awaiting.
///
/// This is what makes the demo experience feel real: your session, your saved
/// homes and the places you publish all survive a restart, entirely on-device.
class LocalStore {
  LocalStore._(this._prefs);

  static LocalStore? _instance;
  final SharedPreferences _prefs;

  /// The initialised singleton. Call [init] once in `main` before use.
  static LocalStore get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('LocalStore.init() must be awaited before use.');
    }
    return i;
  }

  static Future<LocalStore> init() async {
    final prefs = await SharedPreferences.getInstance();
    return _instance ??= LocalStore._(prefs);
  }

  // ---- Primitives ----
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);

  List<String> getStringList(String key) => _prefs.getStringList(key) ?? const [];
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // ---- JSON helpers ----
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  List<Map<String, dynamic>> getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));
}
