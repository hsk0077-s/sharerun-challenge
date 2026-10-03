import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/account_daily_steps_provider.dart';

void main() {
  test('today display is the server document steps', () {
    expect(AccountDailySteps.stepsOf(const {'steps': 4321}), 4321);
    expect(AccountDailySteps.stepsOf(null), 0);
    expect(AccountDailySteps.stepsOf(const {'steps': 0}), 0);
    expect(AccountDailySteps.stepsOf(const {'steps': 999999}), 0);
  });
}
