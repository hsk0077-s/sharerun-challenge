import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/walking_step_keepalive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fixed baseline then three +100 batches is 300, not 600', () {
    final keep = WalkingStepKeepAlive(onDaily: (steps, km) async {});
    keep.debugAnchorToday();
    keep.debugIngestRaw(5000);
    expect(keep.debugFloor, 0);
    keep.debugIngestRaw(5100);
    expect(keep.debugFloor, 100);
    keep.debugIngestRaw(5200);
    expect(keep.debugFloor, 200);
    keep.debugIngestRaw(5300);
    expect(keep.debugFloor, 300);
  });

  test('Health 4706 replaces a stored 29655 floor and null health does not',
      () async {
    final reported = <int>[];
    final keep = WalkingStepKeepAlive(onDaily: (steps, _) async {
      reported.add(steps);
    });
    keep.debugSeedFloor(29655);
    await keep.debugPublishHealth(
      healthToday: 4706,
      persisted: 29655,
      isolate: 29655,
    );
    expect(keep.debugFloor, 4706);
    expect(reported, [4706]);

    keep.debugSeedFloor(29655);
    reported.clear();
    await keep.debugPublishHealth(
      healthToday: null,
      persisted: 29655,
      isolate: 4706,
    );
    expect(keep.debugFloor, 29655);
    expect(reported, isEmpty);
  });

  test('sensor publish after Health 4706 does not re-raise 29999', () async {
    final reported = <int>[];
    final keep = WalkingStepKeepAlive(onDaily: (steps, _) async {
      reported.add(steps);
    });
    keep.debugSeedFloor(29999);
    await keep.debugPublishHealth(
      healthToday: 4706,
      persisted: 29999,
      isolate: 29999,
    );
    expect(keep.debugFloor, 4706);
    reported.clear();
    keep.debugSeedFloor(29999);
    await keep.debugPublishSensor(29999);
    expect(keep.debugFloor, 4706);
    expect(reported, [4706]);
  });

  test('sensor publish without health keeps a stored 29999', () async {
    final keep = WalkingStepKeepAlive(onDaily: (steps, km) async {});
    keep.debugSeedFloor(29999);
    await keep.debugPublishSensor(100);
    expect(keep.debugFloor, 29999);
  });
}
