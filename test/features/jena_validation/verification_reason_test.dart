import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/jena_validation/models/jena_validation_result.dart';
import 'package:share_run_challenge/features/jena_validation/verification_reason.dart';

void main() {
  test('reason codes become a specific Korean explanation', () {
    const codes = {
      'distance_too_short': '최소 거리',
      'cadence_out_of_range': '120~210',
      'heart_rate_required': '워치 심박',
      'heart_rate_low': '평균 심박',
      'heart_rate_flat': '거의 변하지',
      'stride_out_of_range': '보폭',
      'vehicle_speed': '차량',
      'kickboard': '킥보드',
      'bike': '자전거',
    };
    for (final entry in codes.entries) {
      final result = JenaValidationResult.fromJson({
        'verified': false,
        'decision': 'rejected_unknown',
        'reason': '서버 내부 문장',
        'reason_code': entry.key,
        'value_token_reward': 0,
      });
      final message = verificationUserMessage(result);
      expect(message, contains(entry.value), reason: entry.key);
      expect(message, isNot(verificationRejectedFallback));
      expect(message, isNot('서버 내부 문장'));
    }
  });

  test('a missing code falls back to the server sentence', () {
    final result = JenaValidationResult.fromJson({
      'verified': false,
      'decision': 'rejected_unknown',
      'reason': '검증 최소 거리에 못 미칩니다.',
      'value_token_reward': 0,
    });
    expect(result.reasonCode, isEmpty);
    expect(
      verificationUserMessage(result),
      '검증 최소 거리에 못 미칩니다.',
    );
  });

  test('an empty rejection uses the generic line', () {
    const result = JenaValidationResult(
      verified: false,
      decision: JenaDecision.rejectedUnknown,
      reason: 'No reason provided.',
      valueTokenReward: 0,
    );
    expect(verificationUserMessage(result), verificationRejectedFallback);
  });
}
