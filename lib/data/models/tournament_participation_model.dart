import 'package:cloud_firestore/cloud_firestore.dart';

import 'tournament_model.dart';

class TournamentParticipationModel {
  const TournamentParticipationModel({
    required this.tournament,
    required this.entryFeeShare,
    required this.participantStatus,
    required this.joinedAt,
    required this.refundStatus,
  });

  final TournamentModel tournament;
  final int entryFeeShare;
  final String participantStatus;
  final DateTime? joinedAt;
  final String? refundStatus;

  bool get isRefunded => refundStatus == 'refunded';

  factory TournamentParticipationModel.fromFirestore({
    required String tournamentId,
    required Map<String, dynamic> tournamentJson,
    required Map<String, dynamic> participantJson,
  }) {
    final joinedAt = participantJson['joinedAt'];
    DateTime? joinedDate;
    if (joinedAt is Timestamp) {
      joinedDate = joinedAt.toDate();
    }

    return TournamentParticipationModel(
      tournament: TournamentModel.fromJson(id: tournamentId, json: tournamentJson),
      entryFeeShare: (participantJson['entryFeeShare'] as num?)?.toInt() ?? 0,
      participantStatus: participantJson['status'] as String? ?? 'joined',
      joinedAt: joinedDate,
      refundStatus: participantJson['refundStatus'] as String?,
    );
  }
}
