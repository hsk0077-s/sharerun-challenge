enum TournamentStatus {
  recruiting,
  active,
  cancelled,
  cancelledBepNotMet,
  completed,
}

class TournamentModel {
  const TournamentModel({
    required this.id,
    required this.title,
    required this.targetDistanceKm,
    required this.entryFeeShare,
    required this.winnerRewardValue,
    required this.donationValue,
    required this.minParticipantsBep,
    required this.maxParticipants,
    required this.participantCount,
    required this.requiredTier,
    required this.status,
    required this.sponsorName,
    this.sponsorBillboardMessages = const [],
  });

  final String id;
  final String title;
  final double targetDistanceKm;
  final int entryFeeShare;
  final int winnerRewardValue;
  final int donationValue;
  final int minParticipantsBep;
  final int maxParticipants;
  final int participantCount;
  final int requiredTier;
  final TournamentStatus status;
  final String sponsorName;
  final List<String> sponsorBillboardMessages;

  bool get isRecruiting => status == TournamentStatus.recruiting;

  bool lockedForTier(int userTier) {
    return requiredTier < userTier;
  }

  bool get hasCapacityLimit => maxParticipants > 0;

  bool get isFull => hasCapacityLimit && participantCount >= maxParticipants;

  String get recruitmentSummary {
    final bep = '$participantCount/$minParticipantsBep BEP';
    if (hasCapacityLimit) {
      return '$bep · $participantCount/$maxParticipants capacity';
    }
    return bep;
  }

  factory TournamentModel.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    return TournamentModel(
      id: id,
      title: json['title'] as String? ?? 'SRC Tournament',
      targetDistanceKm: (json['targetDistanceKm'] as num?)?.toDouble() ?? 3,
      entryFeeShare: (json['entryFeeShare'] as num?)?.toInt() ?? 0,
      winnerRewardValue: (json['winnerRewardValue'] as num?)?.toInt() ?? 0,
      donationValue: (json['donationValue'] as num?)?.toInt() ?? 0,
      minParticipantsBep: (json['minParticipantsBep'] as num?)?.toInt() ?? 0,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 0,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      requiredTier: (json['requiredTier'] as num?)?.toInt() ?? 1,
      status: _statusFromCode(json['status'] as String?),
      sponsorName: json['sponsorName'] as String? ?? 'SRC Sponsor',
      sponsorBillboardMessages: (json['sponsorBillboardMessages'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }

  static TournamentStatus _statusFromCode(String? code) {
    return switch (code) {
      'active' => TournamentStatus.active,
      'cancelled' => TournamentStatus.cancelled,
      'cancelled_bep_not_met' => TournamentStatus.cancelledBepNotMet,
      'completed' => TournamentStatus.completed,
      _ => TournamentStatus.recruiting,
    };
  }

  String get statusCode => switch (status) {
        TournamentStatus.active => 'active',
        TournamentStatus.cancelled => 'cancelled',
        TournamentStatus.cancelledBepNotMet => 'cancelled_bep_not_met',
        TournamentStatus.completed => 'completed',
        TournamentStatus.recruiting => 'recruiting',
      };

  /// Firestore `/tournaments` 문서 페이로드 (createdAt은 Repository에서 주입).
  Map<String, dynamic> toFirestoreMap({String? createdByUid}) {
    return {
      'title': title,
      'targetDistanceKm': targetDistanceKm,
      'entryFeeShare': entryFeeShare,
      'winnerRewardValue': winnerRewardValue,
      'donationValue': donationValue,
      'minParticipantsBep': minParticipantsBep,
      'maxParticipants': maxParticipants,
      'participantCount': participantCount,
      'requiredTier': requiredTier,
      'status': statusCode,
      'sponsorName': sponsorName,
      'sponsorBillboardMessages': sponsorBillboardMessages,
      if (createdByUid != null) 'createdByUid': createdByUid,
      'userCreated': true,
    };
  }
}
