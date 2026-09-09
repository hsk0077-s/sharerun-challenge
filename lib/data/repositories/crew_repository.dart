import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../firebase/share_spend_transaction.dart';
import '../models/crew_ranking_model.dart';

class CrewRepository {
  CrewRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  /// 크루 창설 — SHARE 차감과 `crews` 문서 생성을 원자적으로 커밋.
  Future<CrewRankingModel> createCrewWithShareDebit({
    required String uid,
    required String name,
    required int shareCost,
  }) async {
    final crewRef = _firestoreService.collection(FirestorePaths.crews).doc();
    final crew = CrewRankingModel(
      id: crewRef.id,
      name: name,
      totalValue: 0,
      memberCount: 1,
    );

    await _firestoreService.runTransaction<void>((tx) async {
      await debitShareInTransaction(
        firestore: _firestoreService,
        tx: tx,
        uid: uid,
        amount: shareCost,
        extraUserFields: {'ownedCrewId': crewRef.id},
      );
      tx.set(crewRef, {
        'name': name,
        'ownerUid': uid,
        'totalValue': 0,
        'memberCount': 1,
        'shareCost': shareCost,
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
