import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/solo_pedometer_foreground.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'resolveNotification keeps 1,835 when midnight offset equals daily steps',
      () async {
    SharedPreferences.setMockInitialValues({
      '2026-09-11_step_offset': 1835,
      'stepOffset': 1835,
      '2026-09-11_steps': 1835,
      '2026-09-11_claimed_steps': 0,
    });

    final resolved =
        await SoloPedometerForeground.resolveNotification(rawSteps: 1835);

    expect(resolved.effectiveSteps, 1835);
    expect(resolved.body, contains('1,835보'));
    expect(resolved.body, isNot(contains('(0 /')));
    expect(resolved.title, isNot(contains('대기 중')));
  });

  test('resolveNotification hydrates 0 live from walking-screen prefs',
      () async {
    final today = DateTime.now().toUtc().add(const Duration(hours: 9));
    final m = today.month.toString().padLeft(2, '0');
    final d = today.day.toString().padLeft(2, '0');
    final todayKey = '${today.year}-$m-$d';

    SharedPreferences.setMockInitialValues({
      '${todayKey}_step_offset': 50000,
      'stepOffset': 50000,
      '${todayKey}_steps': 1835,
      '${todayKey}_claimed_steps': 0,
    });

    final resolved =
        await SoloPedometerForeground.resolveNotification(rawSteps: 0);

    expect(resolved.effectiveSteps, 1835);
    expect(resolved.body, contains('1,835보'));
  });

  test(
      'resolveNotification does not prefer poisoned 86626 over a sane live daily',
      () async {
    final today = DateTime.now().toUtc().add(const Duration(hours: 9));
    final m = today.month.toString().padLeft(2, '0');
    final d = today.day.toString().padLeft(2, '0');
    final todayKey = '${today.year}-$m-$d';

    SharedPreferences.setMockInitialValues({
      '${todayKey}_steps': 86626,
      '${todayKey}_claimed_steps': 0,
    });

    final resolved =
        await SoloPedometerForeground.resolveNotification(rawSteps: 450);

    expect(resolved.effectiveSteps, 450);
    expect(resolved.body, contains('450'));
    expect(resolved.body, isNot(contains('86,626')));
  });

  test(
      'resolveNotification health 4706 replaces prefs 29999; no health keeps it',
      () async {
    final today = DateTime.now().toUtc().add(const Duration(hours: 9));
    final m = today.month.toString().padLeft(2, '0');
    final d = today.day.toString().padLeft(2, '0');
    final todayKey = '${today.year}-$m-$d';
    SharedPreferences.setMockInitialValues({
      '${todayKey}_steps': 29999,
      '${todayKey}_claimed_steps': 0,
    });

    final capped = await SoloPedometerForeground.resolveNotification(
      rawSteps: 29999,
      healthToday: 4706,
    );
    expect(capped.effectiveSteps, 4706);
    expect(
      capped.effectiveSteps,
      lessThanOrEqualTo(4706 + 2000),
    );
    expect(capped.body, contains('4,706'));

    final kept = await SoloPedometerForeground.resolveNotification(
      rawSteps: 29999,
    );
    expect(kept.effectiveSteps, 29999);
    expect(kept.body, contains('29,999'));
  });

  test('plain step update after heal still carries positive Health', () {
    SoloPedometerForeground.debugResetKnownHealth();
    expect(SoloPedometerForeground.debugTaskPayload(29999, null), 29999);
    expect(
      SoloPedometerForeground.debugTaskPayload(4706, 4706),
      <Object>[4706, 4706],
    );
    expect(
      SoloPedometerForeground.debugTaskPayload(29999, null),
      <Object>[29999, 4706],
    );
    expect(
      SoloPedometerForeground.debugTaskPayload(29999, 0),
      <Object>[29999, 4706],
    );
    SoloPedometerForeground.debugResetKnownHealth();
  });

  test('isolate commit after heal does not re-raise to 29999', () {
    final healed = SoloPedometerForegroundHandler();
    expect(
      healed.debugMergeCommit(
        computed: 4706,
        saved: 29999,
        healthToday: 4706,
      ),
      4706,
    );
    expect(
      healed.debugMergeCommit(computed: 29999, saved: 29999),
      4706,
    );
    expect(
      healed.debugMergeCommit(computed: 29999, saved: 29999, healthToday: 0),
      4706,
    );

    final plain = SoloPedometerForegroundHandler();
    expect(
      plain.debugMergeCommit(computed: 29999, saved: 29999),
      29999,
    );
    expect(
      plain.debugMergeCommit(computed: 100, saved: 29999, healthToday: 0),
      29999,
    );
  });
}
