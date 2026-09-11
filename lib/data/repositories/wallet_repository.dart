import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/async/stream_guards.dart';
import '../../core/constants/debug_wallet_grant.dart';
import '../../core/constants/firestore_paths.dart';
import '../api/secured_action_api_client.dart';
import '../firebase/firestore_service.dart';
import '../models/pedometer_harvest_result.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

class WalletRepository {
  WalletRepository(
    this._firestoreService,
    this._securedActionApiClient,
  );

  final FirestoreService _firestoreService;
  final SecuredActionApiClient _securedActionApiClient;

  /// SHARE 증감은 웹훅 / secured actions 전용. 클라이언트는 원장을 쓰지 않는다.
  Future<void> applyShareDelta(String uid, int delta) async {
    debugPrint(
      'applyShareDelta skipped (server-owned wallet): uid=$uid delta=$delta',
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
    return onStreamErrorEmit<WalletModel>(
      _firestoreService.doc(FirestorePaths.user(uid)).snapshots().map(
        (snapshot) {
          try {
            final data = snapshot.data();
            final walletRaw = data?['wallet'];
            final Map<String, dynamic>? walletMap = switch (walletRaw) {
              final Map<String, dynamic> m => m,
              final Map m => Map<String, dynamic>.from(m),
              _ => null,
            };
            return WalletModel.fromJson({
              if (data?['shareBalance'] != null)
                'shareBalance': data!['shareBalance'],
              if (data?['diamondBalance'] != null)
                'diamondBalance': data!['diamondBalance'],
              if (data?['valueBalance'] != null)
                'valueTokenBalance': data!['valueBalance'],
              if (data?['valueTokenBalance'] != null)
                'valueTokenBalance': data!['valueTokenBalance'],
              ...?walletMap,
            });
          } catch (e) {
            debugPrint('watchWallet parse: $e');
            return WalletModel.empty();
          }
        },
      ),
      WalletModel.empty(),
      debugLabel: 'watchWallet',
    );
  }

  Future<void> requestCashRefund({
    required int shareAmount,
  }) {
    return _securedActionApiClient.requestRefund(shareAmount: shareAmount);
  }

  /// Walking-challenge SHARE mint. Server updates `wallet.shareBalance` only.
  Future<PedometerHarvestResult> harvestPedometerShare({
    required int claimedSteps,
  }) {
    return _securedActionApiClient.harvestPedometerShare(
      claimedSteps: claimedSteps,
    );
  }

  /// Debug one-shot 1M SHARE/DIA/VALUE. No-op outside [kDebugMode].
  Future<PedometerHarvestResult> grantDebugTestWallet1m({
    String grantSecret = '',
  }) {
    if (!kDebugMode) {
      throw UnsupportedError('Debug test grant is debug-only.');
    }
    return _securedActionApiClient.grantDebugTestWallet1m(
      grantSecret: grantSecret,
    );
  }

  /// Debug one-shot write to `users/{uid}.wallet` + `testGrant1mDone`.
  /// Home/`walletProvider` read this document. Release/profile must not call.
  Future<void> applyLocalDebugTestGrant({required String uid}) async {
    if (!kDebugMode) {
      throw UnsupportedError('Debug test grant is debug-only.');
    }
    if (uid.isEmpty) return;
    await _firestoreService.doc(FirestorePaths.user(uid)).set(
      {
        'uid': uid,
        ...DebugWalletGrant.firestoreMergeFields(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Debug USB: persist a SHARE spend + donation totals without rewriting
  /// DIA/VALUE or zeroing aggregates. Release: no-op.
  Future<void> persistDebugShareSpend({
    required String uid,
    required int shareDelta,
    int? donationCount,
    int? cumulativeDonationAmount,
    bool isSponsored = false,
  }) async {
    if (!kDebugMode) {
      throw UnsupportedError('Debug SHARE spend persist is debug-only.');
    }
    if (uid.isEmpty || shareDelta >= 0) return;
    await _firestoreService.doc(FirestorePaths.user(uid)).set(
      {
        'uid': uid,
        'wallet.shareBalance': FieldValue.increment(shareDelta),
        'updatedAt': FieldValue.serverTimestamp(),
        if (donationCount != null) 'donationCount': donationCount,
        if (cumulativeDonationAmount != null)
          'cumulativeDonationAmount': cumulativeDonationAmount,
        if (isSponsored) 'isSponsored': true,
      },
      SetOptions(merge: true),
    );
  }

  /// Debug harvest: persist SHARE only. DIA/VALUE stay as-is. Release: no-op.
  Future<void> creditLocalDebugHarvestShare({
    required String uid,
    required int shareBalance,
  }) async {
    if (!kDebugMode) {
      throw UnsupportedError('Debug harvest credit is debug-only.');
    }
    if (uid.isEmpty || shareBalance < 0) return;
    await _firestoreService.doc(FirestorePaths.user(uid)).set(
      {
        'uid': uid,
        'wallet.shareBalance': shareBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
