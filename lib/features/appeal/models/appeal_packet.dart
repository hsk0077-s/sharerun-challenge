enum AppealPacketStatus {
  pending,
  underReview,
  approved,
  rejected,
}

extension AppealPacketStatusCode on AppealPacketStatus {
  String get code => switch (this) {
        AppealPacketStatus.pending => 'pending',
        AppealPacketStatus.underReview => 'under_review',
        AppealPacketStatus.approved => 'approved',
        AppealPacketStatus.rejected => 'rejected',
      };

  static AppealPacketStatus fromCode(String? code) {
    return switch (code) {
      'under_review' => AppealPacketStatus.underReview,
      'approved' => AppealPacketStatus.approved,
      'rejected' => AppealPacketStatus.rejected,
      _ => AppealPacketStatus.pending,
    };
  }
}

/// src-admin-2 소명 대기 리스트 인계 패킷.
class AppealPacket {
  const AppealPacket({
    required this.appealId,
    required this.userId,
    required this.userNickname,
    required this.activityId,
    required this.reasonCategory,
    required this.reasonDetail,
    required this.proofImageUri,
    required this.status,
    required this.createdAt,
    required this.expireAt,
    required this.purgeAt,
    this.ttlDays = 14,
    this.purgeOnAdminDecision = true,
    this.challengeTitle = '중급 3km 챌린지',
  });

  final String appealId;
  final String userId;
  final String userNickname;
  final String activityId;
  final String reasonCategory;
  final String reasonDetail;
  final String proofImageUri;
  final AppealPacketStatus status;
  final DateTime createdAt;
  final DateTime expireAt;
  final DateTime purgeAt;
  final int ttlDays;
  final bool purgeOnAdminDecision;
  final String challengeTitle;

  Map<String, dynamic> toFirestore() {
    return {
      'appealId': appealId,
      'userId': userId,
      'userNickname': userNickname,
      'activityId': activityId,
      'reasonCategory': reasonCategory,
      'reasonDetail': reasonDetail,
      'proofImageUri': proofImageUri,
      'status': status.code,
      'adminQueue': 'src-admin-2',
      'challengeTitle': challengeTitle,
      'ttlDays': ttlDays,
      'purgeOnAdminDecision': purgeOnAdminDecision,
      'retentionPolicy': 'purge_on_admin_decision_or_${ttlDays}d',
      'createdAt': createdAt.toUtc().toIso8601String(),
      'expireAt': expireAt.toUtc().toIso8601String(),
      'purgeAt': purgeAt.toUtc().toIso8601String(),
    };
  }
}
