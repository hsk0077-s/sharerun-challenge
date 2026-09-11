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

  test('resolveNotification hydrates 0 live from walking-screen prefs', () async {
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
}
