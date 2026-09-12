import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../shop_inventory_store.dart';

/// 상점 탭(src-13) · 보관함(src-20) 공용 인벤토리 / 펀딩 진행률.
class ShopTabState {
  const ShopTabState({
    this.cprCount = 0,
    this.safeGuardCount = 0,
    this.starBoostCount = 0,
    this.sharePackCount = 0,
    this.fundingProgress = 0.85,
    this.totalDonatedValue = 0,
  });

  final int cprCount;
  final int safeGuardCount;
  final int starBoostCount;
  final int sharePackCount;
  final double fundingProgress;
  final int totalDonatedValue;

  bool get hasOwnedItems =>
      cprCount > 0 ||
      safeGuardCount > 0 ||
      starBoostCount > 0 ||
      sharePackCount > 0;

  ShopInventorySnapshot get inventory => ShopInventorySnapshot(
        cprCount: cprCount,
        safeGuardCount: safeGuardCount,
        starBoostCount: starBoostCount,
        sharePackCount: sharePackCount,
      );

  ShopTabState copyWith({
    int? cprCount,
    int? safeGuardCount,
    int? starBoostCount,
    int? sharePackCount,
    double? fundingProgress,
    int? totalDonatedValue,
  }) {
    return ShopTabState(
      cprCount: cprCount ?? this.cprCount,
      safeGuardCount: safeGuardCount ?? this.safeGuardCount,
      starBoostCount: starBoostCount ?? this.starBoostCount,
      sharePackCount: sharePackCount ?? this.sharePackCount,
      fundingProgress: fundingProgress ?? this.fundingProgress,
      totalDonatedValue: totalDonatedValue ?? this.totalDonatedValue,
    );
  }
}

enum ShopItemSku { cpr, safeGuard, starBoost, sharePack }

/// 홈 지갑 카드 → 상점 영역 포커스 (아이템 탭 / 기부 펀딩).
enum StoreFocus {
  items,
  donate;

  static StoreFocus? tryParse(Object? raw) {
    if (raw is StoreFocus) return raw;
    final key = raw?.toString().trim().toLowerCase();
    return switch (key) {
      'items' || 'item' || 'dia' || 'diamond' => StoreFocus.items,
      'donate' || 'donation' || 'value' || 'funding' => StoreFocus.donate,
      _ => null,
    };
  }
}

/// 셸 탭이 IndexedStack으로 재사용될 때도 포커스를 전달한다.
class StoreFocusNotifier extends Notifier<StoreFocus?> {
  @override
  StoreFocus? build() => null;

  void setFocus(StoreFocus? focus) => state = focus;
}

final storeFocusProvider =
    NotifierProvider<StoreFocusNotifier, StoreFocus?>(StoreFocusNotifier.new);

class ShopTabNotifier extends Notifier<ShopTabState> {
  static const donateValueAmount = 500;
  static const itemDiaCost = 30;
  static const sharePackShareReward = 10000;

  @override
  ShopTabState build() {
    ref.listen(authStateChangesProvider, (_, next) {
      unawaited(_hydrate());
    });
    unawaited(_hydrate());
    return const ShopTabState();
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

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      restoreInventory(ShopInventoryStore.hydrate(prefs, uid: _uid()));
    } catch (e) {
      debugPrint('shop inventory hydrate: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await ShopInventoryStore.persist(
        prefs: prefs,
        inventory: state.inventory,
        uid: _uid(),
      );
    } catch (e) {
      debugPrint('shop inventory persist: $e');
    }
  }

  void restoreInventory(ShopInventorySnapshot snap) {
    if (!snap.hasOwnedItems && !state.hasOwnedItems) return;
    final merged = ShopInventorySnapshot.mergeMax(state.inventory, snap);
    if (merged.cprCount == state.cprCount &&
        merged.safeGuardCount == state.safeGuardCount &&
        merged.starBoostCount == state.starBoostCount &&
        merged.sharePackCount == state.sharePackCount) {
      return;
    }
    state = state.copyWith(
      cprCount: merged.cprCount,
      safeGuardCount: merged.safeGuardCount,
      starBoostCount: merged.starBoostCount,
      sharePackCount: merged.sharePackCount,
    );
  }

  void addDonation(int valueAmount) {
    if (valueAmount <= 0) return;
    final nextProgress =
        (state.fundingProgress + (valueAmount / 10000)).clamp(0.0, 1.0);
    state = state.copyWith(
      fundingProgress: nextProgress,
      totalDonatedValue: state.totalDonatedValue + valueAmount,
    );
  }

  void addItem(ShopItemSku sku, {int qty = 1}) {
    if (qty <= 0) return;
    switch (sku) {
      case ShopItemSku.cpr:
        state = state.copyWith(cprCount: state.cprCount + qty);
      case ShopItemSku.safeGuard:
        state = state.copyWith(safeGuardCount: state.safeGuardCount + qty);
      case ShopItemSku.starBoost:
        state = state.copyWith(starBoostCount: state.starBoostCount + qty);
      case ShopItemSku.sharePack:
        state = state.copyWith(sharePackCount: state.sharePackCount + qty);
    }
    unawaited(_persist());
  }

  /// Firestore `hasCPR` 복원 — 로컬 인벤토리가 비어 있을 때만 채운다.
  void restoreCprOwned() {
    if (state.cprCount > 0) return;
    state = state.copyWith(cprCount: 1);
    unawaited(_persist());
  }

  bool useItem(ShopItemSku sku) {
    switch (sku) {
      case ShopItemSku.cpr:
        if (state.cprCount <= 0) return false;
        state = state.copyWith(cprCount: state.cprCount - 1);
      case ShopItemSku.safeGuard:
        if (state.safeGuardCount <= 0) return false;
        state = state.copyWith(safeGuardCount: state.safeGuardCount - 1);
      case ShopItemSku.starBoost:
        if (state.starBoostCount <= 0) return false;
        state = state.copyWith(starBoostCount: state.starBoostCount - 1);
      case ShopItemSku.sharePack:
        if (state.sharePackCount <= 0) return false;
        state = state.copyWith(sharePackCount: state.sharePackCount - 1);
    }
    unawaited(_persist());
    return true;
  }
}

final shopTabProvider = NotifierProvider<ShopTabNotifier, ShopTabState>(
  ShopTabNotifier.new,
);
