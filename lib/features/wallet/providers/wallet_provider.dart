import 'dart:async' show Completer, unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/wallet_model.dart';

/// 전역 재화 상태 — SHARE / DIA / VALUE.
///
/// Firestore [activeWalletProvider]와 양방향 싱크하며,
/// src-14 충전·방 개설 차감·상점 기부/구매는 이 Notifier를 통해 UI에 즉시 반영된다.
/// 로컬 SharedPreferences(`SHARE` / `DIA` / `VALUE`)가 재시작 후에도 총액을 유지한다.
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
  static const shareKey = 'SHARE';
  static const diaKey = 'DIA';
  static const valueKey = 'VALUE';

  Completer<void> _ready = Completer<void>();
  var _hydratedFromPrefs = false;
  var _cloudWallet = WalletModel.empty();

  @override
  WalletState build() {
    _ready = Completer<void>();
    _hydratedFromPrefs = false;
    ref.onDispose(() {
      if (!_ready.isCompleted) _ready.complete();
    });
    ref.listen<AsyncValue<WalletModel>>(activeWalletProvider, (_, next) {
      next.whenData(_syncFromRemote);
    });
    unawaited(initWalletData());
    return const WalletState();
  }

  /// 앱 시작 시 SharedPreferences에서 SHARE / DIA / VALUE를 복구한다.
  Future<void> initWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final share = prefs.getInt(shareKey) ?? 0;
      final dia = prefs.getInt(diaKey) ?? 0;
      final value = prefs.getInt(valueKey) ?? 0;
      _hydratedFromPrefs = true;
      if (!_isRemoteEmpty(_cloudWallet)) {
        state = WalletState.fromModel(_cloudWallet);
      } else {
        state = WalletState(
          shareBalance: share < 0 ? 0 : share,
          diamondBalance: dia < 0 ? 0 : dia,
          valueBalance: value < 0 ? 0 : value,
        );
      }
    } catch (e, st) {
      debugPrint('initWalletData: $e\n$st');
      _hydratedFromPrefs = true;
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  Future<void> _persistWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(shareKey, state.shareBalance);
      await prefs.setInt(diaKey, state.diamondBalance);
      await prefs.setInt(valueKey, state.valueBalance);
    } catch (e, st) {
      debugPrint('_persistWallet: $e\n$st');
    }
  }

  void _applyAfterReady(void Function() apply) {
    unawaited(() async {
      await _ready.future;
      apply();
      await _persistWallet();
    }());
  }

  bool _isRemoteEmpty(WalletModel model) {
    return model.shareBalance <= 0 &&
        model.diamondBalance <= 0 &&
        model.valueTokenBalance <= 0;
  }

  void _syncFromRemote(WalletModel model) {
    _cloudWallet = model;
    if (_isRemoteEmpty(model)) return;
    state = WalletState.fromModel(model);
    if (_hydratedFromPrefs) unawaited(_persistWallet());
  }

  /// Firestore 스냅샷으로 잔액을 덮어쓴다. 재설치·기기 변경 복원용.
  void replaceFromRemote(WalletModel model) => _syncFromRemote(model);

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
