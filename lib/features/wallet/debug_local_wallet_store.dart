import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug USB durable SHARE + paid-join ledger.
///
/// Firestore `persistDebugShareSpend` is often permission-denied when the
/// one-shot grant never landed on `users/{uid}`. Home then hydrates the
/// pre-debit 1M and wipes the join. This store is the fallback ledger so
/// SHARE and `대회 참가` history survive hydrate / kill. Release never reads
/// or writes it.
class DebugLocalShareTx {
  const DebugLocalShareTx({
    required this.id,
    required this.title,
    required this.amount,
    required this.assetType,
    required this.timestampMs,
  });

  final String id;
  final String title;
  final int amount;
  final String assetType;
  final int timestampMs;

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(timestampMs);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'assetType': assetType,
        'timestampMs': timestampMs,
      };

  factory DebugLocalShareTx.fromJson(Map<String, dynamic> json) {
    return DebugLocalShareTx(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      assetType: json['assetType'] as String? ?? 'SHARE',
      timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class DebugLocalWalletSnapshot {
  const DebugLocalWalletSnapshot({
    this.share,
    this.paidIds = const {},
    this.history = const [],
  });

  final int? share;
  final Set<String> paidIds;
  final List<DebugLocalShareTx> history;
}

abstract final class DebugLocalWalletStore {
  static const shareKeyPrefix = 'debugLocalShareBalance_';
  static const historyKeyPrefix = 'debugLocalShareHistory_';
  static const paidJoinKeyPrefix = 'debugPaidJoinedIds_';

  /// PR #14 wrote this even when Firestore persist failed. Do not treat it
  /// as payment proof — only [paidJoinKeyPrefix] / remote Jena ids count.
  static const legacyJoinedKeyPrefix = 'debugLocalJoinedIds_';

  static const harvestSlack = 60;
  static const maxSpendShareDrop = 250000;

  static final Map<String, int> _share = {};
  static final Map<String, Set<String>> _paid = {};
  static final Map<String, List<DebugLocalShareTx>> _history = {};

  static String shareKey(String uid) => '$shareKeyPrefix$uid';
  static String historyKey(String uid) => '$historyKeyPrefix$uid';
  static String paidJoinKey(String uid) => '$paidJoinKeyPrefix$uid';
  static String legacyJoinedKey(String uid) => '$legacyJoinedKeyPrefix$uid';

  static int? cachedShare(String uid) => _share[uid];
  static Set<String> cachedPaidJoins(String uid) =>
      Set<String>.unmodifiable(_paid[uid] ?? const {});
  static List<DebugLocalShareTx> cachedHistory(String uid) =>
      List<DebugLocalShareTx>.unmodifiable(_history[uid] ?? const []);

  static void clearCacheForTest() {
    _share.clear();
    _paid.clear();
    _history.clear();
  }

  static void rememberInMemory({
    required String uid,
    int? share,
    Set<String>? paidIds,
    List<DebugLocalShareTx>? history,
  }) {
    if (uid.isEmpty) return;
    if (share != null && share >= 0) _share[uid] = share;
    if (paidIds != null) {
      _paid[uid] = paidIds.where((id) => id.isNotEmpty).toSet();
    }
    if (history != null) _history[uid] = List<DebugLocalShareTx>.from(history);
  }

  /// Firestore SHARE cannot climb back over a recorded spend except a small
  /// harvest bump. Grant restore (1M over 0) is not clamped here — callers
  /// skip the ceiling when there is no durable spend.
  static int applyShareCeiling({
    required int incomingShare,
    required int durableShare,
    int harvestSlack = harvestSlack,
  }) {
    if (incomingShare <= durableShare) return incomingShare;
    final bump = incomingShare - durableShare;
    if (bump <= harvestSlack) return incomingShare;
    return durableShare;
  }

  /// In-session: incoming SHARE restores a join/sponsor-sized debit.
  static bool shouldRejectHydrateRestore({
    required int currentShare,
    required int incomingShare,
    int harvestSlack = harvestSlack,
    int maxSpendDrop = maxSpendShareDrop,
  }) {
    if (!kDebugMode) return false;
    final restore = incomingShare - currentShare;
    if (restore <= harvestSlack) return false;
    return restore <= maxSpendDrop;
  }

  static bool isPaidJoin({
    required Set<String> remoteJoinedIds,
    required Set<String> durablePaidIds,
    required String tournamentId,
  }) {
    if (tournamentId.isEmpty) return false;
    return remoteJoinedIds.contains(tournamentId) ||
        durablePaidIds.contains(tournamentId);
  }

  static Set<String> parseIdList(List<String>? stored) {
    if (stored == null || stored.isEmpty) return {};
    return stored.where((id) => id.isNotEmpty).toSet();
  }

  static List<DebugLocalShareTx> parseHistory(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (row) => DebugLocalShareTx.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .where((tx) => tx.title.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static DebugLocalWalletSnapshot hydrateFromPrefs(
    SharedPreferences prefs,
    String uid,
  ) {
    if (uid.isEmpty) return const DebugLocalWalletSnapshot();
    final share = prefs.getInt(shareKey(uid));
    final paid = parseIdList(prefs.getStringList(paidJoinKey(uid)));
    final history = parseHistory(prefs.getString(historyKey(uid)));
    rememberInMemory(
      uid: uid,
      share: share,
      paidIds: paid,
      history: history,
    );
    return DebugLocalWalletSnapshot(
      share: share,
      paidIds: paid,
      history: history,
    );
  }

  static Future<void> recordPaidJoin({
    required SharedPreferences prefs,
    required String uid,
    required String tournamentId,
    required int shareBalanceAfter,
    required int debitAmount,
    required String historyTitle,
  }) async {
    if (uid.isEmpty || shareBalanceAfter < 0) return;
    final wasPaid = cachedPaidJoins(uid).contains(tournamentId);
    final paid = {
      ...cachedPaidJoins(uid),
      if (tournamentId.isNotEmpty) tournamentId,
    };
    var history = cachedHistory(uid);
    if (!wasPaid && debitAmount > 0) {
      final tx = DebugLocalShareTx(
        id: 'TX_SHARE_LOCAL_${DateTime.now().millisecondsSinceEpoch}',
        title: historyTitle,
        amount: -debitAmount,
        assetType: 'SHARE',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
      history = [tx, ...history].take(40).toList();
    }
    rememberInMemory(
      uid: uid,
      share: shareBalanceAfter,
      paidIds: paid,
      history: history,
    );
    await prefs.setInt(shareKey(uid), shareBalanceAfter);
    await prefs.setStringList(paidJoinKey(uid), paid.toList());
    await prefs.setString(
      historyKey(uid),
      jsonEncode(history.map((tx) => tx.toJson()).toList()),
    );
  }

  /// Merge local debug receipts with Firestore so USB still shows `대회 참가`
  /// when `wallet_transactions` create is denied.
  static List<DebugLocalShareTx> mergeHistory({
    required List<DebugLocalShareTx> remote,
    required List<DebugLocalShareTx> local,
  }) {
    bool sameReceipt(DebugLocalShareTx a, DebugLocalShareTx b) {
      if (a.id.isNotEmpty && a.id == b.id) return true;
      if (a.title != b.title || a.amount != b.amount) return false;
      if (a.assetType != b.assetType) return false;
      final dt = (a.timestampMs - b.timestampMs).abs();
      return dt < 120000;
    }

    final out = <DebugLocalShareTx>[];
    for (final localTx in local) {
      final dup = remote.any((remoteTx) => sameReceipt(localTx, remoteTx));
      if (!dup) out.add(localTx);
    }
    out.addAll(remote);
    out.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return out;
  }
}
