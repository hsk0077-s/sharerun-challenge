import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/user_model.dart';

void main() {
  test('fromJson restores wallet nested map and inventory flags', () {
    final profile = UserModel.fromJson({
      'uid': 'u1',
      'hasCPR': true,
      'hasSafeGuard': true,
      'isSponsored': true,
      'wallet': {
        'shareBalance': 10,
        'diamondBalance': 20,
        'valueTokenBalance': 30,
        'totalDonationValue': 0,
      },
    });

    expect(profile.uid, 'u1');
    expect(profile.hasCPR, isTrue);
    expect(profile.hasSafeGuard, isTrue);
    expect(profile.isSponsored, isTrue);
    expect(profile.shareBalance, 10);
    expect(profile.diamondBalance, 20);
    expect(profile.valueBalance, 30);
  });

  test('fromJson falls back to top-level diamondBalance', () {
    final profile = UserModel.fromJson({
      'uid': 'u2',
      'diamondBalance': 100,
      'hasCPR': false,
    });

    expect(profile.hasCPR, isFalse);
    expect(profile.isSponsored, isFalse);
    expect(profile.diamondBalance, 100);
  });

  test('copyWith updates hasCPR and isSponsored', () {
    final base = UserModel.dashboardDefault(uid: 'u3');
    final next = base.copyWith(
      hasCPR: true,
      hasSafeGuard: true,
      isSponsored: true,
    );
    expect(next.hasCPR, isTrue);
    expect(next.hasSafeGuard, isTrue);
    expect(next.isSponsored, isTrue);
    expect(base.hasCPR, isFalse);
    expect(base.hasSafeGuard, isFalse);
  });
}
