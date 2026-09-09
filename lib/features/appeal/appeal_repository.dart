import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/firebase/firestore_service.dart';
import '../../data/models/activity_model.dart';
import 'models/appeal_packet.dart';

class AppealRepository {
  AppealRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  static const proofTtl = Duration(days: 14);

  /// 어드민 소명 대기 리스트로 트랜잭션 인계 + 액티비티 보류 락을 under_review로 전이.
  Future<AppealPacket> submitAppealPacket({
    required AppealPacket packet,
  }) async {
    final appealRef = _firestoreService.doc(FirestorePaths.appeal(packet.appealId));
    final activityRef =
        _firestoreService.doc(FirestorePaths.activity(packet.activityId));

    await _firestoreService.runTransaction<void>((tx) async {
      tx.set(appealRef, {
        ...packet.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(packet.expireAt),
        'purgeAt': Timestamp.fromDate(packet.purgeAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        activityRef,
        {
          'userId': packet.userId,
          'activityId': packet.activityId,
          'activityStatus': ActivityStatus.pending.code,
          'appealStatus': AppealPacketStatus.underReview.code,
          'appealId': packet.appealId,
          'locked': true,
          'jenaVerified': false,
          'Jena_Verified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    return packet;
  }
}
