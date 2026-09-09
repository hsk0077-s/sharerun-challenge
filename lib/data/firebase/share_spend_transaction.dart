import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/wallet_model.dart';
import 'firestore_service.dart';

/// Firestore `users/{uid}` 원장 SHARE가 부족한 경우. 트랜잭션은 커밋되지 않는다.
class InsufficientShareException implements Exception {
  const InsufficientShareException({
    required this.requiredAmount,
    required this.available,
  });

  final int requiredAmount;
  final int available;

  @override
  String toString() =>
      'InsufficientShareException(need: $requiredAmount, have: $available)';
}

/// `wallet.shareBalance`를 우선하고, 중첩 맵이 없으면 최상위 `shareBalance`를 읽는다.
int shareBalanceFromUserDoc(Map<String, dynamic>? data) {
  if (data == null) return 0;
  final walletRaw = data['wallet'];
  if (walletRaw is Map) {
    return WalletModel.fromJson(Map<String, dynamic>.from(walletRaw))
        .shareBalance;
  }
  final top = data['shareBalance'];
  if (top is num) return top.toInt();
  return WalletModel.fromJson(data).shareBalance;
}

/// 트랜잭션 안에서 SHARE를 차감한다. 잔액 부족 시 [InsufficientShareException].
///
/// Firestore 규칙: 모든 `get`은 이 함수(및 호출 측)의 쓰기보다 먼저 끝나야 한다.
Future<void> debitShareInTransaction({
  required FirestoreService firestore,
  required Transaction tx,
  required String uid,
  required int amount,
  Map<String, dynamic>? extraUserFields,
}) async {
  if (amount <= 0) {
    throw ArgumentError.value(amount, 'amount');
  }
  final userRef = firestore.doc(FirestorePaths.user(uid));
  final snap = await tx.get(userRef);
  final available = shareBalanceFromUserDoc(snap.data());
  if (available < amount) {
    throw InsufficientShareException(
      requiredAmount: amount,
      available: available,
    );
  }
  tx.set(
    userRef,
    {
      'wallet.shareBalance': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
      if (extraUserFields != null) ...extraUserFields,
    },
    SetOptions(merge: true),
  );
}
