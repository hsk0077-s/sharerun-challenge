import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/constants/economy_constants.dart';
import '../../data/models/activity_model.dart';
import '../pedometer/account_daily_steps_provider.dart';
import '../pedometer/kst_calendar.dart';

/// Everything on My Page below 천사연대기: 불꽃 유지, 연속 출석 calendar,
/// 러닝 로그, and the week chart (month distance and pace).
///
/// Those four sections read only this provider. A KST day counts from the
/// account: a non-rejected activity with distance > 0, or
/// `users/{uid}/daily_metrics/{day}` steps/km greater than zero.
/// Per day, kilometres are the larger of activity distance and the server
/// walk kilometres so a walk is not added on top of a run.
///
/// Consecutive streak ends at today, or at yesterday when today has no
/// record yet. This display streak does not change wallet bonuses.
class MyPageLogEntry {
  const MyPageLogEntry({
    required this.dateLabel,
    required this.km,
    this.activity,
    this.walk = false,
  });

  final String dateLabel;
  final double km;
  final ActivityModel? activity;
  final bool walk;
}

class MyPageActivityStats {
  const MyPageActivityStats({
    required this.streakDays,
    required this.activeMonthDays,
    required this.crownDay,
    required this.daysInMonth,
    required this.weekKm,
    required this.monthKm,
    required this.paceLabel,
    required this.stampedWeekdays,
    required this.logEntries,
  });

  final int streakDays;
  final Set<int> activeMonthDays;
  final int? crownDay;
  final int daysInMonth;
  final List<double> weekKm;
  final double monthKm;
  final String paceLabel;

  /// `DateTime.weekday` (Monday = 1) for qualified days in the current KST week.
  final Set<int> stampedWeekdays;
  final List<MyPageLogEntry> logEntries;

  String get monthDistanceLabel => '${monthKm.toStringAsFixed(1)} KM';
}

final myPageActivityStatsProvider = Provider<MyPageActivityStats>((ref) {
  final activities = ref.watch(recentActivitiesProvider).value ?? const [];
  final days =
      ref.watch(accountDailyMetricsProvider).asData?.value ?? const [];
  final stepsByDate = <String, int>{};
  final kmByDate = <String, double>{};
  for (final day in days) {
    if (day.steps > 0) stepsByDate[day.dayKey] = day.steps;
    if (day.km > 0) kmByDate[day.dayKey] = day.km;
  }
  return MyPageActivityMath.compute(
    activities: activities,
    stepsByDate: stepsByDate,
    kmByDate: kmByDate,
    now: DateTime.now(),
  );
});

abstract final class MyPageActivityMath {
  static const _streakGuard = 5000;

