import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/debug_wallet_grant.dart';

/// Debug USB durable SHARE + paid-join ledger, plus last-known DIA/VALUE.
///
/// Firestore wallet writes are often permission-denied (shop DIA/VALUE are
/// not in the legacy rules). This store is the fallback so balances and
/// `대회 참가` history survive hydrate / kill even when the cloud write
/// fails. Release never reads or writes the SHARE join ledger; DIA/VALUE
/// last-known snapshots are the shop persist cache.
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
    this.diamond,
    this.value,
    this.paidIds = const {},
    this.history = const [],
  });

  final int? share;
  final int? diamond;
  final int? value;
  final Set<String> paidIds;
  final List<DebugLocalShareTx> history;
}

abstract final class DebugLocalWalletStore {
  static const shareKeyPrefix = 'debugLocalShareBalance_';
  static const diamondKeyPrefix = 'debugLocalDiamondBalance_';
  static const valueKeyPrefix = 'debugLocalValueBalance_';
  static const historyKeyPrefix = 'debugLocalShareHistory_';
  static const paidJoinKeyPrefix = 'debugPaidJoinedIds_';

  /// PR #14 wrote this even when Firestore persist failed. Do not treat it
  /// as payment proof — only [paidJoinKeyPrefix] / remote Jena ids count.
  static const legacyJoinedKeyPrefix = 'debugLocalJoinedIds_';

  static const harvestSlack = 60;
  static const maxSpendShareDrop = 250000;

  static final Map<String, int> _share = {};
  static final Map<String, int> _diamond = {};
  static final Map<String, int> _value = {};
  static final Map<String, Set<String>> _paid = {};
  static final Map<String, List<DebugLocalShareTx>> _history = {};

  static String shareKey(String uid) => '$shareKeyPrefix$uid';
  static String diamondKey(String uid) => '$diamondKeyPrefix$uid';
  static String valueKey(String uid) => '$valueKeyPrefix$uid';
  static String historyKey(String uid) => '$historyKeyPrefix$uid';
  static String paidJoinKey(String uid) => '$paidJoinKeyPrefix$uid';
  static String legacyJoinedKey(String uid) => '$legacyJoinedKeyPrefix$uid';

  static int? cachedShare(String uid) => _share[uid];
  static int? cachedDiamond(String uid) => _diamond[uid];
  static int? cachedValue(String uid) => _value[uid];
  static Set<String> cachedPaidJoins(String uid) =>
      Set<String>.unmodifiable(_paid[uid] ?? const {});
  static List<DebugLocalShareTx> cachedHistory(String uid) =>
      List<DebugLocalShareTx>.unmodifiable(_history[uid] ?? const []);

  static void clearCacheForTest() {
    _share.clear();
    _diamond.clear();
    _value.clear();
    _paid.clear();
    _history.clear();
  }

  static void rememberInMemory({
    required String uid,
    int? share,
    int? diamond,
    int? value,
    Set<String>? paidIds,
    List<DebugLocalShareTx>? history,
  }) {
    if (uid.isEmpty) return;
    if (share != null && share >= 0) _share[uid] = share;
    if (diamond != null && diamond >= 0) _diamond[uid] = diamond;
    if (value != null && value >= 0) _value[uid] = value;
    if (paidIds != null) {
      _paid[uid] = paidIds.where((id) => id.isNotEmpty).toSet();
    }
    if (history != null) _history[uid] = List<DebugLocalShareTx>.from(history);
  }

  /// Merge a recorded DIA/VALUE snapshot with a remote/in-memory value.
  ///
  /// This is **not** the reverted #29 anti-1M ceiling. A missing or zero
  /// durable must never wipe a legitimate high incoming grant. A stale
  /// exact 1M snapshot cannot refill a recorded shop spend.
  static int resolveDurableCurrency({
    required int incoming,
    required int durable,
    int grantAmount = DebugWalletGrant.amount,
  }) {
    if (durable <= 0) return incoming;
    if (incoming <= 0) return durable;
    if (incoming == grantAmount && durable < grantAmount) return durable;
    return incoming;
  }

  static Future<void> persistBalances({
    required SharedPreferences prefs,
    required String uid,
    int? share,
    int? diamond,
    int? value,
  }) async {
    if (uid.isEmpty) return;
    rememberInMemory(uid: uid, share: share, diamond: diamond, value: value);
    if (share != null && share >= 0) {
      await prefs.setInt(shareKey(uid), share);
    }
    if (diamond != null && diamond >= 0) {
      await prefs.setInt(diamondKey(uid), diamond);
    }
    if (value != null && value >= 0) {
      await prefs.setInt(valueKey(uid), value);
    }
  }

