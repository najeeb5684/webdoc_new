import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> putString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String? getString(String key, {String? defaultValue}) {
    return _prefs?.getString(key) ?? defaultValue;
  }

  static Future<void> putInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static int? getInt(String key, {int? defaultValue}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  static Future<void> putBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static bool? getBool(String key, {bool? defaultValue}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  static Future<void> clear() async {
    await _prefs?.clear();
  }

  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? Future.value(false);
  }
}