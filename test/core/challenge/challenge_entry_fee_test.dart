import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/challenge/challenge_entry_fee.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';

void main() {
  test('1km beginner is cheaper than 3km intermediate', () {
    expect(ChallengeEntryFee.forDistanceKm(1), 600);
    expect(ChallengeEntryFee.forDistanceKm(3), 1200);
    expect(ChallengeEntryFee.forDistanceKm(5), 1800);
    expect(ChallengeEntryFee.forDistanceKm(10), 3000);
    expect(ChallengeEntryFee.forDistanceKm(15), 3600);
    expect(ChallengeEntryFee.forDistanceKm(20), 4200);
    expect(ChallengeEntryFee.beginner1kmShare, 600);
    expect(ChallengeEntryFee.intermediate3kmShare, 1200);
    expect(
      ChallengeEntryFee.forDistanceKm(1) < ChallengeEntryFee.forDistanceKm(3),
      isTrue,
    );
  });

  test('fee labels match Home and challenge-detail copy', () {
    expect(
      ChallengeEntryFee.labelShare(600),
      AppStrings.dashboardChallenge1Sub,
    );
    expect(
      ChallengeEntryFee.labelShare(1200),
      AppStrings.challengeDetailEntryFee,
    );
    expect(AppStrings.dashboardChallenge2Sub, '참가비: 1,200 SHARE');
    expect(AppStrings.lobbyRoom3Sub, contains('600 SHARE'));
    expect(AppStrings.dashboardChallenge1Sub, isNot(contains('10만')));
  });
}
