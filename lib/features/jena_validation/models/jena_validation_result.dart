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
    this.companyDonationWon = 0,
    this.donationCounted = false,
    this.donationReason = '',
    this.donationCapReached = false,
  });

  final bool verified;
  final JenaDecision decision;
  final String reason;
  final int valueTokenReward;

  /// Server `reason_code`. The screen maps this to plain Korean.
  final String reasonCode;

  /// Server-recorded company won for this run. Never computed on the phone.
  final int companyDonationWon;
  final bool donationCounted;
  final String donationReason;

  /// True when this month's company donation limit is used up.
  final bool donationCapReached;

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
      companyDonationWon: (json['company_donation_won'] as num?)?.toInt() ?? 0,
      donationCounted: json['donation_counted'] as bool? ?? false,
      donationReason: json['donation_reason'] as String? ?? '',
      donationCapReached: json['donation_cap_reached'] as bool? ?? false,
    );
  }
}
