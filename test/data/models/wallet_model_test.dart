import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';

void main() {
  test('fromJson reads nested Firestore-style maps that are not Map<String,dynamic>',
      () {
    final raw = <dynamic, dynamic>{
      'shareBalance': 12,
      'diamondBalance': '8',
      'valueTokenBalance': 3,
      'totalDonationValue': 0,
    };
    final wallet = WalletModel.fromJson(Map<String, dynamic>.from(raw));
    expect(wallet.shareBalance, 12);
    expect(wallet.diamondBalance, 8);
    expect(wallet.valueTokenBalance, 3);
  });

  test('fromJson returns zeros for missing wallet', () {
    final wallet = WalletModel.fromJson(null);
    expect(wallet.shareBalance, 0);
    expect(wallet.diamondBalance, 0);
    expect(wallet.valueTokenBalance, 0);
  });
}
