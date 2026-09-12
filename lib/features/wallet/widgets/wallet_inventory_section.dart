import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../screens/item_inventory_screen.dart';
import '../../shop/providers/shop_tab_provider.dart';

/// Wallet inventory list — owned CPR, Safeguard, and other shop SKUs.
///
/// Reads [ShopTabState] only. Does not debit, persist, or rewrite wallet.
class WalletInventorySection extends StatelessWidget {
  const WalletInventorySection({
    required this.shop,
    this.compact = false,
    super.key,
  });

  final ShopTabState shop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = <_InventoryRow>[
      if (shop.cprCount > 0)
        _InventoryRow(
          icon: Icons.monitor_heart_outlined,
          color: AppColors.error,
          title: AppStrings.itemInventoryCprTitle,
          count: shop.cprCount,
        ),
      if (shop.safeGuardCount > 0)
        _InventoryRow(
          icon: Icons.shield_outlined,
          color: AppColors.success,
          title: AppStrings.itemInventorySafeGuardTitle,
          count: shop.safeGuardCount,
        ),
      if (shop.starBoostCount > 0)
        _InventoryRow(
          icon: Icons.star_rounded,
          color: AppColors.progressYellow,
          title: AppStrings.storeItemStarBoost,
          count: shop.starBoostCount,
        ),
      if (shop.sharePackCount > 0)
        _InventoryRow(
          icon: Icons.monetization_on_outlined,
          color: AppColors.progressYellow,
          title: AppStrings.storeItemSharePack,
          count: shop.sharePackCount,
        ),
    ];

    return KeyedSubtree(
      key: const Key('wallet-inventory-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.myWalletInventoryTitle,
                  style: compact
                      ? AppTextStyles.agreementLabel.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        )
                      : MyWalletInventoryTitle.style,
                ),
              ),
              TextButton(
                onPressed: () => AppRouteNav.push<void>(
                  context,
                  RouteNames.itemInventory,
                  materialBuilder: (_) => const ItemInventoryScreen(),
                ),
                child: const Text(AppStrings.myWalletInventoryOpen),
              ),
            ],
          ),
          if (rows.isEmpty)
            Text(
              AppStrings.myWalletInventoryEmpty,
              style: AppTextStyles.caption.copyWith(fontSize: 13),
            )
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(row.icon, size: 20, color: row.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.title,
                        style: AppTextStyles.agreementLabel.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      AppStrings.myWalletInventoryCount(row.count),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InventoryRow {
  const _InventoryRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int count;
}

abstract final class MyWalletInventoryTitle {
  static const style = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.myWalletInk,
    height: 1.3,
  );
}
