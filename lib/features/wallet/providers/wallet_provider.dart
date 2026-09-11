import 'dart:async' show Completer, unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/wallet_model.dart';

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

  @override
  WalletState build() {
    _ready = Completer<void>();
    ref.onDispose(() {
      if (!_ready.isCompleted) _ready.complete();
    });
    ref.listen<AsyncValue<WalletModel>>(activeWalletProvider, (_, next) {
      next.whenData(_syncFromRemote);
    });
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
    state = WalletState.fromModel(model);
    if (!_ready.isCompleted) _ready.complete();
  }

  /// Firestore 스냅샷으로 잔액을 덮어쓴다. 재설치·기기 변경 복원용.
  void replaceFromRemote(WalletModel model) => _syncFromRemote(model);

  /// Walking-challenge harvest: update SHARE only. DIA/VALUE stay as-is.
  void applyShareFromServer({
    int? shareBalance,
    int shareCredited = 0,
  }) {
    if (shareBalance != null) {
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
