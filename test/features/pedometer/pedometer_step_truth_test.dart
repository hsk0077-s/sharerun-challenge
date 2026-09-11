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
  });
}
