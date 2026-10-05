import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/constants/economy_constants.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';

void main() {
  test('effort VALUE matches the server 10 per km truncation', () {
    expect(EconomyConstants.srvTokensPerKm, 10);
    expect(EconomyConstants.effortValueTokens(1), 10);
    expect(EconomyConstants.effortValueTokens(3), 30);
    expect(EconomyConstants.effortValueTokens(1.9), 19);
    expect(EconomyConstants.effortValueTokens(0), 0);
    expect(
      AppStrings.liveRunningEffortTip(EconomyConstants.effortValueTokens(1)),
      '순수 노력 목표: 완주 시 밸류 토큰 +10',
    );
    expect(
      AppStrings.liveRunningEffortTip(EconomyConstants.effortValueTokens(3)),
      '순수 노력 목표: 완주 시 밸류 토큰 +30',
    );
  });
}
