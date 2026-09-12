import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/constants/firestore_paths.dart';

void main() {
  test('userWalletTransactions nests under the signed-in user document', () {
    expect(
      FirestorePaths.userWalletTransactions('uid-1'),
      'users/uid-1/wallet_transactions',
    );
  });

  test('userNotifications nests under the signed-in user document', () {
    expect(
      FirestorePaths.userNotifications('uid-1'),
      'users/uid-1/notifications',
    );
  });

  test('stamp-tour catalog paths are config + collection, not user docs', () {
    expect(FirestorePaths.stampTourConfig, 'config/stamp_tour');
    expect(FirestorePaths.stampLandmarks, 'stampLandmarks');
  });
}
