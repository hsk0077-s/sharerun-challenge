import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/challenge/challenge_entry_fee.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';

void main() {
  test('1km beginner is cheaper than 3km intermediate', () {
    expect(ChallengeEntryFee.forDistanceKm(1), 300000);
    expect(ChallengeEntryFee.forDistanceKm(3), 600000);
    expect(ChallengeEntryFee.beginner1kmShare, 300000);
    expect(ChallengeEntryFee.intermediate3kmShare, 600000);
    expect(
      ChallengeEntryFee.forDistanceKm(1) < ChallengeEntryFee.forDistanceKm(3),
      isTrue,
    );
  });

  test('fee labels match Home and challenge-detail copy', () {
    expect(
      ChallengeEntryFee.labelShare(300000),
      AppStrings.dashboardChallenge1Sub,
    );
    expect(
      ChallengeEntryFee.labelShare(600000),
      AppStrings.challengeDetailEntryFee,
    );
    expect(AppStrings.dashboardChallenge2Sub, '참가비: 600,000 SHARE');
    expect(AppStrings.lobbyRoom3Sub, contains('300,000 SHARE'));
    expect(AppStrings.dashboardChallenge1Sub, isNot(contains('10만')));
  });
}
