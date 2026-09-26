import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../firebase/crew_founding_write.dart';
import '../firebase/firestore_service.dart';
import '../firebase/share_spend_transaction.dart';
import '../models/crew_ranking_model.dart';

class CrewRepository {
  CrewRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  /// 크루 창설 — SHARE 차감과 `crews` 문서 생성을 원자적으로 커밋.
  ///
  /// Absolute nested SHARE via `update`. `ownedCrewId` is allowed only on
  /// this write (`validCrewFoundingDebit` in `firestore.rules`).
  Future<CrewRankingModel> createCrewWithShareDebit({
    required String uid,
    required String name,
    required int shareCost,
  }) async {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid');
    }
    final crewBody = CrewFoundingWrite.crewFields(
      name: name,
      ownerUid: uid,
      shareCost: shareCost,
    );
    final crewRef = _firestoreService.collection(FirestorePaths.crews).doc();
    if (!CrewFoundingWrite.isCrewId(crewRef.id)) {
      throw StateError('Unexpected crew id: ${crewRef.id}');
    }
    final crew = CrewRankingModel(
      id: crewRef.id,
      name: crewBody['name']! as String,
      totalValue: 0,
      memberCount: 1,
    );

    await _firestoreService.runTransaction<void>((tx) async {
      final userRef = _firestoreService.doc(FirestorePaths.user(uid));
      final snap = await tx.get(userRef);
      final available = shareBalanceFromUserDoc(snap.data());
      final shareAfter = CrewFoundingWrite.shareAfter(
        availableShare: available,
        shareCost: shareCost,
      );
      if (shareAfter == null) {
        throw InsufficientShareException(
          requiredAmount: shareCost,
          available: available,
        );
      }
      // Reads finish before writes. `update` dot-path keeps DIA/VALUE.
      tx.update(userRef, {
        ...CrewFoundingWrite.userMergeFields(
          shareAfter: shareAfter,
          crewId: crewRef.id,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(crewRef, {
        ...crewBody,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return crew;
  }

  Stream<List<CrewRankingModel>> watchTopCrews() {
    return _firestoreService
        .collection(FirestorePaths.crewRankings)
        .orderBy('totalValue', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CrewRankingModel.fromJson(
                  id: doc.id,
                  json: doc.data(),
                ),
              )
              .toList(),
        );
  }
}
