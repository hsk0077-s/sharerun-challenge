import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/today_steps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int totalFor(List<int> raws) {
    final today = TodaySteps();
    today.debugAnchorToday();
    for (final raw in raws) {
      today.onRaw(raw);
    }
    return today.steps;
  }

  test('three sources in any order produce one total', () {
    const expected = 300;
    expect(totalFor([5000, 5100, 5200, 5300]), expected);
    expect(
      totalFor([5000, 5000, 5000, 5100, 5200, 5100, 5300, 5200]),
      expected,
    );
    expect(totalFor([5000, 5300, 5200, 5100]), expected);
  });

  test('isolate restart with stale prefs does not raise above the health cap',
      () {
    final restarted = TodaySteps();
    restarted.debugAnchorToday();
    restarted.restore(29999, health: 4706);
    expect(restarted.steps, lessThanOrEqualTo(6706));
    expect(restarted.steps, isNot(29999));

    restarted.onRaw(8000);
    restarted.onRaw(8100);
    expect(restarted.steps, lessThanOrEqualTo(6706));
  });

  test('onHealth raises 1503 to the Health Connect total 4696', () async {
    final today = TodaySteps();
    today.debugAnchorToday();
    today.debugSeed(1503);
    await today.onHealth(4696);
    expect(today.steps, 4696);
    expect(today.health, 4696);
  });

  test('midnight rollover clears today and yesterday health cap', () {
    var day = '2026-10-02';
    final today = TodaySteps();
    today.debugTodayKey = () => day;
    today.debugAnchorToday();
    today.debugSeed(3931);
    today.restore(3931, health: 4706);
    expect(today.health, 4706);

    day = '2026-10-03';
    today.onRaw(9000);
    expect(today.steps, 0);
    expect(today.health, isNull);

    today.onRaw(9100);
    expect(today.steps, 100);
    today.restore(29999, health: null);
    expect(today.steps, 100);
  });
}