  /// Resolve Firestore SHARE against the durable local ledger.
  ///
  /// Incoming cannot climb back over a recorded spend except a small harvest
  /// bump. A harvest-sized drop below durable is treated as a stale remote
  /// missing the local credit (keep durable). Spend-sized drops still apply.
  static int applyShareCeiling({
    required int incomingShare,
    required int durableShare,
    int harvestSlack = harvestSlack,
  }) {
    if (incomingShare > durableShare) {
      final bump = incomingShare - durableShare;
      if (bump <= harvestSlack) return incomingShare;
      return durableShare;
    }
    final drop = durableShare - incomingShare;
    if (drop > 0 && drop <= harvestSlack) return durableShare;
    return incomingShare;
  }

  /// In-session / prefs hydrate: lift an empty or stale-low wallet up to the
  /// durable ledger, but do not clamp a harvest-sized in-memory credit down.
  static int resolveHydratedShare({
    required int currentShare,
    required int durableShare,
    int harvestSlack = harvestSlack,
  }) {
    if (currentShare <= 0) return durableShare;
    if (currentShare < durableShare) return durableShare;
    if (currentShare > durableShare + harvestSlack) return durableShare;
    return currentShare;
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
    final prefsShare = prefs.getInt(shareKey(uid));
    final cachedShare = _share[uid];
    final int? share;
    if (prefsShare != null && cachedShare != null) {
      share = applyShareCeiling(
        incomingShare: prefsShare,
        durableShare: cachedShare,
      );
    } else {
      share = cachedShare ?? prefsShare;
    }
    final prefsDia = prefs.getInt(diamondKey(uid));
    final cachedDia = _diamond[uid];
    final int? diamond;
    if (prefsDia != null && cachedDia != null) {
      diamond = resolveDurableCurrency(
        incoming: prefsDia,
        durable: cachedDia,
      );
    } else {
      diamond = cachedDia ?? prefsDia;
    }
    final prefsValue = prefs.getInt(valueKey(uid));
    final cachedValue = _value[uid];
    final int? value;
    if (prefsValue != null && cachedValue != null) {
      value = resolveDurableCurrency(
        incoming: prefsValue,
        durable: cachedValue,
      );
    } else {
      value = cachedValue ?? prefsValue;
    }
    final paid = parseIdList(prefs.getStringList(paidJoinKey(uid)));
    final history = parseHistory(prefs.getString(historyKey(uid)));
    rememberInMemory(
      uid: uid,
      share: share,
      diamond: diamond,
      value: value,
      paidIds: paid,
      history: history,
    );
    return DebugLocalWalletSnapshot(
      share: share,
      diamond: diamond,
      value: value,
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

  static const harvestHistoryTitle = '워킹챌린지 코인 줍기';
  static const hofValueDonationTitle = '명예의 전당 기부 완료 🕊️';
  static const fundingValueDonationTitle = '유니세프 글로벌 기부 펀딩 참여 🕊️';

  /// Append a client receipt (VALUE donation, etc.) without touching SHARE.
  /// History → payment history merges this with Firestore.
  static Future<void> recordClientHistory({
    required SharedPreferences prefs,
    required String uid,
    required String title,
    required int amount,
    required String assetType,
  }) async {
    if (uid.isEmpty || title.isEmpty || amount == 0) return;
    final prefix = switch (assetType) {
      'DIA' => 'TX_DIA_LOCAL_',
      'VALUE' => 'TX_VALUE_LOCAL_',
      _ => 'TX_SHARE_LOCAL_',
    };
    final tx = DebugLocalShareTx(
      id: '$prefix${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      assetType: assetType,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    final history = [tx, ...cachedHistory(uid)].take(40).toList();
    rememberInMemory(uid: uid, history: history);
    await prefs.setString(
      historyKey(uid),
      jsonEncode(history.map((row) => row.toJson()).toList()),
    );
  }

  /// Debug USB: persist a walking harvest so Home / 누적 통장 keep the SHARE
  /// after Jena fail, grant re-hydrate, or process restart.
  static Future<void> recordHarvestCredit({
    required SharedPreferences prefs,
    required String uid,
    required int shareBalanceAfter,
    required int credited,
  }) async {
    if (uid.isEmpty || shareBalanceAfter < 0 || credited <= 0) return;
    final tx = DebugLocalShareTx(
      id: 'TX_SHARE_HARVEST_${DateTime.now().millisecondsSinceEpoch}',
      title: harvestHistoryTitle,
      amount: credited,
      assetType: 'SHARE',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    final history = [tx, ...cachedHistory(uid)].take(40).toList();
    rememberInMemory(
      uid: uid,
      share: shareBalanceAfter,
      history: history,
    );
    await prefs.setInt(shareKey(uid), shareBalanceAfter);
    await prefs.setString(
      historyKey(uid),
      jsonEncode(history.map((row) => row.toJson()).toList()),
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
