import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/firestore_paths.dart';
import '../api/secured_action_api_client.dart';
import '../firebase/firestore_service.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

class WalletRepository {
  WalletRepository(
    this._firestoreService,
    this._securedActionApiClient,
  );

  final FirestoreService _firestoreService;
  final SecuredActionApiClient _securedActionApiClient;

  /// GCP 대시보드 싱크용 SHARE 증감 (클라이언트 optimistic; 서버 웹훅과 병행).
  Future<void> applyShareDelta(String uid, int delta) async {
    if (delta == 0) return;
    await _firestoreService.doc(FirestorePaths.user(uid)).set(
      {
        'wallet': {
          'shareBalance': FieldValue.increment(delta),
        },
      },
      SetOptions(merge: true),
    );
    await logClientWalletTransaction(
      uid: uid,
      title: delta > 0 ? 'SHARE 충전 💳' : 'SHARE 차감',
      amount: delta,
      assetType: 'SHARE',
    );
  }

  /// 소비/충전 완료 후 `users/{uid}/wallet_transactions`에 영구 기록한다.
  /// 업로드 실패는 본 결제를 롤백하지 않는다.
  Future<void> logClientWalletTransaction({
    required String uid,
    required String title,
    required int amount,
    required String assetType,
  }) async {
    if (uid.isEmpty) return;
    try {
      await _firestoreService
          .collection(FirestorePaths.userWalletTransactions(uid))
          .add({
        'id': '${_receiptPrefix(assetType)}'
            '${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'amount': amount,
        'assetType': assetType,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE TRANSACTION] $assetType 영수증 발행 완료');
    } catch (e) {
      debugPrint('[FIRESTORE TRANSACTION] $assetType 영수증 발행 실패: $e');
    }
  }

  String _receiptPrefix(String assetType) {
    return switch (assetType) {
      'DIA' => 'TX_DIA_',
      'VALUE' => 'TX_VALUE_',
      _ => 'TX_SHARE_',
    };
  }

  Stream<WalletModel> watchWallet(String uid) {
    return _firestoreService.doc(FirestorePaths.user(uid)).snapshots().map(
      (snapshot) {
        final data = snapshot.data();
        final wallet = data?['wallet'] as Map<String, dynamic>?;

        return WalletModel(
          shareBalance: (wallet?['shareBalance'] as num?)?.toInt() ?? 0,
          diamondBalance: (wallet?['diamondBalance'] as num?)?.toInt() ?? 0,
          valueTokenBalance: (wallet?['valueTokenBalance'] as num?)?.toInt() ?? 0,
          totalDonationValue: (wallet?['totalDonationValue'] as num?)?.toInt() ?? 0,
        );
      },
    );
  }

  Future<void> requestCashRefund({
    required int shareAmount,
  }) {
    return _securedActionApiClient.requestRefund(shareAmount: shareAmount);
  }

  Future<void> transferValueToWeb3({
    required String destinationAddress,
    required int amountSrv,
    required String transferChannel,
  }) {
    return _securedActionApiClient.transferValueToWeb3(
      destinationAddress: destinationAddress,
      amountSrv: amountSrv,
      transferChannel: transferChannel,
    );
  }

  Stream<List<WalletTransactionModel>> watchRecentTransactions(String uid) {
    return _firestoreService
        .collection(FirestorePaths.walletTransactions)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => WalletTransactionModel.fromFirestore(
                  id: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(),
        );
  }
}
