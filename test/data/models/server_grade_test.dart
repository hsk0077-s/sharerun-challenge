import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';

void main() {
  test('grade comes only from the server doc', () {
    final graded = UserModel.fromJson({
      'uid': 'u1',
      'gradeRank': 12,
      'economy': {
        'gradeRuns': [
          {'day': '2026-10-06'},
          {'day': '2026-10-07'},
          {'day': '2026-10-08'},
        ],
      },
    });
    expect(graded.gradeRank, 12);
    expect(graded.economy.gradeRunCount, 3);
    expect(UserTier.tryFromRankScore(graded.gradeRank)?.firestoreCode,
        'wolf_silver');

    final fresh = UserModel.fromJson({'uid': 'u2', 'tier': 25});
    expect(fresh.gradeRank, 0);
    expect(fresh.economy.gradeRunCount, 0);
    expect(UserTier.tryFromRankScore(fresh.gradeRank), isNull);
  });

  test('copyWith keeps the server grade', () {
    final user = UserModel.fromJson({'uid': 'u1', 'gradeRank': 7});
    expect(user.copyWith(nickname: '달림이').gradeRank, 7);
  });
}