  static MyPageActivityStats compute({
    required List<ActivityModel> activities,
    required Map<String, int> stepsByDate,
    required Map<String, double> kmByDate,
    required DateTime now,
  }) {
    final kstNow = KstCalendar.toKst(now);
    final today = DateTime.utc(kstNow.year, kstNow.month, kstNow.day);
    final todayKey = KstCalendar.dateKeyFromYmd(
      today.year,
      today.month,
      today.day,
    );

    final activityKm = <String, double>{};
    final activityOnDay = <String, bool>{};
    final counted = <ActivityModel>[];
    for (final activity in activities) {
      if (!_counts(activity)) continue;
      final key = KstCalendar.dateKey(activity.completedAt!);
      activityKm[key] = (activityKm[key] ?? 0) + activity.distanceKm;
      activityOnDay[key] = true;
      counted.add(activity);
    }

    final keys = <String>{
      ...activityKm.keys,
      ...stepsByDate.keys,
      ...kmByDate.keys,
    };
    final dayKm = <String, double>{};
    final qualifying = <String>{};
    for (final key in keys) {
      final steps = stepsByDate[key] ?? 0;
      final storedKm = kmByDate[key] ?? 0;
      final walkKm =
          storedKm > 0 ? storedKm : (steps > 0 ? _kmFromSteps(steps) : 0.0);
      final fromActivity = activityKm[key] ?? 0;
      final km = fromActivity > walkKm ? fromActivity : walkKm;
      if (km > 0) dayKm[key] = km;
      if (fromActivity > 0 || steps > 0 || storedKm > 0) {
        qualifying.add(key);
      }
    }

    final streak = _streakEnding(todayKey, qualifying);
    final daysInMonth = DateTime.utc(today.year, today.month + 1, 0).day;
    final active = <int>{};
    for (final key in qualifying) {
      final parts = _parseKey(key);
      if (parts == null) continue;
      if (parts.year != today.year || parts.month != today.month) continue;
      if (parts.day < 1 || parts.day > today.day) continue;
      active.add(parts.day);
    }
    final crown =
        active.isEmpty ? null : active.reduce((a, b) => a > b ? a : b);

    final week = KstCalendar.thisWeekDays(now);
    final weekKm = <double>[
      for (final day in week) dayKm[day.key] ?? 0,
    ];
    final stamped = <int>{};
    for (final day in week) {
      if (!qualifying.contains(day.key)) continue;
      stamped.add(DateTime.utc(day.year, day.month, day.day).weekday);
    }

    var monthKm = 0.0;
    for (var day = 1; day <= today.day; day++) {
      final key = KstCalendar.dateKeyFromYmd(today.year, today.month, day);
      monthKm += dayKm[key] ?? 0;
    }

    final logs = <({int millis, MyPageLogEntry entry})>[];
    for (final activity in counted) {
      final at = activity.completedAt!;
      logs.add((
        millis: at.millisecondsSinceEpoch,
        entry: MyPageLogEntry(
          dateLabel: _dateLabel(KstCalendar.toKst(at)),
          km: activity.distanceKm,
          activity: activity,
        ),
      ));
    }
    for (final key in qualifying) {
      if (activityOnDay[key] == true) continue;
      final steps = stepsByDate[key] ?? 0;
      final storedKm = kmByDate[key] ?? 0;
      if (steps <= 0 && storedKm <= 0) continue;
      final parts = _parseKey(key);
      if (parts == null) continue;
      final walkKm = dayKm[key] ?? 0;
      if (walkKm <= 0 && steps <= 0) continue;
      logs.add((
        millis: DateTime.utc(parts.year, parts.month, parts.day)
            .millisecondsSinceEpoch,
        entry: MyPageLogEntry(
          dateLabel: _dateLabel(
            DateTime.utc(parts.year, parts.month, parts.day),
          ),
          km: walkKm > 0 ? walkKm : _kmFromSteps(steps),
          walk: true,
        ),
      ));
    }
    logs.sort((a, b) => b.millis.compareTo(a.millis));
    final logEntries = <MyPageLogEntry>[
      for (final row in logs.take(8)) row.entry,
    ];

    return MyPageActivityStats(
      streakDays: streak,
      activeMonthDays: active,
      crownDay: crown,
      daysInMonth: daysInMonth,
      weekKm: weekKm,
      monthKm: monthKm,
      paceLabel: _paceLabel(counted, today),
      stampedWeekdays: stamped,
      logEntries: logEntries,
    );
  }

  static bool _counts(ActivityModel activity) {
    final at = activity.completedAt;
    if (at == null || activity.distanceKm <= 0) return false;
    return activity.validationStatus != ActivityValidationStatus.rejected;
  }

  static double _kmFromSteps(int steps) {
    if (steps <= 0) return 0;
    return (steps * EconomyConstants.pedometerStrideMeters) / 1000.0;
  }

  static int _streakEnding(String todayKey, Set<String> qualifying) {
    var cursor = todayKey;
    if (!qualifying.contains(cursor)) {
      cursor = _previousKey(cursor);
    }
    var streak = 0;
    while (qualifying.contains(cursor) && streak < _streakGuard) {
      streak += 1;
      cursor = _previousKey(cursor);
    }
    return streak;
  }

  static String _previousKey(String key) {
    final parts = _parseKey(key);
    if (parts == null) return key;
    final previous = DateTime.utc(parts.year, parts.month, parts.day)
        .subtract(const Duration(days: 1));
    return KstCalendar.dateKeyFromYmd(
      previous.year,
      previous.month,
      previous.day,
    );
  }

  static ({int year, int month, int day})? _parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return (year: year, month: month, day: day);
  }

  static String _dateLabel(DateTime kst) {
    final m = kst.month.toString().padLeft(2, '0');
    final d = kst.day.toString().padLeft(2, '0');
    return '${kst.year}.$m.$d';
  }

  static String _paceLabel(List<ActivityModel> counted, DateTime today) {
    final monthPrefix =
        KstCalendar.dateKeyFromYmd(today.year, today.month, 1).substring(0, 7);
    var weighted = 0.0;
    var km = 0.0;
    for (final activity in counted) {
      final pace = activity.averagePaceSecondsPerKm;
      if (pace == null || pace <= 0) continue;
      final key = KstCalendar.dateKey(activity.completedAt!);
      if (!key.startsWith(monthPrefix)) continue;
      weighted += pace * activity.distanceKm;
      km += activity.distanceKm;
    }
    if (km <= 0) return '—';
    final total = (weighted / km).round();
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /KM';
  }
}
