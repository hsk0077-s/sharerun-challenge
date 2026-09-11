import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/kst_calendar.dart';

void main() {
  test('KST dateKey rolls at UTC 15:00 (midnight UTC+9)', () {
    final justBefore = DateTime.utc(2026, 9, 8, 14, 59);
    final atMidnight = DateTime.utc(2026, 9, 8, 15);
    expect(KstCalendar.dateKey(justBefore), '2026-09-08');
    expect(KstCalendar.dateKey(atMidnight), '2026-09-09');
  });

  test('KST todayRange starts at previous UTC 15:00', () {
    final now = DateTime.utc(2026, 9, 9, 1, 30);
    final range = KstCalendar.todayRange(now);
    expect(range.startDate.toUtc(), DateTime.utc(2026, 9, 8, 15));
    expect(range.endDate.toUtc(), now);
  });

  test('thisWeekDays is Monday-Sunday in KST', () {
    // Wednesday 2026-09-09 01:00 UTC = 10:00 KST Wednesday.
    final days = KstCalendar.thisWeekDays(DateTime.utc(2026, 9, 9, 1));
    expect(days.length, 7);
    expect(days.first.key, '2026-09-07'); // Monday
    expect(days.last.key, '2026-09-13');
  });
}
