import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/pedometer_harvest_ledger.dart';

void main() {
  test('pending floor is 1 SHARE per 100 unclaimed steps', () {
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2918, claimedSteps: 0),
      29,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 2918, claimedSteps: 2918),
      0,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 3000, claimedSteps: 2918),
      0,
    );
    expect(
      PedometerHarvestLedger.pendingShareFloor(steps: 3018, claimedSteps: 2918),
      1,
    );
  });

  test('re-enter does not revive the same floor amount after a successful claim',
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
}
