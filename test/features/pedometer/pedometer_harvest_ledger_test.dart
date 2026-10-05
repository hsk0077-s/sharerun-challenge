import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/pedometer_harvest_ledger.dart';

void main() {
  test('pending floor is 10 SHARE per 100 unclaimed steps', () {
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2918, claimedSteps: 0),
      291,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2918, claimedSteps: 2918),
      0,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2927, claimedSteps: 2918),
      0,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2928, claimedSteps: 2918),
      1,
    );
  });

  test(
      're-enter does not revive the same floor amount after a successful claim',
      () {
    const steps = 2918;
    const claimed = 2918;
    expect(
      PedometerHarvestLedger.pendingShareFloor(
        steps: steps,
        claimedSteps: claimed,
      ),
      0,
    );
  });

  test('coalesceClaimed keeps todayKey watermark when prefix uid is empty', () {
    expect(
      PedometerHarvestLedger.coalesceClaimed(
        current: 0,
        fromTodayKey: 2918,
        fromPrefix: 0,
        steps: 2918,
      ),
      2918,
    );
  });

  test('coalesceClaimed does not clamp watermark to 0 while steps are loading',
      () {
    expect(
      PedometerHarvestLedger.coalesceClaimed(
        current: 0,
        fromTodayKey: 2918,
        fromPrefix: 0,
        steps: 0,
      ),
      2918,
    );
  });

  test('later restore cannot lower an already restored watermark', () {
    expect(
      PedometerHarvestLedger.coalesceClaimed(
        current: 2918,
        fromTodayKey: 0,
        fromPrefix: 0,
        steps: 2918,
      ),
      2918,
    );
  });

  test('2950 steps with claimed 0 is 295 pending and 295 floor', () {
    expect(
      PedometerHarvestLedger.pendingShareExact(steps: 2950, claimedSteps: 0),
      295,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2950, claimedSteps: 0),
      295,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2950, claimedSteps: 2950),
      0,
    );
  });

  test('displayed mined SHARE is the server field for today only', () {
    expect(
      PedometerHarvestLedger.displayHarvestedShare(
        dateKey: '2026-10-03',
        harvestedShare: 50,
        todayKey: '2026-10-03',
      ),
      50,
    );
    expect(
      PedometerHarvestLedger.displayHarvestedShare(
        dateKey: '2026-10-02',
        harvestedShare: 50,
        todayKey: '2026-10-03',
      ),
      0,
    );
    expect(
      PedometerHarvestLedger.displayHarvestedShare(
        dateKey: '2026-10-03',
        harvestedShare: 999,
        todayKey: '2026-10-03',
      ),
      600,
    );
  });

  test('today mined and pending never exceed the daily 600 SHARE cap', () {
    expect(
      PedometerHarvestLedger.todayMinedShare(claimedSteps: 999999),
      PedometerHarvestLedger.dailyShareCap,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(
        steps: 999999,
        claimedSteps: 0,
      ),
      PedometerHarvestLedger.dailyShareCap,
    );
    expect(
      PedometerHarvestLedger.pendingShareExact(
        steps: 999999,
        claimedSteps: 0,
      ),
      PedometerHarvestLedger.dailyShareCap.toDouble(),
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(
        steps: 999999,
        claimedSteps: 5000,
      ),
      100,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(
        steps: 999999,
        claimedSteps: 6000,
      ),
      0,
    );
    expect(
      PedometerHarvestLedger.claimedAfterHarvest(
        steps: 999999,
        claimedSteps: 0,
      ),
      PedometerHarvestLedger.stepsForDailyCap,
    );
    expect(
      PedometerHarvestLedger.claimedAfterHarvest(
        steps: 4500,
        claimedSteps: 0,
      ),
      4500,
    );
    expect(
      PedometerHarvestLedger.claimedAfterHarvest(
        steps: 6200,
        claimedSteps: 5500,
      ),
      PedometerHarvestLedger.stepsForDailyCap,
    );
  });

  test('coalesceClaimed drops an overflow claimed watermark to the daily cap',
      () {
    expect(
      PedometerHarvestLedger.coalesceClaimed(
        current: 999999,
        fromTodayKey: 999999,
        fromPrefix: 0,
        steps: 999999,
      ),
      PedometerHarvestLedger.stepsForDailyCap,
    );
  });

  test('global same-day claimed survives empty uid prefix', () {
    expect(
      PedometerHarvestLedger.claimedFromGlobal(
        storedDate: '2026-09-11',
        storedClaimed: 2950,
        todayKey: '2026-09-11',
      ),
      2950,
    );
    expect(
      PedometerHarvestLedger.claimedFromGlobal(
        storedDate: '2026-09-10',
        storedClaimed: 2950,
        todayKey: '2026-09-11',
      ),
      0,
    );
    expect(
      PedometerHarvestLedger.coalesceClaimed(
        current: 0,
        fromTodayKey: 0,
        fromPrefix: 0,
        fromGlobal: 2950,
        steps: 2950,
      ),
      2950,
    );
  });

  test('session watermark survives a remount that reads claimed 0', () {
    const today = '2026-09-26';
    const yesterday = '2026-09-25';
    PedometerHarvestLedger.commitSession(dateKey: yesterday, claimed: 1800);
    expect(PedometerHarvestLedger.sessionClaimed(today), 0);

    PedometerHarvestLedger.commitSession(dateKey: today, claimed: 2900);
    expect(PedometerHarvestLedger.sessionClaimed(yesterday), 0);
    expect(
      PedometerHarvestLedger.coalesceClaimed(
        current: 0,
        fromTodayKey: 0,
        fromPrefix: 0,
        fromSession: PedometerHarvestLedger.sessionClaimed(today),
        steps: 2950,
      ),
      2900,
    );

    const steps = 2950;
    final claimed = PedometerHarvestLedger.claimedAfterHarvest(
      steps: steps,
      claimedSteps: 0,
    );
    expect(claimed, 2950);
    expect(steps > claimed, isFalse);
    expect(
      PedometerHarvestLedger.pickupReady(
        steps: steps,
        claimedSteps: claimed,
      ),
      isFalse,
    );

    PedometerHarvestLedger.commitSession(dateKey: today, claimed: 0);
    expect(PedometerHarvestLedger.sessionClaimed(today), 0);
  });
}
