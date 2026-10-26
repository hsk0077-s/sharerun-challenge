import 'package:shared_preferences/shared_preferences.dart';

/// 걷기 알림(아침·점심·저녁)을 받을지. 기본은 켜짐(기존 동작 유지).
abstract final class ReminderPreferences {
  static const key = 'walking_reminders_enabled';

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }
}
