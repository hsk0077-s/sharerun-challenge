import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/payment_intent_status_model.dart';

void main() {
  group('PaymentIntentStatusModel', () {
    test('detects credited status', () {
      final status = PaymentIntentStatusModel.fromFirestore(
        id: 'intent-1',
        data: const {
          'status': 'credited',
          'type': 'share_top_up',
        },
      );

      expect(status.isCredited, isTrue);
      expect(status.userMessage, contains('반영'));
    });

    test('detects terminal pg failure', () {
      const status = PaymentIntentStatusModel(
        id: 'intent-2',
        status: 'pg_failed',
        type: 'sponsor_payment',
      );

      expect(status.isTerminalFailure, isTrue);
    });
  });
}
