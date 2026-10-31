import '../features/donation/funding_summary.dart';
import '../features/iap/widgets/dia_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/api/api_exception.dart';
import '../core/config/app_env.dart';
import '../data/models/shop_item_model.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../l10n/accessory_names.dart';
import '../l10n/commerce_copy.dart';
import '../l10n/guidance_copy.dart';
import '../l10n/remaining_surface.dart';
import '../l10n/surface_copy.dart';
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
      final chrome = ShopChrome.of(Localizations.localeOf(context));
      _toast(
        result.status == 'already_purchased' ||
                result.status == 'already_matched'
            ? item.valueCost > 0
                ? chrome.alreadyValue
                : item.shareCost > 0
                    ? chrome.alreadyShare
                    : chrome.alreadyDia
            : item.id == 'donation_match'
                ? chrome.donationMatchDone
                : chrome.bought(item.title),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(
        streakItemMessage(
          error,
          fallback: ShopChrome.of(Localizations.localeOf(context)).diaShort,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _toast(
        ShopChrome.of(Localizations.localeOf(context)).buyFailed(item.title),
      );
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

  static String _won(int value) => RemainingSurface.trNow(
        'store.body',
        '${_groupDigits(value)}원',
        {'_groupDigits(value)': _groupDigits(value)},
      );

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
    final copy = ShopCopy.of(Localizations.localeOf(context));
    final chrome = ShopChrome.of(Localizations.localeOf(context));
    final packs = DiaPackProduct.catalog.where((p) => p.totalDia > 12).toList();
    final featured = packs.length >= 3 ? packs.sublist(0, 3) : packs;
    return [
      if (AppEnv.inAppPurchasesEnabled)
        StoreCoachCard(
          monthlyLabel: CoachPlusPlan.monthly.fallbackPriceLabel,
          yearlyLabel: CoachPlusPlan.yearly.fallbackPriceLabel,
          yearlyDiscountPct: _yearlyDiscountPct(),
          onTap: () => CoachPlusUpsellSheet.show(context),
        ),
      if (AppEnv.diaPacksEnabled) ...[
        StoreSectionLabel(
          chrome.diaTopUp,
          more: chrome.seeAll,
          onMore: () => setState(() => _tab = _StoreTab.diamond),
        ),
        Row(
          children: [
            for (final (i, pack) in featured.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              StorePackCard(
                dia: '${pack.totalDia}',
                bonus: pack.bonusDia > 0 ? chrome.bonus(pack.bonusDia) : '',
                price: _won(pack.priceKrw),
                hot: pack.productId == 'dia_pack_130',
                onTap: _openDiaPacks,
              ),
            ],
          ],
        ),
      ],
      StoreSectionLabel(
        chrome.runningItems,
        more: chrome.seeAll,
        onMore: () => setState(() => _tab = _StoreTab.items),
      ),
      Row(
        children: [
          _tile(
            id: 'record_cpr_ticket',
            icon: Icons.healing_rounded,
            name: copy.cpr,
          ),
          const SizedBox(width: 8),
          _tile(
            id: 'record_safe_guard',
            icon: Icons.shield_outlined,
            name: copy.safeGuard,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _tile(
            id: 'coach_one_point_ticket',
            icon: Icons.record_voice_over_rounded,
            name: copy.coach,
          ),
          const SizedBox(width: 8),
          _tile(
            id: 'friend_ghost_pace',
            icon: Icons.directions_run_rounded,
            name: copy.friendGhost,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _tile(
            id: 'extra_entry_ticket',
            icon: Icons.confirmation_number_outlined,
            name: copy.extraEntry,
          ),
          const SizedBox(width: 8),
          _tile(
            id: 'crew_cheer_flag',
            icon: Icons.flag_rounded,
            name: copy.crewCheer,
          ),
        ],
      ),
      StoreSectionLabel(chrome.battlePassSection),
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
                      chrome.battlePassTitle,
                      style: storeText(
                        16,
                        tokens.colors.ink,
                        w: FontWeight.w900,
                      ),
                    ),
                    Text(
                      chrome.battlePassSubtitle,
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
        chrome.cosmetics,
        more: chrome.seeAll,
        onMore: () => setState(() => _tab = _StoreTab.cosmetics),
      ),
      _CosmeticsPreviewRow(
        animal: _myAnimal(),
        onTap: () => setState(() => _tab = _StoreTab.cosmetics),
      ),
      KeyedSubtree(
        key: _fundingKey,
        child: StoreSectionLabel(chrome.donationFunding),
      ),
      const _CompanyFundingCard(),
      const DonationMatchContribution(),
    ];
  }

  /// 다이아 탭: SHARE로 교환. 팩 목록은 `AppEnv.diaPacksEnabled`가 켜질 때만 보인다.
  List<Widget> _diamondTab() {
    final tokens = context.srcTokens;
    final c = tokens.colors;
    final chrome = ShopChrome.of(Localizations.localeOf(context));
    return [
      if (AppEnv.diaPacksEnabled) ...[
        StoreSectionLabel(chrome.diaTopUp),
        for (final pack in DiaPackProduct.catalog)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: Key('store-pack-${pack.productId}'),
              onTap: _openDiaPacks,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: pack.productId == 'dia_pack_130'
                        ? c.primary
                        : c.outline,
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
                            Icon(Icons.diamond_outlined,
                                size: 22, color: c.ink),
                            const SizedBox(width: 10),
                            Text(
                              _groupDigits(pack.totalDia),
                              style: storeText(22, c.ink, w: FontWeight.w900),
                            ),
                            const SizedBox(width: 8),
                            if (pack.bonusDia > 0)
                              Text(
                                chrome.bonus(pack.bonusDia),
                                style: storeText(12, c.primary,
                                    w: FontWeight.w800),
                              ),
                            if (pack.productId == 'dia_pack_130') ...[
                              const SizedBox(width: 8),
                              Text(
                                chrome.popular,
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
                          chrome.preparing,
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
          chrome.packsClosed,
          style: storeText(12, c.muted, h: 1.5),
        ),
      ],
      StoreSectionLabel(chrome.shareExchange),
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
                      chrome.shareToDia,
                      style: storeText(16, c.ink, w: FontWeight.w900),
                    ),
                    Text(
                      chrome.shareToDiaNote,
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
      if (AppEnv.diaPacksEnabled) ...[
        const SizedBox(height: 16),
        const DiaNoticeCard(),
      ],
    ];
  }

  /// 아이템 탭: 시안의 글머리별 한 줄 목록.
  List<Widget> _itemsTab(ServerShopInventory inventory) {
    final shop = ShopCopy.of(Localizations.localeOf(context));
    final chrome = ShopChrome.of(Localizations.localeOf(context));
    return [
      StoreSectionLabel(chrome.keepRecord),
      _row(
        id: 'record_cpr_ticket',
        icon: Icons.healing_rounded,
        name: shop.cpr,
        owned: inventory.cprCount,
      ),
      _row(
        id: 'record_safe_guard',
        icon: Icons.shield_outlined,
        name: shop.safeGuard,
        owned: inventory.safeGuardCount,
      ),
      _row(
        id: 'rest_day_ticket',
        icon: Icons.bedtime_outlined,
        name: shop.restDay,
        sub: shop.restDayNote,
        owned: inventory.restDayCount,
        plainLabel: '${_format(_valueCost('rest_day_ticket'))} VALUE',
      ),
      StoreSectionLabel(chrome.runTogether),
      _row(
        id: 'coach_one_point_ticket',
        icon: Icons.record_voice_over_rounded,
        name: shop.coach,
        owned: inventory.coachOnePointCount,
      ),
      _row(
        id: 'friend_ghost_pace',
        icon: Icons.directions_run_rounded,
        name: shop.friendGhost,
        sub: chrome.ghostPack(_diaCost('friend_ghost_pace_10pack')),
        owned: inventory.friendGhostCount,
      ),
      _row(
        id: 'crew_cheer_flag',
        icon: Icons.flag_rounded,
        name: shop.crewCheer,
        owned: inventory.crewCheerCount,
      ),
      StoreSectionLabel(chrome.tournament),
      _row(
        id: 'extra_entry_ticket',
        icon: Icons.confirmation_number_outlined,
        name: shop.extraEntry,
        sub: chrome.entryPack(_diaCost('extra_entry_ticket_3pack')),
        owned: inventory.extraEntryCount,
      ),
      StoreItemRow(
        icon: Icons.bolt_rounded,
        name: shop.battlePass,
        sub: shop.battlePassNote,
        plainLabel: chrome.view,
        onTap: _openBattlePass,
      ),
      StoreSectionLabel(chrome.earnBySteps),
      _row(
        id: 'boost_run',
        icon: Icons.rocket_launch_outlined,
        name: shop.boostRun,
        sub: shop.boostRunNote,
        owned: inventory.boostRunCount,
        plainLabel: '${_format(_shareCost('boost_run'))} SHARE',
      ),
      _row(
        id: 'step_incubator',
        icon: Icons.egg_outlined,
        name: shop.stepIncubator,
        sub: shop.stepIncubatorNote,
        owned: inventory.stepIncubatorCount,
        plainLabel: '${_format(_shareCost('step_incubator'))} SHARE',
      ),
      _row(
        id: 'donation_match',
        icon: Icons.favorite_border_rounded,
        name: shop.donationMatch,
        sub: shop.donationMatchNote,
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
          ShopCopy.of(Localizations.localeOf(ctx)).valueTitle,
          style: storeText(18, c.ink, w: FontWeight.w900),
        ),
        content: Text(
          ShopCopy.of(Localizations.localeOf(ctx)).valueBody,
          style: storeText(14, c.muted, h: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ShopChrome.of(Localizations.localeOf(ctx)).confirm),
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
    final chrome = ShopChrome.of(Localizations.localeOf(context));

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
              labels: [for (final t in _StoreTab.values) t.label(chrome)],
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

enum _StoreTab { recommended, diamond, items, cosmetics }

extension on _StoreTab {
  String label(ShopChrome chrome) => switch (this) {
        _StoreTab.recommended => chrome.tabRecommended,
        _StoreTab.diamond => chrome.tabDiamond,
        _StoreTab.items => chrome.tabItems,
        _StoreTab.cosmetics => chrome.tabCosmetics,
      };
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
                      accessoryName(
                          a.id, a.nameKo, Localizations.localeOf(context)),
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

/// 기부 펀딩 카드. 라임 바탕에 어두운 글자. 서버 값이 있으면 이번 달 모인 기부금과 목표를 보여 준다.
class _CompanyFundingCard extends ConsumerWidget {
  const _CompanyFundingCard();

  static const progressKey = Key('store-funding-progress');

  static const preparingKey = Key('store-funding-preparing');

  static String _won(int value) {
    final s = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return RemainingSurface.trNow('store.body.2', '$out원', {'out': out});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.srcTokens.colors;
    final summary = ref.watch(fundingSummaryProvider).asData?.value;
    final copy = ShopFundingGuidance.of(Localizations.localeOf(context));
    if (summary != null) {
      return Container(
        key: progressKey,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: c.primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.title,
              style: storeText(17, c.onPrimary, w: FontWeight.w900, h: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              copy.monthLabel,
              style: storeText(12, c.onPrimary, w: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              _won(summary.totalWon),
              style: storeText(26, c.onPrimary, w: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.ratio,
                minHeight: 10,
                backgroundColor: c.onPrimary.withValues(alpha: 0.18),
                color: c.onPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              summary.allReached
                  ? copy.allReached
                  : copy.stageLine(summary.stage, _won(summary.goalWon)),
              style: storeText(12, c.onPrimary, w: FontWeight.w800),
            ),
            if (summary.capReached) ...[
              const SizedBox(height: 8),
              Text(
                copy.capReached,
                style: storeText(12, c.onPrimary, w: FontWeight.w700, h: 1.4),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              copy.note,
              style: storeText(11, c.onPrimary, w: FontWeight.w600, h: 1.4),
            ),
          ],
        ),
      );
    }
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
            copy.title,
            style: storeText(17, c.onPrimary, w: FontWeight.w900, h: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            copy.preparingNote,
            key: preparingKey,
            style: storeText(13, c.onPrimary, w: FontWeight.w700, h: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                disabledBackgroundColor: c.onPrimary.withValues(alpha: 0.18),
                disabledForegroundColor: c.onPrimary.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                copy.preparing,
                style: storeText(14, c.onPrimary, w: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
