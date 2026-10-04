import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_names.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../screens/item_inventory_screen.dart';
import '../../shop/providers/server_shop_inventory_provider.dart';

/// Wallet inventory list. Counts come from the account shopInventory docs.
class WalletInventorySection extends ConsumerWidget {
  const WalletInventorySection({
    this.compact = false,
    super.key,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(serverShopInventoryProvider).asData?.value ??
        const ServerShopInventory();
    final rows = <_InventoryRow>[
      if (shop.cprCount > 0)
        _InventoryRow(
          icon: Icons.monitor_heart_outlined,
          color: AppColors.error,
          title: AppStrings.itemInventoryCprTitle,
          count: shop.cprCount,
          note: AppStrings.myWalletItemDuringRun,
        ),
      if (shop.safeGuardCount > 0)
        _InventoryRow(
          icon: Icons.shield_outlined,
          color: AppColors.success,
          title: AppStrings.itemInventorySafeGuardTitle,
          count: shop.safeGuardCount,
          note: AppStrings.myWalletItemDuringTournament,
        ),
      if (shop.friendGhostCount > 0)
        _InventoryRow(
          icon: Icons.speed,
          color: AppColors.tealAccent,
          title: AppStrings.itemInventoryFriendGhostTitle,
          count: shop.friendGhostCount,
          note: AppStrings.myWalletItemDuringRun,
        ),
      if (shop.crewCheerCount > 0)
        _InventoryRow(
          icon: Icons.flag_outlined,
          color: AppColors.progressYellow,
          title: AppStrings.itemInventoryCrewCheerTitle,
          count: shop.crewCheerCount,
          note: AppStrings.myWalletItemDuringTournament,
        ),
      if (shop.ghostPaceCount > 0)
        _InventoryRow(
          icon: Icons.speed,
          color: AppColors.tealAccent,
          title: serverShopItemTitle(ServerShopInventory.ghostPaceId) ?? '',
          count: shop.ghostPaceCount,
          note: AppStrings.myWalletItemDuringRun,
        ),
      if (shop.battlePassCount > 0)
        _InventoryRow(
          icon: Icons.emoji_events_outlined,
          color: AppColors.progressYellow,
          title: shop.battlePass.ownsPlus
              ? '배틀런 패스+'
              : serverShopItemTitle(ServerShopInventory.battlePassId) ?? '',
          count: shop.battlePassCount,
          note: AppStrings.battlePassInventoryNote,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            style: AppTextStyles.agreementLabel.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            row.note,
                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                          ),
                        ],
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
    required this.note,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final String note;
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
