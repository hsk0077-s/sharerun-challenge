import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/account_daily_steps_provider.dart';

void main() {
  test('a daily_metrics row becomes one account day', () {
    final row = AccountDailySteps.dayOf('2026-10-03', const {
      'steps': 2000,
      'km': 1.5,
    });
    expect(row?.steps, 2000);
    expect(row?.km, 1.5);
    expect(AccountDailySteps.dayOf('not-a-day', const {'steps': 10}), isNull);
    expect(AccountDailySteps.dayOf('2026-10-03', const {'steps': 0}), isNull);
    final covered = AccountDailySteps.dayOf('2026-10-03', const {
      'steps': 0,
      'streakCovered': 'cpr',
    });
    expect(covered?.streakCovered, isTrue);
    expect(covered?.steps, 0);
    expect(covered?.km, 0);
  });

  test('today display is the server document steps', () {
    expect(AccountDailySteps.stepsOf(const {'steps': 4321}), 4321);
    expect(AccountDailySteps.stepsOf(null), 0);
    expect(AccountDailySteps.stepsOf(const {'steps': 0}), 0);
    expect(AccountDailySteps.stepsOf(const {'steps': 999999}), 0);
  });
}
