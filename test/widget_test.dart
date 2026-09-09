import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/constants/payment_constants.dart';

void main() {
  test('payment amount policy is defined for CI smoke', () {
    expect(PaymentConstants.shareTopUpAmountKrw, 10000);
  });
}
