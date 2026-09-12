import 'dart:async' show Completer, unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/wallet_model.dart';
import '../debug_local_wallet_store.dart';

/// 전역 재화 표시 — Firestore [activeWalletProvider]가 원장이다.
/// SharedPreferences SHARE/DIA/VALUE 값은 표시에 쓰지 않는다.
class WalletState {
  const WalletState({
    this.shareBalance = 0,
    this.diamondBalance = 0,
    this.valueBalance = 0,
  });

  final int shareBalance;
  final int diamondBalance;
  final int valueBalance;

  bool get isEmpty =>
      shareBalance <= 0 && diamondBalance <= 0 && valueBalance <= 0;

  WalletState copyWith({
    int? shareBalance,
    int? diamondBalance,
    int? valueBalance,
  }) {
    return WalletState(
      shareBalance: shareBalance ?? this.shareBalance,
      diamondBalance: diamondBalance ?? this.diamondBalance,
      valueBalance: valueBalance ?? this.valueBalance,
    );
  }

  factory WalletState.fromModel(WalletModel model) {
    return WalletState(
      shareBalance: model.shareBalance,
      diamondBalance: model.diamondBalance,
      valueBalance: model.valueTokenBalance,
    );
  }
}

class WalletNotifier extends Notifier<WalletState> {
  Completer<void> _ready = Completer<void>();
  int? _durableDebugShare;
  int? _durableDia;
  int? _durableValue;

  @override
  WalletState build() {
    _ready = Completer<void>();
    _durableDebugShare = null;
    _durableDia = null;
    _durableValue = null;
    ref.onDispose(() {
      if (!_ready.isCompleted) _ready.complete();
    });
    ref.listen<AsyncValue<WalletModel>>(activeWalletProvider, (_, next) {
      next.whenData(_syncFromRemote);
    });
    ref.listen(authStateChangesProvider, (_, next) {
      final uid = next.asData?.value?.uid;
      if (uid != null && uid.isNotEmpty) {
        unawaited(_hydrateDurableBalances());
      }
    });
    unawaited(_hydrateDurableBalances());
    final existing = ref.read(activeWalletProvider).asData?.value;
    if (existing != null) {
      Future<void>.microtask(() {
        if (!_ready.isCompleted) _ready.complete();
      });
      return WalletState.fromModel(existing);
    }
    unawaited(_markReady());
    return const WalletState();
  }

  /// Debug USB: keep the post-spend SHARE so Firestore 1M cannot wipe it.
  void rememberDurableDebugShare(int share) {
    if (!kDebugMode || share < 0) return;
    _durableDebugShare = share;
  }

  void rememberDurableWallet({
    int? share,
    int? diamond,
    int? value,
  }) {
    if (share != null && share >= 0 && kDebugMode) {
      _durableDebugShare = share;
    }
    if (diamond != null && diamond >= 0) _durableDia = diamond;
    if (value != null && value >= 0) _durableValue = value;
  }

