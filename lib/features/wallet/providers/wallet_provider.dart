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

  @override
  WalletState build() {
    _ready = Completer<void>();
    _durableDebugShare = null;
    ref.onDispose(() {
      if (!_ready.isCompleted) _ready.complete();
    });
    ref.listen<AsyncValue<WalletModel>>(activeWalletProvider, (_, next) {
      next.whenData(_syncFromRemote);
    });
    ref.listen(authStateChangesProvider, (_, next) {
      final uid = next.asData?.value?.uid;
      if (uid != null && uid.isNotEmpty) {
        unawaited(_hydrateDurableDebugShare());
      }
    });
    unawaited(_hydrateDurableDebugShare());
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

  Future<void> _hydrateDurableDebugShare() async {
    if (!kDebugMode) return;
    final uid = ref.read(authStateChangesProvider).asData?.value?.uid ?? '';
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snap = DebugLocalWalletStore.hydrateFromPrefs(prefs, uid);
      final share = snap.share;
      if (share == null) return;
      rememberDurableDebugShare(share);
      if (state.shareBalance <= 0 || state.shareBalance > share) {
        state = state.copyWith(shareBalance: share);
      }
    } catch (e) {
      debugPrint('hydrateDurableDebugShare: $e');
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
    return WalletState(
      shareBalance: share,
      diamondBalance: incoming.diamondBalance == 0 && current.diamondBalance > 0
          ? current.diamondBalance
          : incoming.diamondBalance,
      valueBalance: incoming.valueBalance == 0 && current.valueBalance > 0
          ? current.valueBalance
          : incoming.valueBalance,
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
        }
        return;
      }
      state = state.copyWith(shareBalance: shareBalance);
      return;
    }
    if (shareCredited <= 0) return;
    state = state.copyWith(shareBalance: state.shareBalance + shareCredited);
  }

  /// Debug test grant / full snapshot. Null fields keep the current value.
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

  /// Tournament join / entry-fee spend. Synchronous so Home SHARE drops
  /// before a Firestore snapshot can merge against the pre-debit balance.
  /// DIA/VALUE are unchanged.
  void applyEntryFeeDebit(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(
      shareBalance: (state.shareBalance - amount).clamp(0, 1 << 31),
    );
    if (kDebugMode) {
      _durableDebugShare = state.shareBalance;
    }
  }

  void creditDia(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(diamondBalance: state.diamondBalance + amount);
    });
  }

  void creditValue(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(valueBalance: state.valueBalance + amount);
    });
  }

  void debitDia(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(
        diamondBalance: (state.diamondBalance - amount).clamp(0, 1 << 31),
      );
    });
  }

  void debitValue(int amount) {
    if (amount <= 0) return;
    _applyAfterReady(() {
      state = state.copyWith(
        valueBalance: (state.valueBalance - amount).clamp(0, 1 << 31),
      );
    });
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);
