import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/pedometer_harvest_result.dart';

void main() {
  test('fromJson reads snake_case harvest snapshot', () {
    final result = PedometerHarvestResult.fromJson({
      'accepted': true,
      'status': 'harvested',
      'share_credited': 51,
      'share_balance': 91,
      'diamond_balance': 3,
      'value_token_balance': 5000,
    });

    expect(result.creditedShare(fallback: 40), 51);
    expect(result.shareBalance, 91);
    expect(result.diamondBalance, 3);
    expect(result.valueTokenBalance, 5000);
  });

  test('already_harvested does not fall back to the client floor amount', () {
    final result = PedometerHarvestResult.fromJson({
      'status': 'already_harvested',
      'share_credited': 0,
      'share_balance': 40,
      'diamond_balance': 0,
      'value_token_balance': 5000,
    });

    expect(result.creditedShare(fallback: 51), 0);
    expect(result.shareBalance, 40);
    expect(result.valueTokenBalance, 5000);
  });

  test('empty body is treated as harvested so older APIs still credit', () {
    final result = PedometerHarvestResult.fromJson(const {});
    expect(result.status, 'harvested');
    expect(result.creditedShare(fallback: 20), 20);
  });
}
