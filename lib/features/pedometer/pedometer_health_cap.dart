import 'package:shared_preferences/shared_preferences.dart';

import 'pedometer_step_truth.dart';

/// Last positive Health Connect total for this KST day, shared by every isolate.
///
/// The in-memory cap dies when the UI or the foreground isolate restarts.
/// Health Connect then returns 0 or throws in the background, and a stale
/// 29,999 store is maxed back. This pref is the ceiling until the next KST day.
abstract final class PedometerHealthCap {
  static const dayKey = 'pedometer_health_cap_day';
  static const stepsKey = 'pedometer_health_cap_steps';

  static int? _memory;
  static String _memoryDay = '';

  /// Same-isolate copy. A different KST day does not apply yesterday's cap.
  static int? cached(String todayKey) {
    if (_memoryDay != todayKey) return null;
    final steps = _memory;
    if (steps == null || steps <= 0) return null;
    return steps;
  }

  static void remember(String todayKey, int health) {
    if (health <= 0) return;
    _memoryDay = todayKey;
    _memory = health;
  }

  static void forget() {
    _memory = null;
    _memoryDay = '';
  }

  static int? fromPrefs(SharedPreferences prefs, {required String todayKey}) {
    final day = prefs.getString(dayKey);
    if (day != todayKey) return null;
    final steps = prefs.getInt(stepsKey);
    if (steps == null || steps <= 0) return null;
    remember(todayKey, steps);
    return steps;
  }

  static Future<void> persist(
    SharedPreferences prefs, {
    required String todayKey,
    required int health,
  }) async {
    if (health <= 0) return;
    remember(todayKey, health);
    await prefs.setString(dayKey, todayKey);
    await prefs.setInt(stepsKey, health);
  }

  static Future<void> clear(SharedPreferences prefs) async {
    forget();
    await prefs.remove(dayKey);
    await prefs.remove(stepsKey);
  }

  /// Another isolate's `setInt` is invisible until [SharedPreferences.reload].
  static Future<SharedPreferences> fresh() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {}
    return prefs;
  }

  /// Live positive health wins. Otherwise [persisted] for today.
  static int? effective({required int? live, required int? persisted}) {
    if (live != null && live > 0) return live;
    if (persisted != null && persisted > 0) return persisted;
    return null;
  }

  /// Steps at or under the last positive Health reading, plus the lead.
  /// No reading means [PedometerStepTruth.clampDaily] only.
  static int cap(int steps, int? health) {
    if (health == null || health <= 0) {
      return PedometerStepTruth.clampDaily(steps);
    }
    return PedometerStepTruth.dailyFromSources(
      liveDaily: steps,
      healthToday: health,
    );
  }
}
