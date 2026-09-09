import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../firebase/firestore_service.dart';

/// 클라이언트는 영수증만 적재한다. SHARE 가산은 status == VERIFIED 이후 서버 전용.
class PurchaseRepository {
  PurchaseRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  static const pendingVerify = 'PENDING_VERIFY';
  static const verified = 'VERIFIED';
  static const rejected = 'REJECTED';

  Future<String> enqueuePendingReceipt({
    required String userId,
    required String productId,
    required int shareAmount,
    required String purchaseId,
    required String serverVerificationData,
    required String localVerificationData,
    required String source,
  }) async {
    final docId = purchaseId.trim().isEmpty
        ? 'iap-${DateTime.now().millisecondsSinceEpoch}'
        : purchaseId.trim();
    final ref = _firestoreService.doc(FirestorePaths.purchase(docId));

    await _firestoreService.runTransaction<void>((tx) async {
      tx.set(ref, {
        'userId': userId,
        'productId': productId,
        'shareAmount': shareAmount,
        'purchaseID': purchaseId,
        'verificationData': {
          'serverVerificationData': serverVerificationData,
          'localVerificationData': localVerificationData,
          'source': source,
        },
        'status': pendingVerify,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return docId;
  }

  Stream<String?> watchStatus(String purchaseDocId) {
    return _firestoreService.doc(FirestorePaths.purchase(purchaseDocId)).snapshots().map(
      (snapshot) => snapshot.data()?['status'] as String?,
    );
  }

  /// 로컬/모의 CF — Play Developer API 대조 성공을 재현. 운영에서는 Cloud Functions만 호출.
  Future<void> markVerifiedForMock({required String purchaseDocId}) {
    return _firestoreService.doc(FirestorePaths.purchase(purchaseDocId)).set(
      {
        'status': verified,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
