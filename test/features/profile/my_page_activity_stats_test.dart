import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/activity_model.dart';
import 'package:share_run_challenge/features/pedometer/kst_calendar.dart';
import 'package:share_run_challenge/features/profile/my_page_activity_stats.dart';

ActivityModel _activity({
  required String id,
  required double km,
  required DateTime completedAt,
  ActivityValidationStatus status = ActivityValidationStatus.verified,
  double? paceSeconds,
}) {
  return ActivityModel(
    id: id,
    userId: 'u',
    distanceKm: km,
    durationSeconds: 600,
    averagePaceSecondsPerKm: paceSeconds,
    completedAt: completedAt,
    validationStatus: status,
    jenaReason: null,
  );
}

void main() {
  // 2026-09-25 16:00 UTC = 2026-09-26 01:00 KST (Saturday).
  final now = DateTime.utc(2026, 9, 25, 16);

  test('empty sources stay empty', () {
    final stats = MyPageActivityMath.compute(
      activities: const [],
      stepsByDate: const {},
      kmByDate: const {},
      now: now,
    );

    expect(stats.streakDays, 0);
    expect(stats.activeMonthDays, isEmpty);
    expect(stats.crownDay, isNull);
    expect(stats.daysInMonth, 30);
    expect(stats.weekKm, [0, 0, 0, 0, 0, 0, 0]);
    expect(stats.monthKm, 0);
    expect(stats.monthDistanceLabel, '0.0 KM');
    expect(stats.paceLabel, '—');
    expect(stats.stampedWeekdays, isEmpty);
    expect(stats.logEntries, isEmpty);
  });

  test('KST day boundary, streak, crown, pace, and week chart', () {
    final stats = MyPageActivityMath.compute(
      activities: [
        _activity(
          id: 'today',
          km: 2,
          paceSeconds: 300,
          // 2026-09-25 15:30 UTC = 2026-09-26 00:30 KST.
          completedAt: DateTime.utc(2026, 9, 25, 15, 30),
        ),
        _activity(
          id: 'yesterday',
          km: 4,
          paceSeconds: 360,
          // 2026-09-24 16:00 UTC = 2026-09-25 01:00 KST.
          completedAt: DateTime.utc(2026, 9, 24, 16),
        ),
        _activity(
          id: 'gap',
          km: 8,
          completedAt: DateTime.utc(2026, 9, 22, 16),
        ),
        _activity(
          id: 'rejected',
          km: 9,
          status: ActivityValidationStatus.rejected,
          completedAt: DateTime.utc(2026, 9, 23, 16),
        ),
      ],
      stepsByDate: const {},
      kmByDate: const {},
      now: now,
    );

    expect(stats.streakDays, 2);
    expect(stats.activeMonthDays, {23, 25, 26});
    expect(stats.crownDay, 26);
    expect(stats.monthKm, 14);
    expect(stats.paceLabel, '5:40 /KM');
    expect(
      stats.stampedWeekdays,
      {DateTime.wednesday, DateTime.friday, DateTime.saturday},
    );
    expect(stats.weekKm[4], 4);
    expect(stats.weekKm[5], 2);
    expect(stats.logEntries.map((entry) => entry.km), [2, 4, 8]);
    expect(stats.logEntries.first.dateLabel, '2026.09.26');
    expect(stats.logEntries.first.activity?.id, 'today');
  });

  test('today without a record still continues yesterday', () {
    final stats = MyPageActivityMath.compute(
      activities: [
        _activity(
          id: 'yesterday',
          km: 1.2,
          completedAt: DateTime.utc(2026, 9, 24, 16),
        ),
      ],
      stepsByDate: const {},
      kmByDate: const {},
      now: now,
    );

    expect(stats.streakDays, 1);
    expect(stats.crownDay, 25);
    expect(stats.activeMonthDays.contains(26), isFalse);
  });

  test('walk-only day counts and is not double-added onto a run', () {
    final monday = KstCalendar.dateKeyFromYmd(2026, 9, 21);
    final today = KstCalendar.dateKeyFromYmd(2026, 9, 26);
    final stats = MyPageActivityMath.compute(
      activities: [
        _activity(
          id: 'run',
          km: 3.2,
          completedAt: DateTime.utc(2026, 9, 25, 15, 30),
        ),
      ],
      stepsByDate: {monday: 2000, today: 4000},
      kmByDate: {today: 1.5},
      now: now,
    );

    expect(stats.streakDays, 1);
    expect(stats.activeMonthDays, {21, 26});
    expect(stats.monthKm, closeTo(3.2 + 1.5, 0.001));
    expect(stats.weekKm[0], closeTo(1.5, 0.001));
    expect(stats.weekKm[5], 3.2);
    expect(stats.logEntries.where((entry) => entry.walk), hasLength(1));
    expect(stats.logEntries.first.walk, isFalse);
    expect(stats.stampedWeekdays, {DateTime.monday, DateTime.saturday});
  });

  test('previous month counts for streak but not this month total', () {
    final october = DateTime.utc(2026, 9, 30, 15);
    final stats = MyPageActivityMath.compute(
      activities: [
        _activity(
          id: 'sep',
          km: 5,
          paceSeconds: 300,
          completedAt: DateTime.utc(2026, 9, 29, 16),
        ),
      ],
      stepsByDate: const {},
      kmByDate: const {},
      now: october,
    );

    expect(KstCalendar.dateKey(october), '2026-10-01');
    expect(stats.streakDays, 1);
    expect(stats.monthKm, 0);
    expect(stats.paceLabel, '—');
    expect(stats.activeMonthDays, isEmpty);
    expect(stats.daysInMonth, 31);
    expect(stats.logEntries, hasLength(1));
  });

  test('pending activity counts and a gap breaks the streak', () {
    final stats = MyPageActivityMath.compute(
      activities: [
        _activity(
          id: 'pending',
          km: 1,
          status: ActivityValidationStatus.pending,
          completedAt: DateTime.utc(2026, 9, 25, 15, 30),
        ),
        _activity(
          id: 'older',
          km: 1,
          completedAt: DateTime.utc(2026, 9, 23, 16),
        ),
      ],
      stepsByDate: const {},
      kmByDate: const {},
      now: now,
    );

    expect(stats.streakDays, 1);
    expect(stats.activeMonthDays, {24, 26});
    expect(stats.logEntries, hasLength(2));
  });

  test('a server-covered miss keeps the streak and adds no distance', () {
    final without = MyPageActivityMath.compute(
      activities: const [],
      stepsByDate: const {'2026-09-24': 1000},
      kmByDate: const {},
      now: now,
    );
    final covered = MyPageActivityMath.compute(
      activities: const [],
      stepsByDate: const {'2026-09-24': 1000},
      kmByDate: const {},
      coveredDays: const {'2026-09-25'},
      now: now,
    );

    expect(without.streakDays, 0);
    expect(covered.streakDays, 2);
    expect(covered.monthKm, without.monthKm);
    expect(covered.activeMonthDays.contains(25), isTrue);
    expect(
      covered.logEntries.map((entry) => entry.dateLabel).toList(),
      ['2026.09.24'],
    );
  });

  test('a rest day pauses the streak without counting as a run', () {
    final paused = MyPageActivityMath.compute(
      activities: const [],
      stepsByDate: const {'2026-09-24': 1000, '2026-09-26': 800},
      kmByDate: const {},
      pausedDays: const {'2026-09-25'},
      now: now,
    );
    final broken = MyPageActivityMath.compute(
      activities: const [],
      stepsByDate: const {'2026-09-24': 1000, '2026-09-26': 800},
      kmByDate: const {},
      now: now,
    );

    expect(paused.streakDays, 2);
    expect(broken.streakDays, 1);
    expect(paused.activeMonthDays.contains(25), isFalse);
    expect(paused.activeMonthDays, {24, 26});
    expect(
      paused.logEntries.map((entry) => entry.dateLabel).toList(),
      isNot(contains('2026.09.25')),
    );
  });
}