  String _uid() {
    try {
      final auth = ref.read(authStateChangesProvider).asData?.value?.uid ?? '';
      if (auth.isNotEmpty) return auth;
      return ref.read(persistedAuthSessionProvider)?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _hydrateDurableBalances() async {
    final uid = _uid();
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snap = DebugLocalWalletStore.hydrateFromPrefs(prefs, uid);
      if (kDebugMode && snap.share != null) {
        final current = state.shareBalance > (_durableDebugShare ?? 0)
            ? state.shareBalance
            : (_durableDebugShare ?? state.shareBalance);
        final resolved = DebugLocalWalletStore.resolveHydratedShare(
          currentShare: current,
          durableShare: snap.share!,
        );
        rememberDurableDebugShare(resolved);
        if (state.shareBalance != resolved) {
          state = state.copyWith(shareBalance: resolved);
        }
      }
      if (snap.diamond != null && snap.diamond! > 0) {
        final resolved = DebugLocalWalletStore.resolveDurableCurrency(
          incoming: state.diamondBalance,
          durable: snap.diamond!,
        );
        rememberDurableWallet(diamond: resolved);
        if (state.diamondBalance != resolved) {
          state = state.copyWith(diamondBalance: resolved);
        }
      }
      if (snap.value != null && snap.value! > 0) {
        final resolved = DebugLocalWalletStore.resolveDurableCurrency(
          incoming: state.valueBalance,
          durable: snap.value!,
        );
        rememberDurableWallet(value: resolved);
        if (state.valueBalance != resolved) {
          state = state.copyWith(valueBalance: resolved);
        }
      }
    } catch (e) {
      debugPrint('hydrateDurableBalances: $e');
    }
  }

  Future<void> _markReady() async {
    if (!_ready.isCompleted) _ready.complete();
  }

  /// Kept for callers that await hydration. Wallet display comes from Firestore.
  Future<void> initWalletData() async {
    await _ready.future;
  }

  void _applyAfterReady(void Function() apply) {
    unawaited(() async {
      await _ready.future;
      apply();
    }());
  }

  void _syncFromRemote(WalletModel model) {
    state = mergeRemote(
      state,
      WalletState.fromModel(model),
      durableShare: _durableDebugShare,
      durableDiamond: _durableDia,
      durableValue: _durableValue,
    );
    if (!_ready.isCompleted) _ready.complete();
  }

  /// Debug local harvest may sit a few SHARE above a stale Firestore snapshot.
  /// Join/validate debits (tens of thousands of SHARE) must still apply.
  static const debugHarvestShareSlack = 60;

  /// Largest single join/sponsor SHARE spend we still treat as a debit
  /// (20 km entry 200k + 50k personal sponsor). Bigger SHARE-only drops are
  /// the debug grant vs Jena harvest wipe (1M → 51).
  static const debugMaxSpendShareDrop = 250000;

  /// Firestore is the ledger, but SHARE-only harvest snapshots (DIA/VALUE 0)
  /// must not wipe a debug grant or in-memory harvest credit.
  static WalletState mergeRemote(
    WalletState current,
    WalletState incoming, {
    int? durableShare,
    int? durableDiamond,
    int? durableValue,
  }) {
    if (incoming.isEmpty && !current.isEmpty) {
      return current;
    }
    var share = incoming.shareBalance;
    if (shouldPreserveDebugShare(
      currentShare: current.shareBalance,
      incomingShare: incoming.shareBalance,
      incomingDiamond: incoming.diamondBalance,
      incomingValue: incoming.valueBalance,
    )) {
      share = current.shareBalance;
    }
    if (durableShare != null) {
      share = DebugLocalWalletStore.applyShareCeiling(
        incomingShare: share,
        durableShare: durableShare,
      );
    } else if (DebugLocalWalletStore.shouldRejectHydrateRestore(
      currentShare: current.shareBalance,
      incomingShare: incoming.shareBalance,
    )) {
      share = current.shareBalance;
    }
    var diamond = incoming.diamondBalance == 0 && current.diamondBalance > 0
        ? current.diamondBalance
        : incoming.diamondBalance;
    if (durableDiamond != null) {
      diamond = DebugLocalWalletStore.resolveDurableCurrency(
        incoming: diamond,
        durable: durableDiamond,
      );
    }
    var value = incoming.valueBalance == 0 && current.valueBalance > 0
        ? current.valueBalance
        : incoming.valueBalance;
    if (durableValue != null) {
      value = DebugLocalWalletStore.resolveDurableCurrency(
        incoming: value,
        durable: durableValue,
      );
    }
    return WalletState(
      shareBalance: share,
      diamondBalance: diamond,
      valueBalance: value,
    );
  }

  static bool shouldPreserveDebugShare({
    required int currentShare,
    required int incomingShare,
    int incomingDiamond = 0,
    int incomingValue = 0,
  }) {
    if (!kDebugMode) return false;
    final drop = currentShare - incomingShare;
    if (drop <= 0) return false;
    if (drop <= debugHarvestShareSlack) return true;
    // Harvest may send SHARE only (DIA/VALUE 0) far below the 1M grant.
    // Join/sponsor remainders are spend-sized even when the nested wallet
    // map was previously replaced with SHARE-only (debug harvest write).
    if (incomingDiamond == 0 && incomingValue == 0) {
      return drop > debugMaxSpendShareDrop;
    }
    return false;
  }

  /// Firestore 스냅샷으로 잔액을 덮어쓴다. 재설치·기기 변경 복원용.
  void replaceFromRemote(WalletModel model) => _syncFromRemote(model);

  /// Walking-challenge harvest: update SHARE only. DIA/VALUE stay as-is.
  void applyShareFromServer({
    int? shareBalance,
    int shareCredited = 0,
  }) {
    if (shareBalance != null) {
      // Debug local grant/harvest may already be ahead of Jena. Do not
      // replace a higher local SHARE with a stale server snapshot.
      if (kDebugMode && shareBalance < state.shareBalance) {
        if (shareCredited > 0) {
          state = state.copyWith(
            shareBalance: state.shareBalance + shareCredited,
          );
          _rememberHarvestDurable();
        }
        return;
      }
      // Jena wallet snapshot can still be the pre-join 1M. Only take a
      // harvest-sized bump; never re-apply the grant over a spent ledger.
      if (kDebugMode &&
          state.shareBalance > 0 &&
          shareBalance > state.shareBalance + DebugLocalWalletStore.harvestSlack) {
        if (shareCredited > 0) {
          state = state.copyWith(
            shareBalance: state.shareBalance + shareCredited,
          );
        }
        _rememberHarvestDurable();
        return;
      }
      state = state.copyWith(shareBalance: shareBalance);
      _rememberHarvestDurable();
      return;
    }
    if (shareCredited <= 0) return;
    state = state.copyWith(shareBalance: state.shareBalance + shareCredited);
    _rememberHarvestDurable();
  }

  void _rememberHarvestDurable() {
    if (!kDebugMode) return;
    _durableDebugShare = state.shareBalance;
    final uid = ref.read(authStateChangesProvider).asData?.value?.uid ?? '';
    if (uid.isNotEmpty) {
      DebugLocalWalletStore.rememberInMemory(
        uid: uid,
        share: state.shareBalance,
      );
    }
  }

  /// Debug test grant / full snapshot. Null fields keep the current value.
  /// Persists the granted/spent ledger so kill + relaunch does not reset
  /// to empty after a Firestore permission-denied write.
  void applyWalletSnapshot({
    int? shareBalance,
    int? diamondBalance,
    int? valueBalance,
  }) {
    state = state.copyWith(
      shareBalance: shareBalance,
      diamondBalance: diamondBalance,
      valueBalance: valueBalance,
    );
    _rememberBalancesDurable();
  }

  /// src-14 PG 결제 완료 시 SHARE 충전.
  void chargeShare(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(shareBalance: state.shareBalance + amount);
    });
  }

  /// 방 개설·참가비 차감 (스펙명 subtractShare).
  void subtractShare(int amount) => deductShare(amount);

  void deductShare(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(
        shareBalance: (state.shareBalance - amount).clamp(0, 1 << 31),
      );
    });
  }

  /// Tournament join / personal SHARE sponsor spend. Synchronous so Home
  /// SHARE drops before a Firestore snapshot can merge against the
  /// pre-debit balance. DIA/VALUE are unchanged.
  void applyEntryFeeDebit(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(
      shareBalance: (state.shareBalance - amount).clamp(0, 1 << 31),
    );
    if (kDebugMode) {
      _durableDebugShare = state.shareBalance;
    }
    _rememberBalancesDurable();
  }

  void creditDia(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(diamondBalance: state.diamondBalance + amount);
      _rememberBalancesDurable();
    });
  }

  void creditValue(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(valueBalance: state.valueBalance + amount);
      _rememberBalancesDurable();
    });
  }

  void debitDia(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(
      diamondBalance: (state.diamondBalance - amount).clamp(0, 1 << 31),
    );
    _rememberBalancesDurable();
  }

  void debitValue(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(
      valueBalance: (state.valueBalance - amount).clamp(0, 1 << 31),
    );
    _rememberBalancesDurable();
  }

  void _rememberBalancesDurable() {
    rememberDurableWallet(
      share: kDebugMode ? state.shareBalance : null,
      diamond: state.diamondBalance,
      value: state.valueBalance,
    );
    final uid = _uid();
    if (uid.isEmpty) return;
    DebugLocalWalletStore.rememberInMemory(
      uid: uid,
      share: kDebugMode ? state.shareBalance : null,
      diamond: state.diamondBalance,
      value: state.valueBalance,
    );
    unawaited(_persistDurablePrefs(uid));
  }

  Future<void> _persistDurablePrefs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await DebugLocalWalletStore.persistBalances(
        prefs: prefs,
        uid: uid,
        share: kDebugMode ? state.shareBalance : null,
        diamond: state.diamondBalance,
        value: state.valueBalance,
      );
    } catch (e) {
      debugPrint('persistDurablePrefs: $e');
    }
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);
