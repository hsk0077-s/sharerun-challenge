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
    this.prizeTier = '',
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

  /// Company prize race tier. Empty on a normal room.
  final String prizeTier;

  bool get isRecruiting => status == TournamentStatus.recruiting;

  bool get isPrizeRace => prizeTier.isNotEmpty;

  bool get isTerminal =>
      status == TournamentStatus.cancelled ||
      status == TournamentStatus.cancelledBepNotMet ||
      status == TournamentStatus.completed;

  bool lockedForTier(int userTier) {
    return requiredTier < userTier;
  }

  bool get hasCapacityLimit => maxParticipants > 0;

  bool get isFull => hasCapacityLimit && participantCount >= maxParticipants;

  /// Headcount users see. The minimum-to-open figure stays off this line.
  String get recruitmentSummary {
    if (hasCapacityLimit) {
      return '참가자 $participantCount/$maxParticipants명';
    }
    return '참가자 $participantCount명';
  }

  bool get _prizeTakenFromEntryFee {
    if (entryFeeShare <= 0) return false;
    return winnerRewardValue == (entryFeeShare * 0.4).round() &&
        donationValue == (entryFeeShare * 0.2).round();
  }

  /// Cash pool line. Null when the room has no sponsor or company prize.
  String? get cashPrizePoolLabel {
    if (!isPrizeRace &&
        (_prizeTakenFromEntryFee ||
            (winnerRewardValue <= 0 && donationValue <= 0))) {
      return null;
    }
    return 'Donation pool: $donationValue Value';
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
      prizeTier: json['prizeTier'] is String
          ? (json['prizeTier'] as String).trim()
          : '',
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
