import '../../../data/models/activity_model.dart';

enum JenaDecision {
  verified,
  pending,
  rejectedKickboard,
  rejectedBike,
  rejectedUnknown,
}

extension JenaDecisionActivityStatus on JenaDecision {
  ActivityStatus get activityStatus => switch (this) {
        JenaDecision.verified => ActivityStatus.passed,
        JenaDecision.pending => ActivityStatus.pending,
        _ => ActivityStatus.failed,
      };
}

class JenaValidationResult {
  const JenaValidationResult({
    required this.verified,
    required this.decision,
    required this.reason,
    required this.valueTokenReward,
    this.reasonCode = '',
  });

  final bool verified;
  final JenaDecision decision;
  final String reason;
  final int valueTokenReward;

  /// Server `reason_code`. The screen maps this to plain Korean.
  final String reasonCode;

  factory JenaValidationResult.fromJson(Map<String, dynamic> json) {
    final decisionCode = json['decision'] as String? ?? 'rejected_unknown';
    final rawCode = json['reason_code'] ?? json['reasonCode'];

    return JenaValidationResult(
      verified: json['verified'] as bool? ?? false,
      decision: switch (decisionCode) {
        'verified' => JenaDecision.verified,
        'pending' => JenaDecision.pending,
        'rejected_kickboard' => JenaDecision.rejectedKickboard,
        'rejected_bike' => JenaDecision.rejectedBike,
        _ => JenaDecision.rejectedUnknown,
      },
      reason: json['reason'] as String? ?? 'No reason provided.',
      reasonCode: rawCode is String ? rawCode : '',
      valueTokenReward: (json['value_token_reward'] as num?)?.toInt() ?? 0,
    );
  }
}
