import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../api/secured_action_api_client.dart';
import '../firebase/firestore_service.dart';
import '../firebase/share_spend_transaction.dart';
import '../models/tournament_model.dart';
import '../models/tournament_participation_model.dart';

class TournamentRepository {
  TournamentRepository(
    this._firestoreService,
    this._securedActionApiClient,
  );

  final FirestoreService _firestoreService;
  final SecuredActionApiClient _securedActionApiClient;

  /// 유저 주도 방 개설 → SHARE 차감과 `/tournaments` 인서트를 한 트랜잭션으로 커밋.
  Future<TournamentModel> createUserChallengeRoom({
    required String title,
    required int distanceKm,
    required int entryFeeShare,
    required String createdByUid,
    String donationTarget = 'UNICEF',
    int? minParticipantsBep,
    int? maxParticipants,
  }) async {
    final bep = minParticipantsBep ?? defaultBepForDistance(distanceKm);
    final capacity = maxParticipants ?? (bep * 2).clamp(20, 400);
    final doc = _firestoreService.collection(FirestorePaths.tournaments).doc();
    final room = TournamentModel(
      id: doc.id,
      title: title,
      targetDistanceKm: distanceKm.toDouble(),
      entryFeeShare: entryFeeShare,
      winnerRewardValue: (entryFeeShare * 0.4).round(),
      donationValue: (entryFeeShare * 0.2).round(),
      minParticipantsBep: bep,
      maxParticipants: capacity,
      participantCount: 1,
      requiredTier: 1,
      status: TournamentStatus.recruiting,
      sponsorName: donationTarget,
      sponsorBillboardMessages: const [],
    );

    await _firestoreService.runTransaction<void>((tx) async {
      await debitShareInTransaction(
        firestore: _firestoreService,
        tx: tx,
        uid: createdByUid,
        amount: entryFeeShare,
      );
      tx.set(doc, {
        ...room.toFirestoreMap(createdByUid: createdByUid),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return room;
  }

  static int defaultBepForDistance(int distanceKm) {
    return switch (distanceKm) {
      1 => 50,
      3 => 100,
      5 => 150,
      10 => 200,
      _ => 250,
    };
  }

  Stream<List<TournamentModel>> watchTournamentRooms() {
    return _firestoreService
        .collection(FirestorePaths.tournaments)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TournamentModel.fromJson(
                  id: doc.id,
                  json: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Stream<TournamentModel?> watchTournament(String tournamentId) {
    return _firestoreService
        .doc(FirestorePaths.tournament(tournamentId))
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return TournamentModel.fromJson(
        id: snapshot.id,
        json: snapshot.data() ?? const {},
      );
    });
  }

  Future<void> joinTournament({
    required TournamentModel tournament,
  }) {
    return _securedActionApiClient.joinTournament(
      tournamentId: tournament.id,
    );
  }

  Stream<Set<String>> watchJoinedTournamentIds(String uid) {
    return _firestoreService
        .collectionGroup('participants')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.reference.parent.parent?.id)
              .whereType<String>()
              .toSet(),
        );
  }

  Stream<List<TournamentParticipationModel>> watchJoinedParticipations(
    String uid,
  ) {
    return _firestoreService
        .collectionGroup('participants')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final participations = <TournamentParticipationModel>[];

      for (final participantDoc in snapshot.docs) {
        final tournamentId = participantDoc.reference.parent.parent?.id;
        if (tournamentId == null) {
          continue;
        }

        final tournamentSnapshot = await _firestoreService
            .doc(FirestorePaths.tournament(tournamentId))
            .get();
        if (!tournamentSnapshot.exists) {
          continue;
        }

        participations.add(
          TournamentParticipationModel.fromFirestore(
            tournamentId: tournamentId,
            tournamentJson: tournamentSnapshot.data() ?? const {},
            participantJson: participantDoc.data(),
          ),
        );
      }

      participations.sort(
        (left, right) =>
            (right.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(left.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return participations;
    });
  }
}
