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

  test('already_harvested without share_credited does not replay the floor', () {
    final result = PedometerHarvestResult.fromJson({
      'status': 'already_harvested',
      'share_balance': 40,
    });
    expect(result.creditedShare(fallback: 29), 0);
  });

  test('empty body does not credit the client floor amount', () {
    final result = PedometerHarvestResult.fromJson(const {});
    expect(result.status, isEmpty);
    expect(result.creditedShare(fallback: 29), 0);
  });

  test('debug 1M grant snapshot parses all three balances', () {
    final result = PedometerHarvestResult.fromJson({
      'status': 'granted',
      'share_credited': 1000000,
      'share_balance': 1000000,
      'diamond_balance': 1000000,
      'value_token_balance': 1000000,
    });

    expect(result.status, 'granted');
    expect(result.shareBalance, 1000000);
    expect(result.diamondBalance, 1000000);
    expect(result.valueTokenBalance, 1000000);
  });
}
