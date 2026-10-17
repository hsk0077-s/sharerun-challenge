import '../features/iap/widgets/dia_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/api/api_exception.dart';
import '../data/models/shop_item_model.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../features/iap/models/coach_plus_product.dart';
import '../features/accessories/accessory_catalog.dart';
import '../features/accessories/dressed_mascot.dart';
import '../features/iap/models/dia_pack_product.dart';
import '../features/iap/widgets/coach_plus_upsell_sheet.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/shop/providers/shop_catalog_provider.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/shop/widgets/accessory_shop_grid.dart';
import '../features/shop/widgets/store_look.dart';
import '../features/shop/widgets/donation_match_contribution.dart';
import '../features/shop/streak_item_message.dart';
import '../features/wallet/providers/wallet_provider.dart';
import 'battle_pass_screen.dart';
import 'dia_pack_store_screen.dart';
import 'share_dia_exchange_screen.dart';
import 'item_inventory_screen.dart';

/// src-13 앱내 상점 및 글로벌 기부 펀딩.
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key, this.initialFocus});

  /// 홈 지갑 카드에서 DIA(아이템) / VALUE(기부 펀딩) 진입 시 영역 포커스.
  final StoreFocus? initialFocus;

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  static const _currentNavIndex = DashboardTabNavigation.shop;
  var _tab = _StoreTab.recommended;
  final _fundingKey = GlobalKey();
  var _buyBusy = false;

  @override
  void initState() {
    super.initState();
    final first = widget.initialFocus ?? ref.read(storeFocusProvider);
    if (first == StoreFocus.items) _tab = _StoreTab.items;
    if (first == StoreFocus.donate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFunding());
    }
  }

  @override
  void didUpdateWidget(StoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFocus != widget.initialFocus &&
        widget.initialFocus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyFocus(widget.initialFocus!);
      });
    }
  }

  /// 홈·마이에서 DIA / VALUE를 눌러 들어오면 해당 탭을 바로 보여 준다.
  void _applyFocus(StoreFocus focus) {
    switch (focus) {
      case StoreFocus.items:
        if (_tab != _StoreTab.items) setState(() => _tab = _StoreTab.items);
      case StoreFocus.donate:
        if (_tab != _StoreTab.recommended) {
          setState(() => _tab = _StoreTab.recommended);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFunding());
    }
  }

  void _scrollToFunding() {
    final ctx = _fundingKey.currentContext;
    if (!mounted || ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  String _format(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    DashboardTabNavigation.go(context, index);
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDonate() {
    _toast(
      '이 화면에서는 VALUE를 차감하지 않습니다. '
      '기부는 서버 원장에 기록된 뒤에만 잔액이 줄어듭니다.',
    );
  }

  ShopItemModel _shopItem(String id) {
    return ShopItemModel.catalog.firstWhere((item) => item.id == id);
  }

  int _diaCost(String id) {
    final catalog = ref.watch(shopCatalogProvider).asData?.value;
    final server = catalog?[id];
    if (server != null) return server;
    return _shopItem(id).diamondCost;
  }

  int _shareCost(String id) {
    final server = ref.watch(shopSharePriceProvider).asData?.value[id];
    if (server != null && server > 0) return server;
    return _shopItem(id).shareCost;
  }

  int _valueCost(String id) {
    final server = ref.watch(shopValuePriceProvider).asData?.value[id];
    if (server != null && server > 0) return server;
    return _shopItem(id).valueCost;
  }

  Future<void> _onBuyItem(ShopItemModel item) async {
    if (_buyBusy) return;
    _buyBusy = true;
    try {
      final result = await ref
          .read(securedActionApiClientProvider)
          .purchaseShopItem(item.id);
      if (!mounted) return;
      ref.read(walletProvider.notifier).applyWalletSnapshot(
            shareBalance: result.shareBalance,
            diamondBalance: result.diamondBalance,
            valueBalance: result.valueTokenBalance,
          );
      _toast(
        result.status == 'already_purchased' ||
                result.status == 'already_matched'
            ? item.valueCost > 0
                ? '이미 처리된 구매입니다. VALUE는 한 번만 차감됩니다.'
                : item.shareCost > 0
                    ? '이미 처리된 구매입니다. SHARE는 한 번만 차감됩니다.'
                    : '이미 처리된 구매입니다. DIA는 한 번만 차감됩니다.'
            : item.id == 'donation_match'
                ? '기부 매칭을 기록했습니다. 회사 명의 기부에 내 이름이 함께 표시됩니다.'
                : '${item.title}을 구매했습니다.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(
        streakItemMessage(
          error,
          fallback: 'DIA가 부족합니다. 상점에서 구매해 주세요.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _toast('${item.title}을 구매하지 못했습니다.');
    } finally {
      _buyBusy = false;
    }
  }

  void _onOpenInventory() {
    AppRouteNav.push<void>(
      context,
      RouteNames.itemInventory,
      materialBuilder: (_) => const ItemInventoryScreen(),
    );
  }

  void _openDiaExchange() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.push(RouteNames.shareToDia);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShareDiaExchangeScreen()),
    );
  }

  void _openDiaPacks() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.push(RouteNames.diaPackStore);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DiaPackStoreScreen()),
    );
  }

  void _openBattlePass() {
    AppRouteNav.push<void>(
      context,
      RouteNames.battlePass,
      materialBuilder: (_) => const BattlePassScreen(),
    );
  }

  static String _won(int value) => '${_groupDigits(value)}원';

  static String _groupDigits(int value) => value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  /// '6,900원' 같은 문구에서 숫자만 뽑는다. 못 뽑으면 0.
  static int _digits(String label) =>
      int.tryParse(label.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// 연간 요금이 월간 12개월 값보다 몇 % 싼지. 계산할 수 없으면 null.
  static int? _yearlyDiscountPct() {
    final monthly = _digits(CoachPlusPlan.monthly.fallbackPriceLabel);
    final yearly = _digits(CoachPlusPlan.yearly.fallbackPriceLabel);
    if (monthly <= 0 || yearly <= 0) return null;
    final pct = ((1 - yearly / (monthly * 12)) * 100).round();
    return pct > 0 ? pct : null;
  }

  Widget _tile({
    required String id,
    required IconData icon,
    required String name,
  }) {
    return StoreItemTile(
      icon: icon,
      name: name,
      cost: '${_diaCost(id)}',
      onTap: () => _onBuyItem(_shopItem(id)),
    );
  }

  Widget _row({
    required String id,
    required IconData icon,
    required String name,
    required int owned,
    String sub = '',
    String? plainLabel,
  }) {
    return StoreItemRow(
      icon: icon,
      name: name,
      sub: sub,
      owned: owned,
      cost: plainLabel == null ? '${_diaCost(id)}' : null,
      plainLabel: plainLabel,
      onTap: () => _onBuyItem(_shopItem(id)),
    );
  }

  /// 추천 탭: Coach+, 다이아 충전, 러닝 아이템, 배틀런 패스, 꾸미기, 기부 펀딩.
  List<Widget> _recommendedTab(
      ServerShopInventory inventory, ShopTabState shop) {
    final tokens = context.srcTokens;
    final packs = DiaPackProduct.catalog.where((p) => p.totalDia > 12).toList();
    final featured = packs.length >= 3 ? packs.sublist(0, 3) : packs;
    return [
      StoreCoachCard(
        monthlyLabel: CoachPlusPlan.monthly.fallbackPriceLabel,
        yearlyLabel: CoachPlusPlan.yearly.fallbackPriceLabel,
        yearlyDiscountPct: _yearlyDiscountPct(),
        onTap: () => CoachPlusUpsellSheet.show(context),
      ),
      StoreSectionLabel(
        '다이아 충전',
        more: '전체 보기',
        onMore: () => setState(() => _tab = _StoreTab.diamond),
      ),
      Row(
        children: [
          for (final (i, pack) in featured.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            StorePackCard(
              dia: '${pack.totalDia}',
              bonus: pack.bonusDia > 0 ? '+${pack.bonusDia} 보너스' : '',
              price: _won(pack.priceKrw),
              hot: pack.productId == 'dia_pack_130',
              onTap: _openDiaPacks,
            ),
          ],
        ],
      ),
      StoreSectionLabel(
        '러닝 아이템',
        more: '전체 보기',
        onMore: () => setState(() => _tab = _StoreTab.items),
      ),
      Row(
        children: [
          _tile(
            id: 'record_cpr_ticket',
            icon: Icons.healing_rounded,
            name: AppStrings.storeItemCpr,
          ),
          const SizedBox(width: 8),
          _tile(
            id: 'record_safe_guard',
            icon: Icons.shield_outlined,
            name: AppStrings.storeItemSafeGuard,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _tile(
            id: 'coach_one_point_ticket',
            icon: Icons.record_voice_over_rounded,
            name: AppStrings.storeItemCoachOnePoint,
          ),
          const SizedBox(width: 8),
          _tile(
            id: 'friend_ghost_pace',
            icon: Icons.directions_run_rounded,
            name: AppStrings.storeItemFriendGhost,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _tile(
            id: 'extra_entry_ticket',
            icon: Icons.confirmation_number_outlined,
            name: AppStrings.storeItemExtraEntry,
          ),
          const SizedBox(width: 8),
          _tile(
            id: 'crew_cheer_flag',
            icon: Icons.flag_rounded,
            name: AppStrings.storeItemCrewCheer,
          ),
        ],
      ),
      const StoreSectionLabel('배틀런 패스'),
      InkWell(
        key: const Key('store-battle-pass'),
        onTap: _openBattlePass,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tokens.colors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tokens.colors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt_rounded, color: tokens.colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '배틀런 챌린지 패스',
                      style: storeText(
                        16,
                        tokens.colors.ink,
                        w: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '시즌 보상 · 패스+',
                      style: storeText(12, tokens.colors.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: tokens.colors.muted,
              ),
            ],
          ),
        ),
      ),
      StoreSectionLabel(
        '꾸미기',
        more: '전체 보기',
        onMore: () => setState(() => _tab = _StoreTab.cosmetics),
      ),
      _CosmeticsPreviewRow(
        animal: _myAnimal(),
        onTap: () => setState(() => _tab = _StoreTab.cosmetics),
      ),
      KeyedSubtree(
        key: _fundingKey,
        child: const StoreSectionLabel('기부 펀딩'),
      ),
      _UnicefFundingCard(progress: shop.fundingProgress, onDonate: _onDonate),
      const DonationMatchContribution(),
    ];
  }

  /// 다이아 탭: 팩 목록(준비 중)과 SHARE로 교환.
  List<Widget> _diamondTab() {
    final tokens = context.srcTokens;
    final c = tokens.colors;
    return [
      const StoreSectionLabel('다이아 충전'),
      for (final pack in DiaPackProduct.catalog)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            key: Key('store-pack-${pack.productId}'),
            onTap: _openDiaPacks,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      pack.productId == 'dia_pack_130' ? c.primary : c.outline,
                  width: pack.productId == 'dia_pack_130' ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_outlined, size: 22, color: c.ink),
                          const SizedBox(width: 10),
                          Text(
                            _groupDigits(pack.totalDia),
                            style: storeText(22, c.ink, w: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          if (pack.bonusDia > 0)
                            Text(
                              '+${pack.bonusDia} 보너스',
                              style:
                                  storeText(12, c.primary, w: FontWeight.w800),
                            ),
                          if (pack.productId == 'dia_pack_130') ...[
                            const SizedBox(width: 8),
                            Text(
                              '인기',
                              style: storeText(
                                11,
                                c.primary,
                                w: FontWeight.w900,
                                ls: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _won(pack.priceKrw),
                        style: storeText(15, c.ink, w: FontWeight.w900),
                      ),
                      Text(
                        '준비 중',
                        style: storeText(11, c.muted, w: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      Text(
        'Play 상품이 열리면 구매할 수 있어요. 지금은 결제해도 DIA가 지급되지 않아요.',
        style: storeText(12, c.muted, h: 1.5),
      ),
      const StoreSectionLabel('SHARE로 교환'),
      InkWell(
        key: const Key('store-dia-exchange'),
        onTap: _openDiaExchange,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.outline),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_walk_rounded, size: 22, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHARE를 DIA로',
                      style: storeText(16, c.ink, w: FontWeight.w900),
                    ),
                    Text(
                      '1,200 SHARE = 1 DIA · 주간 한도 안에서 교환',
                      style: storeText(12, c.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: c.muted),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const DiaNoticeCard(),
    ];
  }

  /// 아이템 탭: 시안의 글머리별 한 줄 목록.
  List<Widget> _itemsTab(ServerShopInventory inventory) {
    return [
      const StoreSectionLabel('기록 지키기'),
      _row(
        id: 'record_cpr_ticket',
        icon: Icons.healing_rounded,
        name: AppStrings.storeItemCpr,
        owned: inventory.cprCount,
      ),
      _row(
        id: 'record_safe_guard',
        icon: Icons.shield_outlined,
        name: AppStrings.storeItemSafeGuard,
        owned: inventory.safeGuardCount,
      ),
      _row(
        id: 'rest_day_ticket',
        icon: Icons.bedtime_outlined,
        name: AppStrings.storeItemRestDay,
        sub: AppStrings.storeItemRestDayNote,
        owned: inventory.restDayCount,
        plainLabel: '${_format(_valueCost('rest_day_ticket'))} VALUE',
      ),
      const StoreSectionLabel('같이 달리기'),
      _row(
        id: 'coach_one_point_ticket',
        icon: Icons.record_voice_over_rounded,
        name: AppStrings.storeItemCoachOnePoint,
        owned: inventory.coachOnePointCount,
      ),
      _row(
        id: 'friend_ghost_pace',
        icon: Icons.directions_run_rounded,
        name: AppStrings.storeItemFriendGhost,
        sub: '10회 묶음 ${_diaCost('friend_ghost_pace_10pack')}',
        owned: inventory.friendGhostCount,
      ),
      _row(
        id: 'crew_cheer_flag',
        icon: Icons.flag_rounded,
        name: AppStrings.storeItemCrewCheer,
        owned: inventory.crewCheerCount,
      ),
      const StoreSectionLabel('대회'),
      _row(
        id: 'extra_entry_ticket',
        icon: Icons.confirmation_number_outlined,
        name: AppStrings.storeItemExtraEntry,
        sub: '3장 묶음 ${_diaCost('extra_entry_ticket_3pack')}',
        owned: inventory.extraEntryCount,
      ),
      StoreItemRow(
        icon: Icons.bolt_rounded,
        name: '배틀런 패스',
        sub: '시즌 보상 · 패스+',
        plainLabel: '보기',
        onTap: _openBattlePass,
      ),
      const StoreSectionLabel('걸음으로 얻기'),
      _row(
        id: 'boost_run',
        icon: Icons.rocket_launch_outlined,
        name: AppStrings.storeItemBoostRun,
        sub: AppStrings.storeItemBoostRunNote,
        owned: inventory.boostRunCount,
        plainLabel: '${_format(_shareCost('boost_run'))} SHARE',
      ),
      _row(
        id: 'step_incubator',
        icon: Icons.egg_outlined,
        name: AppStrings.storeItemStepIncubator,
        sub: AppStrings.storeItemStepIncubatorNote,
        owned: inventory.stepIncubatorCount,
        plainLabel: '${_format(_shareCost('step_incubator'))} SHARE',
      ),
      _row(
        id: 'donation_match',
        icon: Icons.favorite_border_rounded,
        name: AppStrings.storeItemDonationMatch,
        sub: AppStrings.storeItemDonationMatchNote,
        owned: 0,
        plainLabel: '${_format(_valueCost('donation_match'))} VALUE',
      ),
    ];
  }

  TierAnimal _myAnimal() {
    final tier =
        ref.read(activeUserTierStructProvider) ?? UserTier.unratedFallback;
    return tier.isSnail ? TierAnimal.wolf : tier.animal;
  }

  /// 꾸미기 탭: 캐릭터 소품 둘러보기. 러닝화 스킨과 결과 카드 프레임은 더 팔지 않는다.
  List<Widget> _cosmeticsTab() {
    final tier =
        ref.read(activeUserTierStructProvider) ?? UserTier.unratedFallback;
    return [
      AccessoryShopGrid(animal: _myAnimal(), tier: tier),
    ];
  }

  @override
  /// VALUE 설명. 잔액 옆 "?"를 누르면 작은 창으로 보여 준다.
  void _showValueInfo() {
    final c = context.srcTokens.colors;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          AppStrings.storeValueDetailTitle,
          style: storeText(18, c.ink, w: FontWeight.w900),
        ),
        content: Text(
          AppStrings.storeValueDetailBody,
          style: storeText(14, c.muted, h: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    ref.listen<StoreFocus?>(storeFocusProvider, (prev, next) {
      if (next == null || next == prev) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyFocus(next);
      });
    });
    // 가격 목록은 탭과 상관없이 처음 그릴 때 한꺼번에 불러온다.
    // (탭을 바꿀 때 처음 구독하면 그리는 도중에 상태가 바뀌어 오류가 난다.)
    ref
      ..watch(shopCatalogProvider)
      ..watch(shopSharePriceProvider)
      ..watch(shopValuePriceProvider);
    final wallet = ref.watch(walletProvider);
    final shop = ref.watch(shopTabProvider);
    final inventory = ref.watch(serverShopInventoryProvider).asData?.value ??
        const ServerShopInventory();
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final c = context.srcTokens.colors;

    final body = switch (_tab) {
      _StoreTab.recommended => _recommendedTab(inventory, shop),
      _StoreTab.diamond => _diamondTab(),
      _StoreTab.items => _itemsTab(inventory),
      _StoreTab.cosmetics => _cosmeticsTab(),
    };

    final scaffold = Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Row(
              children: [
                const StoreTag('SHOP'),
                const Spacer(),
                StoreBalancePill(
                  icon: Icons.directions_walk_rounded,
                  value: _format(wallet.shareBalance),
                  iconColor: c.primary,
                ),
                const SizedBox(width: 6),
                StoreBalancePill(
                  icon: Icons.diamond_outlined,
                  value: _format(wallet.diamondBalance),
                  iconColor: c.ink,
                ),
                const SizedBox(width: 6),
                StoreBalancePill(
                  icon: Icons.workspace_premium_outlined,
                  value: _format(wallet.valueBalance),
                  iconColor: c.accent,
                  infoKey: const Key('store-value-info'),
                  onInfo: _showValueInfo,
                ),
                IconButton(
                  icon: const Icon(Icons.inventory_2_outlined),
                  color: c.muted,
                  iconSize: 22,
                  tooltip: AppStrings.itemInventoryTitle,
                  onPressed: _onOpenInventory,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.storeTitle,
              style: storeText(30, c.ink, w: FontWeight.w900, h: 1.1),
            ),
            const SizedBox(height: 10),
            StoreUnderlineTabs(
              labels: [for (final t in _StoreTab.values) t.label],
              selected: _tab.index,
              onSelected: (i) => setState(() => _tab = _StoreTab.values[i]),
              keys: [
                for (final t in _StoreTab.values) Key('store-tab-${t.name}'),
              ],
            ),
            const SizedBox(height: 14),
            ...body,
          ],
        ),
      ),
      bottomNavigationBar: embedNav
          ? DashboardBottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            )
          : null,
    );
    return embedNav
        ? SrcExitGuard(
            tabIndex: DashboardTabNavigation.shop,
            child: scaffold,
          )
        : scaffold;
  }
}

enum _StoreTab {
  recommended('추천'),
  diamond('다이아'),
  items('아이템'),
  cosmetics('꾸미기');

  const _StoreTab(this.label);

  final String label;
}

/// 추천 화면의 꾸미기 미리보기: 소품 세 개를 입힌 모습 세 장.
class _CosmeticsPreviewRow extends StatelessWidget {
  const _CosmeticsPreviewRow({required this.animal, required this.onTap});

  final TierAnimal animal;
  final VoidCallback onTap;

  /// 시안과 같은 대표 세 점. 카탈로그에 있는 것만 보인다.
  static const _ids = ['P052', 'P067', 'P058'];

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final picks = <Accessory>[
      for (final id in _ids)
        for (final a in accessoryCatalog)
          if (a.id == id && a.ready) a,
    ];
    final items = picks.length == 3
        ? picks
        : [
            for (final a in accessoryCatalog)
              if (a.ready && a.rarity != AccessoryRarity.tierReward) a,
          ].take(3).toList();
    return Row(
      children: [
        for (final (i, a) in items.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.outline),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 84,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: c.ink.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: DressedMascot(
                          animal: animal,
                          worn: {a},
                          size: 84,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.nameKo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: storeText(13, c.ink, w: FontWeight.w800),
                    ),
                    Text(
                      a.priceLabel,
                      style: storeText(12, c.muted, w: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 유니세프 기부 펀딩 카드. 라임 바탕에 어두운 글자.
class _UnicefFundingCard extends StatelessWidget {
  const _UnicefFundingCard({
    required this.progress,
    required this.onDonate,
  });

  final double progress;
  final VoidCallback? onDonate;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: c.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.storeFundingTitle,
            style: storeText(17, c.onPrimary, w: FontWeight.w900, h: 1.4),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: c.onPrimary.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(c.onPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% 달성',
            style: storeText(12, c.onPrimary, w: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: onDonate,
              style: FilledButton.styleFrom(
                backgroundColor: c.onPrimary,
                foregroundColor: c.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                '[${AppStrings.storeDonateButton}]',
                style: storeText(14, c.primary, w: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
