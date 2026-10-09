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

  /// Client receipts are not the ledger. History reads `walletTransactions`.
  Future<void> logClientWalletTransaction({
    required String uid,
    required String title,
    required int amount,
    required String assetType,
  }) async {
    debugPrint(
      'logClientWalletTransaction skipped (server ledger): '
      'uid=$uid $assetType $amount $title',
    );
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
    int? shareBalanceAfter,
    int? diamondBalance,
    int? valueBalance,
    int? donationCount,
    int? cumulativeDonationAmount,
    bool isSponsored = false,
  }) async {
    if (!kDebugMode) {
      throw UnsupportedError('Debug SHARE spend persist is debug-only.');
    }
    if (uid.isEmpty || shareDelta >= 0) return;
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (shareBalanceAfter != null && shareBalanceAfter >= 0) {
      payload.addAll(
        DebugWalletGrant.shareSpendMergeFields(
          uid: uid,
          shareBalanceAfter: shareBalanceAfter,
          diamondBalance: diamondBalance,
          valueBalance: valueBalance,
          donationCount: donationCount,
          cumulativeDonationAmount: cumulativeDonationAmount,
          isSponsored: isSponsored,
        ),
      );
    } else {
      payload.addAll({
        'uid': uid,
        DebugWalletGrant.prefsKey: true,
        'wallet.shareBalance': FieldValue.increment(shareDelta),
        if (diamondBalance != null) 'wallet.diamondBalance': diamondBalance,
        if (valueBalance != null) 'wallet.valueTokenBalance': valueBalance,
        if (donationCount != null) 'donationCount': donationCount,
        if (cumulativeDonationAmount != null)
          'cumulativeDonationAmount': cumulativeDonationAmount,
        if (isSponsored) 'isSponsored': true,
      });
    }
    await _firestoreService.doc(FirestorePaths.user(uid)).set(
          payload,
          SetOptions(merge: true),
        );
  }

  /// Debug USB: persist a shop DIA/VALUE spend (+ optional CPR flag).
  /// Release: no-op. Local SharedPreferences still holds the spend if this
  /// write is permission-denied (rules not deployed yet).
  Future<void> persistDebugShopSpend({
    required String uid,
    required int shareBalance,
    required int diamondBalance,
    required int valueBalance,
    bool? hasCPR,
  }) async {
    if (!kDebugMode) {
      throw UnsupportedError('Debug shop spend persist is debug-only.');
    }
    if (uid.isEmpty || shareBalance < 0 || diamondBalance < 0 || valueBalance < 0) {
      return;
    }
    await _firestoreService.doc(FirestorePaths.user(uid)).set(
      {
        ...DebugWalletGrant.shopSpendMergeFields(
          uid: uid,
          shareBalance: shareBalance,
          diamondBalance: diamondBalance,
          valueBalance: valueBalance,
          hasCPR: hasCPR,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
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

  /// 서버 원장 `walletTransactions`의 한 쪽(최신순). 규칙상 본인 행만 읽힌다.
  Future<WalletHistoryPage> fetchTransactionPage(
    String uid, {
    Object? cursor,
    int limit = 30,
  }) async {
    var query = _firestoreService
        .collection(FirestorePaths.walletTransactions)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }
    final snapshot = await query.get();
    final docs = snapshot.docs;
    return WalletHistoryPage(
      rows: [
        for (final doc in docs)
          WalletTransactionModel.fromFirestore(id: doc.id, data: doc.data()),
      ],
      cursor: docs.isEmpty ? null : docs.last,
      hasMore: docs.length >= limit,
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
