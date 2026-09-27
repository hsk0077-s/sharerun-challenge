import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/pedometer_step_truth.dart';

void main() {
  group('PedometerStepTruth.fromSensorEvent', () {
    test('shake/session increment is not killed by a midnight sensor offset', () {
      // Repro: UI 1,835, offset snapshotted at sensor 1,835 (reboot / QA init).
      // Old path: (healthBase + delta) - offset => 5, rejected vs UI 1,835.
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 1840,
          healthBase: 1835,
          sessionDelta: 5,
          stepOffset: 1835,
        ),
        1840,
      );
    });

    test('large midnight offset does not zero Health-today + session', () {
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 50010,
          healthBase: 1835,
          sessionDelta: 10,
          stepOffset: 50000,
        ),
        1845,
      );
    });

    test('offset 0 must not dump since-boot raw totals', () {
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 52000,
          healthBase: 100,
          sessionDelta: 3,
          stepOffset: 0,
        ),
        103,
      );
    });

    test('small stepOffset plus raw 86626 is not today', () {
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 86626,
          healthBase: 0,
          sessionDelta: 0,
          stepOffset: 450,
        ),
        0,
      );
      // Yesterday's daily (or a QA snapshot) as offset must not beat a real walk.
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 86626,
          healthBase: 450,
          sessionDelta: 0,
          stepOffset: 1835,
        ),
        450,
      );
      // Still under the 30,000 ceiling: a small offset must not win.
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 20000,
          healthBase: 0,
          sessionDelta: 0,
          stepOffset: 450,
        ),
        0,
      );
    });

    test('450 steps after a hardware offset still count', () {
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 86450,
          healthBase: 0,
          sessionDelta: 0,
          stepOffset: 86000,
        ),
        450,
      );
    });

    test('athletic day under the ceiling still counts with a hardware offset', () {
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 86000 + 20000,
          healthBase: 20000,
          sessionDelta: 0,
          stepOffset: 86000,
        ),
        20000,
      );
    });

    test('raw minus offset can raise the floor when Health is stale', () {
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 51200,
          healthBase: 80,
          sessionDelta: 0,
          stepOffset: 50000,
        ),
        1200,
      );
    });

    test('yesterday in-memory 39 does not replace today 0', () {
      expect(
        PedometerStepTruth.inMemoryDailyIfSameDay(
          inMemorySteps: 39,
          memoryDayKey: '2026-09-26',
          todayKey: '2026-09-27',
        ),
        0,
      );
      expect(
        PedometerStepTruth.inMemoryDailyIfSameDay(
          inMemorySteps: 39,
          memoryDayKey: '',
          todayKey: '2026-09-27',
        ),
        0,
      );
      expect(
        PedometerStepTruth.mergeStoredDaily(
          storedToday: 0,
          inMemorySteps: 39,
          memoryDayKey: '2026-09-26',
          todayKey: '2026-09-27',
        ),
        0,
      );
      // Same KST day: a live count still ahead of prefs must not be clipped.
      expect(
        PedometerStepTruth.mergeStoredDaily(
          storedToday: 1835,
          inMemorySteps: 1840,
          memoryDayKey: '2026-09-27',
          todayKey: '2026-09-27',
        ),
        1840,
      );
      expect(
        PedometerStepTruth.mergeStoredDaily(
          storedToday: 1835,
          inMemorySteps: 100,
          memoryDayKey: '2026-09-27',
          todayKey: '2026-09-27',
        ),
        1835,
      );
    });

    test('yesterday floor is not reapplied after the KST day flips', () {
      // 5377 was yesterday in Asia/Seoul. Rollover paints 0, then this
      // sample used to win max(healthBase, raw - oldOffset) and put 5377
      // back on today.
      const yesterday = 5377;
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 50000 + yesterday,
          healthBase: yesterday,
          sessionDelta: yesterday,
          stepOffset: 50000,
          floorDayKey: '2026-09-25',
          todayKey: '2026-09-26',
        ),
        0,
      );
      expect(
        PedometerStepTruth.cachedDailyIfSameDay(
          cachedSteps: yesterday,
          cachedDayKey: '2026-09-25',
          todayKey: '2026-09-26',
        ),
        0,
      );
      expect(
        PedometerStepTruth.cachedDailyIfSameDay(
          cachedSteps: 120,
          cachedDayKey: '2026-09-26',
          todayKey: '2026-09-26',
        ),
        120,
      );
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 50000 + 40,
          healthBase: 0,
          sessionDelta: 0,
          stepOffset: 50000,
          floorDayKey: '2026-09-26',
          todayKey: '2026-09-26',
        ),
        40,
      );
    });

    test('baseline 0 then raw 86626 is not today', () {
      final dump = PedometerStepTruth.acceptSensorDelta(
        raw: 86626,
        baseline: 0,
        previousRaw: 0,
      );
      expect(dump.rebase, isTrue);
      expect(dump.delta, 0);
      expect(PedometerStepTruth.isPoisonDaily(86626), isTrue);
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 86626,
          healthBase: 0,
          sessionDelta: dump.delta,
          stepOffset: 0,
        ),
        0,
      );
      // Ceiling backstop if a listener still passes the raw jump as session.
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 86626,
          healthBase: 0,
          sessionDelta: 86626,
          stepOffset: 0,
        ),
        0,
      );
    });

    test('450 steps after a real since-boot baseline still count', () {
      const baseline = 86000;
      final sample = PedometerStepTruth.acceptSensorDelta(
        raw: baseline + 450,
        baseline: baseline,
        previousRaw: baseline,
      );
      expect(sample.rebase, isFalse);
      expect(sample.delta, 450);
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: baseline + 450,
          healthBase: 0,
          sessionDelta: sample.delta,
          stepOffset: 0,
        ),
        450,
      );
    });

    test(
        'single 20000 jump from zero is a dump; the same total walked gradually is not',
        () {
      final dump = PedometerStepTruth.acceptSensorDelta(
        raw: 20000,
        baseline: 0,
        previousRaw: 0,
      );
      expect(dump.rebase, isTrue);
      expect(dump.delta, 0);
      final walked = PedometerStepTruth.acceptSensorDelta(
        raw: 20000,
        baseline: 0,
        previousRaw: 19500,
      );
      expect(walked.rebase, isFalse);
      expect(walked.delta, 20000);
    });

    test('gradual walk from a zero baseline is not a since-boot dump', () {
      final sample = PedometerStepTruth.acceptSensorDelta(
        raw: 450,
        baseline: 0,
        previousRaw: 400,
      );
      expect(sample.rebase, isFalse);
      expect(sample.delta, 450);
    });

    test('after a dump rebase, the next small delta is today', () {
      final dump = PedometerStepTruth.acceptSensorDelta(
        raw: 86626,
        baseline: 0,
        previousRaw: 0,
      );
      expect(dump.rebase, isTrue);
      const rebased = 86626;
      final walked = PedometerStepTruth.acceptSensorDelta(
        raw: rebased + 450,
        baseline: rebased,
        previousRaw: rebased,
      );
      expect(walked.rebase, isFalse);
      expect(walked.delta, 450);
    });

    test('overflow sentinel session does not become today steps', () {
      expect(
        PedometerStepTruth.fromSensorEvent(
          raw: 999999,
          healthBase: 999999,
          sessionDelta: 5,
          stepOffset: 0,
        ),
        0,
      );
    });
  });

  group('PedometerStepTruth.dailyFromSources', () {
    test('never subtracts sensor offset from already-daily counters', () {
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 1835,
          persistedToday: 1835,
        ),
        1835,
      );
    });

    test('Health 1834 + isolate 0 still keeps walking-screen 1835', () {
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 1834,
          persistedToday: 1835,
          isolateDaily: 0,
        ),
        1835,
      );
    });

    test('hydrates notification from persisted walking-screen steps', () {
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 0,
          persistedToday: 1835,
          isolateDaily: 0,
        ),
        1835,
      );
    });

    test('live isolate wins when it is ahead of prefs', () {
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 2100,
          persistedToday: 1835,
        ),
        2100,
      );
    });

    test(
        'poisoned 86626 loses to a sane live day; real totals still max upward',
        () {
      expect(PedometerStepTruth.clampDaily(86626), 0);
      expect(PedometerStepTruth.clampDaily(30001), 0);
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 450,
          persistedToday: 86626,
          isolateDaily: 86626,
        ),
        450,
      );
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 86626,
          persistedToday: 450,
        ),
        450,
      );
      // Same-day legitimate walk still only moves upward.
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 2100,
          persistedToday: 1835,
        ),
        2100,
      );
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 100,
          persistedToday: 1835,
        ),
        1835,
      );
      // Under the ceiling, a higher same-day total is not poison.
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 450,
          persistedToday: 20000,
        ),
        20000,
      );
    });

    test('999999 overflow stub cannot wipe a real persisted day', () {
      expect(PedometerStepTruth.clampDaily(999999), 0);
      expect(PedometerStepTruth.clampDaily(100001), 0);
      expect(
        PedometerStepTruth.clampDaily(PedometerStepTruth.plausibleDailyMax),
        PedometerStepTruth.plausibleDailyMax,
      );
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 999999,
          persistedToday: 1835,
        ),
        1835,
      );
      expect(
        PedometerStepTruth.dailyFromSources(
          liveDaily: 999999,
          persistedToday: 999999,
        ),
        0,
      );
    });
  });

  group('PedometerStepTruth.shouldRebindSensor', () {
    final t0 = DateTime.utc(2026, 9, 11, 12);
    test('resume/init force a rebind even inside the cooldown', () {
      expect(
        PedometerStepTruth.shouldRebindSensor(
          now: t0.add(const Duration(milliseconds: 200)),
          lastRebindAt: t0,
          force: true,
        ),
        isTrue,
      );
    });

    test('stream-error honors a 2s cooldown after FlutterJNI detach flaps', () {
      expect(
        PedometerStepTruth.shouldRebindSensor(
          now: t0.add(const Duration(milliseconds: 500)),
          lastRebindAt: t0,
          force: false,
        ),
        isFalse,
      );
      expect(
        PedometerStepTruth.shouldRebindSensor(
          now: t0.add(const Duration(seconds: 2)),
          lastRebindAt: t0,
          force: false,
        ),
        isTrue,
      );
    });
  });

  group('WalkingChallengeNotificationCopy', () {
    test('0 daily steps uses the waiting / 4,500 copy with matching count', () {
      final copy = WalkingChallengeNotificationCopy.fromDailySteps(0);
      expect(copy.title, contains('셰어런 챌린지 대기 중'));
      expect(copy.body, contains('0 / 4,500보'));
    });

    test('1,835 daily steps stays on the same 4,500 track (not 0)', () {
      final copy = WalkingChallengeNotificationCopy.fromDailySteps(1835);
      expect(copy.title, contains('숲길 걷는 중'));
      expect(copy.body, contains('1,835보'));
      expect(copy.body, isNot(contains('(0 /')));
    });

    test('4,500 daily steps switches to finish copy', () {
      final copy = WalkingChallengeNotificationCopy.fromDailySteps(4500);
      expect(copy.title, contains('챌린지 완주 성공'));
      expect(copy.body, contains('4,500/10,000보'));
    });

    test('since-boot 86,626 does not print in the shade', () {
      final copy = WalkingChallengeNotificationCopy.fromDailySteps(86626);
      expect(copy.body, isNot(contains('86,626')));
      expect(copy.body, contains('0 / 4,500보'));
    });

    test('overflow sentinel does not print 999,999 in the shade', () {
      final copy = WalkingChallengeNotificationCopy.fromDailySteps(999999);
      expect(copy.body, isNot(contains('999,999')));
      expect(copy.body, contains('0 / 4,500보'));
    });
  });
}
