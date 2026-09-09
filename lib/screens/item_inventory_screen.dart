import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';

/// 인게임 아이템 보관함 화면 (Screen 20).
class ItemInventoryScreen extends ConsumerStatefulWidget {
  const ItemInventoryScreen({super.key});

  @override
  ConsumerState<ItemInventoryScreen> createState() =>
      _ItemInventoryScreenState();
}

class _ItemInventoryScreenState extends ConsumerState<ItemInventoryScreen> {
  static const _currentNavIndex = DashboardTabNavigation.shop;
  static const _useButtonMint = Color(0xFFCDDC39);

  String _format(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      Navigator.pop(context);
      return;
    }
    DashboardTabNavigation.go(context, index);
  }

  void _onUseItem(ShopItemSku sku, String title) {
    final used = ref.read(shopTabProvider.notifier).useItem(sku);
    if (!used) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title 보유량이 없습니다. 상점에서 구매해 주세요.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title 사용 완료')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final shop = ref.watch(shopTabProvider);

    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    8,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ItemInventoryHeader(
                        onBack: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _CurrencySummaryBar(
                          shareLabel: _format(wallet.shareBalance),
                          diamondLabel: _format(wallet.diamondBalance),
                          valueLabel: _format(wallet.valueBalance),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InventoryItemCard(
                        icon: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monitor_heart_outlined,
                            color: AppColors.textWhite,
                            size: 24,
                          ),
                        ),
                        title: AppStrings.itemInventoryCprTitle,
                        quantity: '보유량: ${shop.cprCount}',
                        useButtonColor: _useButtonMint,
                        onUse: () => _onUseItem(
                          ShopItemSku.cpr,
                          AppStrings.itemInventoryCprTitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InventoryItemCard(
                        icon: const Icon(
                          Icons.shield_outlined,
                          size: 40,
                          color: AppColors.success,
                        ),
                        title: AppStrings.itemInventorySafeGuardTitle,
                        quantity: '보유량: ${shop.safeGuardCount}',
                        useButtonColor: _useButtonMint,
                        onUse: () => _onUseItem(
                          ShopItemSku.safeGuard,
                          AppStrings.itemInventorySafeGuardTitle,
                        ),
                      ),
                      if (shop.starBoostCount > 0) ...[
                        const SizedBox(height: 12),
                        _InventoryItemCard(
                          icon: const Icon(
                            Icons.star_rounded,
                            size: 40,
                            color: AppColors.progressYellow,
                          ),
                          title: AppStrings.storeItemStarBoost,
                          quantity: '보유량: ${shop.starBoostCount}',
                          useButtonColor: _useButtonMint,
                          onUse: () => _onUseItem(
                            ShopItemSku.starBoost,
                            AppStrings.storeItemStarBoost,
                          ),
                        ),
                      ],
                      if (shop.sharePackCount > 0) ...[
                        const SizedBox(height: 12),
                        _InventoryItemCard(
                          icon: const Icon(
                            Icons.monetization_on_outlined,
                            size: 40,
                            color: AppColors.progressYellow,
                          ),
                          title: AppStrings.storeItemSharePack,
                          quantity: '보유량: ${shop.sharePackCount}',
                          useButtonColor: _useButtonMint,
                          onUse: () => _onUseItem(
                            ShopItemSku.sharePack,
                            AppStrings.storeItemSharePack,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _ItemInventoryHeader extends StatelessWidget {
  const _ItemInventoryHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textBlack,
              iconSize: 22,
              onPressed: onBack,
            ),
          ),
          Text(
            AppStrings.itemInventoryTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CurrencySummaryBar extends StatelessWidget {
  const _CurrencySummaryBar({
    required this.shareLabel,
    required this.diamondLabel,
    required this.valueLabel,
  });

  final String shareLabel;
  final String diamondLabel;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CurrencyItem(
            icon: const _CoinIcon(
              label: 'S',
              color: AppColors.progressYellow,
            ),
            amount: shareLabel,
          ),
          const _DividerSlash(),
          _CurrencyItem(
            icon: const Icon(
              Icons.diamond_rounded,
              color: Color(0xFF42A5F5),
              size: 20,
            ),
            amount: diamondLabel,
          ),
          const _DividerSlash(),
          _CurrencyItem(
            icon: const _CoinIcon(
              label: 'V',
              color: Color(0xFF8BC34A),
            ),
            amount: valueLabel,
          ),
        ],
      ),
    );
  }
}

class _DividerSlash extends StatelessWidget {
  const _DividerSlash();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '/',
        style: AppTextStyles.caption.copyWith(
          fontSize: 14,
          color: AppColors.borderGrey,
        ),
      ),
    );
  }
}

class _CurrencyItem extends StatelessWidget {
  const _CurrencyItem({
    required this.icon,
    required this.amount,
  });

  final Widget icon;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          amount,
          style: AppTextStyles.agreementLabel.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CoinIcon extends StatelessWidget {
  const _CoinIcon({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.textWhite,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.icon,
    required this.title,
    required this.quantity,
    required this.useButtonColor,
    required this.onUse,
  });

  final Widget icon;
  final String title;
  final String quantity;
  final Color useButtonColor;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quantity,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: useButtonColor,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onUse,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    AppStrings.itemInventoryUse,
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.textBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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
