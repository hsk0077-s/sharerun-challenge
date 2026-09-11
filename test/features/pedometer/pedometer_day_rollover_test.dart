import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/pedometer_day_rollover.dart';
import 'package:share_run_challenge/features/pedometer/pedometer_harvest_ledger.dart';

void main() {
  test('needsRollover when lastSavedDate is a previous KST day', () {
    expect(
      PedometerDayRollover.needsRollover(
        lastSavedDate: '2026-09-10',
        todayKey: '2026-09-11',
      ),
      isTrue,
    );
    expect(
      PedometerDayRollover.needsRollover(
        lastSavedDate: '2026-09-11',
        todayKey: '2026-09-11',
      ),
      isFalse,
    );
  });

  test('empty lastSavedDate is not evaluable so yesterday cannot be skipped', () {
    expect(PedometerDayRollover.canEvaluate(''), isFalse);
    expect(
      PedometerDayRollover.needsRollover(
        lastSavedDate: '',
        todayKey: '2026-09-11',
      ),
      isFalse,
    );
  });

  test('rollover plan zeros day-scoped counters and keeps sensor as offset', () {
    final plan = PedometerDayRollover.plan(
      todayKey: '2026-09-11',
      sensorTotal: 18420,
    );
    expect(plan.dateKey, '2026-09-11');
    expect(plan.steps, 0);
    expect(plan.km, 0);
    expect(plan.claimedSteps, 0);
    expect(plan.collectedShare, 0);
    expect(plan.milestone1, isFalse);
    expect(plan.milestone2, isFalse);
    expect(plan.milestone3, isFalse);
    expect(plan.bonus, isFalse);
    expect(plan.stepOffset, 18420);
  });

  test('claimedAfterHydrate drops yesterday watermark after rollover', () {
    expect(
      PedometerDayRollover.claimedAfterHydrate(
        rolledOver: true,
        coalescedClaimed: 2918,
      ),
      0,
    );
    expect(
      PedometerDayRollover.claimedAfterHydrate(
        rolledOver: false,
        coalescedClaimed: 2918,
      ),
      2918,
    );
  });

  test('prefs write clears claimed keys for the new KST day', () {
    final plan = PedometerDayRollover.plan(
      todayKey: '2026-09-11',
      sensorTotal: 100,
    );
    final prefs = PedometerDayRollover.prefsToWrite(plan);
    expect(prefs[PedometerDayRollover.lastSavedDateKey], '2026-09-11');
    expect(prefs[PedometerHarvestLedger.todayClaimedKey('2026-09-11')], 0);
    expect(prefs[PedometerHarvestLedger.globalClaimedKey], 0);
    expect(prefs[PedometerHarvestLedger.globalClaimedDateKey], '2026-09-11');
    expect(prefs[PedometerDayRollover.collectedShareCoinsKey], 0.0);
  });

  test('wallet inventory donation keys persist across midnight', () {
    expect(PedometerDayRollover.persistsAcrossMidnight('SHARE'), isTrue);
    expect(PedometerDayRollover.persistsAcrossMidnight('DIA'), isTrue);
    expect(PedometerDayRollover.persistsAcrossMidnight('VALUE'), isTrue);
    expect(PedometerDayRollover.persistsAcrossMidnight('item_inventory'), isTrue);
    expect(
      PedometerDayRollover.persistsAcrossMidnight('donation_history'),
      isTrue,
    );
    expect(
      PedometerDayRollover.persistsAcrossMidnight('2026-09-10_claimed_steps'),
      isFalse,
    );
  });
}
