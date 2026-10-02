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

  /// Full KST day `[00:00, next midnight)`.
  ///
  /// Samsung Health writes one StepsRecord for the local day. Health Connect
  /// aggregate prorates a record that only partly overlaps the query, so an
  /// end of [now] returns `steps * elapsed/1440` (07:41 KST → 4,696 × 461/1440
  /// = 1,503). The next midnight keeps the whole record inside the window.
  static ({DateTime startDate, DateTime endDate}) todayRange([DateTime? now]) {
    final current = now ?? DateTime.now();
    final kstNow = toKst(current);
    final startUtc = DateTime.utc(
      kstNow.year,
      kstNow.month,
      kstNow.day,
    ).subtract(offset);
    final endUtc = startUtc.add(const Duration(days: 1));
    return (startDate: startUtc.toLocal(), endDate: endUtc.toLocal());
  }

  /// One KST calendar day, `[start, next midnight)`.
  static ({DateTime startDate, DateTime endDate})? dayInterval(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final startUtc = DateTime.utc(year, month, day).subtract(offset);
    final endUtc = startUtc.add(const Duration(days: 1));
    return (startDate: startUtc.toLocal(), endDate: endUtc.toLocal());
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
