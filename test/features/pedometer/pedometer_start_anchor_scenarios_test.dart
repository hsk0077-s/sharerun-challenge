import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/today_steps.dart';

/// Prepares the decision on the iOS `pedometer` change (start the CMPedometer
/// query at today 0:00 instead of the last reboot). See docs/ios-privacy-manifest.md §7.
///
/// These run the app's own step logic on synthetic raw sequences. They show how the
/// app reacts to the two raw-value semantics. They do NOT show what CMPedometer
/// delivers; that needs a device (docs/ios-device-test-plan.md, pedometer rows).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TodaySteps fresh({String Function()? day}) {
    final today = TodaySteps();
    if (day != null) today.debugTodayKey = day;
    today.debugAnchorToday();
    return today;
  }

  int total(List<int> raws) {
    final today = fresh();
    raws.forEach(today.onRaw);
    return today.steps;
  }

  test('a constant shift of the raw values (reboot anchor vs 0:00 anchor) gives the same steps', () {
    const walk = [0, 40, 95, 160, 300, 420];
    final bootAnchored = walk.map((v) => v + 52000).toList();
    final midnightAnchored = walk.map((v) => v + 1800).toList();
    expect(total(bootAnchored), total(midnightAnchored));
    expect(total(bootAnchored), 420);
  });

  test('first event is the baseline: steps before the first callback are not counted', () {
    // Same under both anchors as long as the first callback already carries the
    // cumulative value. If the 0:00 query only fires after the first new step,
    // the baseline would be that later value (device check needed).
    expect(total([1000, 1010]), 10);
    expect(total([1005, 1010]), 5);
  });

  test('resubscribing within the same anchor continues without double counting', () {
    final today = fresh();
    for (final raw in [1000, 1050, 1100]) {
      today.onRaw(raw);
    }
    // a re-listen delivers the cumulative value again, then more steps
    for (final raw in [1100, 1100, 1130]) {
      today.onRaw(raw);
    }
    expect(today.steps, 130);
  });

  test('app restart: a new object starts from its first event and never exceeds the health cap', () {
    final restarted = fresh();
    restarted.restore(130, health: 130);
    restarted.onRaw(5000);
    restarted.onRaw(5020);
    expect(restarted.steps, lessThanOrEqualTo(130 + 20 + 50));
    expect(restarted.steps, greaterThanOrEqualTo(130));
  });

  test('midnight with a live stream: the new day starts from the first event after midnight', () {
    var day = '2026-11-08';
    final today = fresh(day: () => day);
    for (final raw in [2000, 2100, 2200]) {
      today.onRaw(raw);
    }
    expect(today.steps, 200);
    day = '2026-11-09';
    today.onRaw(2250);
    expect(today.steps, 0);
    today.onRaw(2300);
    expect(today.steps, 50);
  });

  test('KNOWN HAZARD for the 0:00 anchor: a stream that crossed midnight, then a re-listen with smaller raw values, stalls', () {
    // Old stream anchored at yesterday 0:00 keeps counting (raw ~20000). After midnight the
    // app re-listens; the new query is anchored at today 0:00 (raw restarts near 0).
    // TodaySteps ignores raw < previousRaw, so steps stay frozen until raw catches up.
    // Under the reboot anchor raw never drops, so this does not occur (except at a reboot).
    // If the 0:00 anchor is adopted, today_steps.dart needs a decrease -> rebase rule
    // and a test; this test pins the current behaviour so the change is deliberate.
    var day = '2026-11-08';
    final today = fresh(day: () => day);
    for (final raw in [20000, 20100]) {
      today.onRaw(raw);
    }
    day = '2026-11-09';
    today.onRaw(20150); // first event of the new day = baseline
    expect(today.steps, 0);
    for (final raw in [30, 80, 140]) {
      today.onRaw(raw); // new subscription, smaller raw values
    }
    expect(today.steps, 0, reason: 'frozen: decrease is ignored, not rebased');
  });
}
