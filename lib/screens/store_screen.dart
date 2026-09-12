import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../features/profile/user_profile_notifier.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import 'in_app_billing_screen.dart';
import 'item_inventory_screen.dart';
import 'web3_wallet_screen.dart';

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
  final _fundingKey = GlobalKey();
  final _itemsKey = GlobalKey();
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeIncomingFocus());
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

  void _consumeIncomingFocus() {
    if (!mounted) return;
    final requested =
        widget.initialFocus ?? ref.read(storeFocusProvider);
    if (requested == null) return;
    _applyFocus(requested);
  }

  void _applyFocus(StoreFocus focus) {
    final key = switch (focus) {
      StoreFocus.donate => _fundingKey,
      StoreFocus.items => _itemsKey,
    };
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
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

  Future<void> _onDonate() async {
    if (_isSubmitting) return;
    final wallet = ref.read(walletProvider);
    const amount = ShopTabNotifier.donateValueAmount;
    if (wallet.valueBalance < amount) {
      _toast(
        'VALUE가 부족합니다. (보유 ${_format(wallet.valueBalance)} / 필요 ${_format(amount)})',
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      ref.read(walletProvider.notifier).debitValue(amount);
      ref.read(shopTabProvider.notifier).addDonation(amount);
      await ref
          .read(userProfileNotifierProvider.notifier)
          .donateValue(amount);
      final progress = ref.read(shopTabProvider).fundingProgress;
      final left = ref.read(walletProvider).valueBalance;
      _toast(
        '기부 완료: -${_format(amount)} VALUE · 잔액 ${_format(left)} · 펀딩 ${(progress * 100).round()}%',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onBuyItem(ShopItemSku sku, String title) async {
    if (_isSubmitting) return;
    final wallet = ref.read(walletProvider);
    const cost = ShopTabNotifier.itemDiaCost;
    if (wallet.diamondBalance < cost) {
      _toast('DIA가 부족합니다. (보유 ${wallet.diamondBalance} / 필요 $cost)');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      ref.read(walletProvider.notifier).debitDia(cost);
      ref.read(shopTabProvider.notifier).addItem(sku);
      final authUid = ref.read(authStateChangesProvider).asData?.value?.uid ?? '';
      final profileUid = ref.read(userProfileProvider).uid;
      final uid = authUid.isNotEmpty ? authUid : profileUid;
      await ref.read(walletRepositoryProvider).logClientWalletTransaction(
            uid: uid,
            title: switch (sku) {
              ShopItemSku.cpr => '심폐소생권(CPR) 아이템 구매 🎁',
              ShopItemSku.safeGuard => '세이프가드 구매 🎁',
              ShopItemSku.starBoost => '스타 부스트 구매 🎁',
              ShopItemSku.sharePack => 'SHARE 팩 구매 🎁',
            },
            amount: -cost,
            assetType: 'DIA',
          );
      await ref.read(userProfileNotifierProvider.notifier).persistShopPurchase(
            diamondFee: cost,
            markCpr: sku == ShopItemSku.cpr,
            markSafeGuard: sku == ShopItemSku.safeGuard,
          );
      final owned = switch (sku) {
        ShopItemSku.cpr => ref.read(shopTabProvider).cprCount,
        ShopItemSku.safeGuard => ref.read(shopTabProvider).safeGuardCount,
        ShopItemSku.starBoost => ref.read(shopTabProvider).starBoostCount,
        ShopItemSku.sharePack => ref.read(shopTabProvider).sharePackCount,
      };
      final leftDia = ref.read(walletProvider).diamondBalance;
      _toast('$title 구매 완료 (−$cost DIA) · 보관함 $owned · DIA 잔액 $leftDia');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onOpenInventory() {
    AppRouteNav.push<void>(
      context,
      RouteNames.itemInventory,
      materialBuilder: (_) => const ItemInventoryScreen(),
    );
  }

  void _onOpenBilling() {
    AppRouteNav.push<bool>(
      context,
      RouteNames.inAppBilling,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  Future<void> _onRequestValueExternalTransfer() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(AppStrings.storeValueTransferConfirmTitle),
          content: const Text(AppStrings.web3WalletVaspWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(AppStrings.storeValueTransferCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(AppStrings.storeValueTransferApprove),
            ),
          ],
        );
      },
    );
    if (approved != true || !mounted) return;
    await AppRouteNav.push<void>(
      context,
      RouteNames.web3Wallet,
      materialBuilder: (_) => const Web3WalletScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StoreFocus?>(storeFocusProvider, (prev, next) {
      if (next == null || next == prev) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyFocus(next);
      });
    });
    final wallet = ref.watch(walletProvider);
    final shop = ref.watch(shopTabProvider);
    final focus = widget.initialFocus ?? ref.watch(storeFocusProvider);
    final highlightDonate = focus == StoreFocus.donate;
    final highlightItems = focus == StoreFocus.items;
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: Stack(
        children: [
          const _StoreGlowBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppShapes.termsHorizontalPadding,
                      12,
                      AppShapes.termsHorizontalPadding,
                      20,
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.storeTitle,
                              style: AppTextStyles.header1.copyWith(fontSize: 24),
                            ),
                          ),
                          TextButton(
                            onPressed: _onOpenBilling,
                            child: Text(
                              AppStrings.storeChargeCta,
                              style: AppTextStyles.link.copyWith(
                                color: AppColors.tealAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.inventory_2_outlined),
                            color: AppColors.textBlack,
                            tooltip: AppStrings.itemInventoryTitle,
                            onPressed: _onOpenInventory,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _CurrencyCapsuleBar(
                        shareLabel: _format(wallet.shareBalance),
                        diamondLabel: _format(wallet.diamondBalance),
                        valueLabel: _format(wallet.valueBalance),
                        onCharge: _onOpenBilling,
                      ),
                      const SizedBox(height: 18),
                      KeyedSubtree(
                        key: _fundingKey,
                        child: _FocusGlow(
                          highlighted: highlightDonate,
                          child: _UnicefFundingCard(
                            progress: shop.fundingProgress,
                            onDonate: _isSubmitting ? null : _onDonate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ValueTokenDetailCard(
                        highlighted: highlightDonate,
                        onRequestExternalTransfer:
                            _onRequestValueExternalTransfer,
                      ),
                      const SizedBox(height: 22),
                      KeyedSubtree(
                        key: _itemsKey,
                        child: _FocusGlow(
                          highlighted: highlightItems,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.storeFunctionalItems,
                                style: AppTextStyles.header1.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ItemBuyCard(
                                      icon: Icons.monitor_heart_outlined,
                                      iconColor: AppColors.error,
                                      title: AppStrings.storeItemCpr,
                                      ownedCount: shop.cprCount,
                                      onBuy: _isSubmitting
                                          ? null
                                          : () => _onBuyItem(
                                                ShopItemSku.cpr,
                                                AppStrings.storeItemCpr,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ItemBuyCard(
                                      icon: Icons.shield_outlined,
                                      iconColor: AppColors.success,
                                      title: AppStrings.storeItemSafeGuard,
                                      ownedCount: shop.safeGuardCount,
                                      onBuy: _isSubmitting
                                          ? null
                                          : () => _onBuyItem(
                                                ShopItemSku.safeGuard,
                                                AppStrings.storeItemSafeGuard,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _FocusGlow extends StatelessWidget {
  const _FocusGlow({
    required this.highlighted,
    required this.child,
  });

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? AppColors.tealAccent.withValues(alpha: 0.72)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.tealAccent.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      padding: highlighted ? const EdgeInsets.all(4) : EdgeInsets.zero,
      child: child,
    );
  }
}

class _ValueTokenDetailCard extends StatelessWidget {
  const _ValueTokenDetailCard({
    required this.highlighted,
    required this.onRequestExternalTransfer,
  });

  final bool highlighted;
  final VoidCallback onRequestExternalTransfer;

  @override
  Widget build(BuildContext context) {
    return _FocusGlow(
      highlighted: highlighted,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.storeValueDetailTitle,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.web3WalletVaspWarning,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.textGrey,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onRequestExternalTransfer,
                  child: Text(
                    AppStrings.storeValueExternalTransfer,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyCapsuleBar extends StatelessWidget {
  const _CurrencyCapsuleBar({
    required this.shareLabel,
    required this.diamondLabel,
    required this.valueLabel,
    required this.onCharge,
  });

  final String shareLabel;
  final String diamondLabel;
  final String valueLabel;
  final VoidCallback onCharge;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: AppColors.surfaceWhite.withValues(alpha: 0.72),
          child: InkWell(
            onTap: onCharge,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.tealAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CapsuleChip(label: 'SHARE', value: shareLabel),
                  _slash(),
                  _CapsuleChip(label: 'DIA', value: diamondLabel),
                  _slash(),
                  _CapsuleChip(label: 'VALUE', value: valueLabel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slash() {
    return Text(
      '/',
      style: AppTextStyles.caption.copyWith(
        fontSize: 16,
        color: AppColors.borderGrey,
      ),
    );
  }
}

class _CapsuleChip extends StatelessWidget {
  const _CapsuleChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: AppColors.tealAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.agreementLabel.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _UnicefFundingCard extends StatelessWidget {
  const _UnicefFundingCard({
    required this.progress,
    required this.onDonate,
  });

  final double progress;
  final VoidCallback? onDonate;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tealAccent.withValues(alpha: 0.92),
            AppColors.primaryMintDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealAccent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.storeFundingTitle,
            style: AppTextStyles.header1.copyWith(
              fontSize: 17,
              color: AppColors.textWhite,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.textWhite.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8FF6B)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% 달성',
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textWhite.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8FF6B).withValues(alpha: 0.55),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: onDonate,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE8FF6B),
                  foregroundColor: AppColors.textBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  '[${AppStrings.storeDonateButton}]',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemBuyCard extends StatelessWidget {
  const _ItemBuyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.ownedCount,
    required this.onBuy,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int ownedCount;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: AppColors.tealAccent.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onBuy,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          child: Column(
            children: [
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (ownedCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '보관함 $ownedCount',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.tealAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppStrings.storeBuyDia,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.tealAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreGlowBackdrop extends StatelessWidget {
  const _StoreGlowBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7F8F4),
            AppColors.bgGradientMid,
            AppColors.bgGradientEnd,
          ],
        ),
      ),
    );
  }
}
