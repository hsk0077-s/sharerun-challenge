import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/challenge/challenge_entry_fee.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';

void main() {
  test('1km beginner is cheaper than 3km intermediate', () {
    expect(ChallengeEntryFee.forDistanceKm(1), 30000);
    expect(ChallengeEntryFee.forDistanceKm(3), 60000);
    expect(ChallengeEntryFee.beginner1kmShare, 30000);
    expect(ChallengeEntryFee.intermediate3kmShare, 60000);
    expect(
      ChallengeEntryFee.forDistanceKm(1) < ChallengeEntryFee.forDistanceKm(3),
      isTrue,
    );
  });

  test('fee labels match Home and challenge-detail copy', () {
    expect(
      ChallengeEntryFee.labelShare(30000),
      AppStrings.dashboardChallenge1Sub,
    );
    expect(
      ChallengeEntryFee.labelShare(60000),
      AppStrings.challengeDetailEntryFee,
    );
    expect(AppStrings.dashboardChallenge2Sub, '참가비: 60,000 SHARE');
    expect(AppStrings.lobbyRoom3Sub, contains('30,000 SHARE'));
    expect(AppStrings.dashboardChallenge1Sub, isNot(contains('10만')));
  });
}
