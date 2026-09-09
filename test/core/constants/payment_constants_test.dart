import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/core/constants/payment_constants.dart';

void main() {
  setUpAll(() async {
    await AppEnv.load();
  });

  test('pgBaseUrl defaults to demo host', () {
    expect(PaymentConstants.pgBaseUrl, 'https://pg.example.com');
  });

  test('share and sponsor paths stay stable', () {
    expect(PaymentConstants.shareTopUpPath, '/share-top-up');
    expect(PaymentConstants.sponsorPath, '/sponsor');
  });

  test('amount policy matches Firestore rules', () {
    expect(PaymentConstants.shareTopUpAmountKrw, 10000);
    expect(PaymentConstants.sponsorAmountOptionsShare, [1000, 3000, 5000]);
  });
}
