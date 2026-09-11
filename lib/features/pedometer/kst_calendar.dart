/// Korea Standard Time (UTC+9) calendar helpers for pedometer day keys.
///
/// Daily steps, harvest watermarks, and success flags roll at KST midnight,
/// not the device's local timezone alone.
abstract final class KstCalendar {
  static const offset = Duration(hours: 9);

  static DateTime toKst(DateTime now) => now.toUtc().add(offset);

  static String dateKey([DateTime? now]) {
    final kstNow = toKst(now ?? DateTime.now());
    final m = kstNow.month.toString().padLeft(2, '0');
    final d = kstNow.day.toString().padLeft(2, '0');
    return '${kstNow.year}-$m-$d';
  }

  static String dateKeyFromYmd(int year, int month, int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  /// KST 당일 00:00 (UTC) ~ [now]. Health plugins want local DateTimes.
  static ({DateTime startDate, DateTime endDate}) todayRange([DateTime? now]) {
    final current = now ?? DateTime.now();
    final kstNow = toKst(current);
    final startUtc = DateTime.utc(
      kstNow.year,
      kstNow.month,
      kstNow.day,
    ).subtract(offset);
    return (startDate: startUtc.toLocal(), endDate: current);
  }

  /// KST 기준 이번 주 월요일~일요일.
  static List<({int year, int month, int day, String key})> thisWeekDays([
    DateTime? now,
  ]) {
    final kstNow = toKst(now ?? DateTime.now());
    final today = DateTime.utc(kstNow.year, kstNow.month, kstNow.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return (
        year: d.year,
        month: d.month,
        day: d.day,
        key: dateKeyFromYmd(d.year, d.month, d.day),
      );
    });
  }
}
