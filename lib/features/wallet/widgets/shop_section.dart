import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/economy_constants.dart';
import '../../../data/models/shop_item_model.dart';

class ShopSection extends StatelessWidget {
  const ShopSection({
    super.key,
    required this.diamondBalance,
    required this.onPurchase,
    required this.onBuyDiamonds,
    this.purchasingItemId,
    this.buyingDiamonds = false,
  });

  final int diamondBalance;
  final Future<void> Function(ShopItemModel item) onPurchase;
  final Future<void> Function() onBuyDiamonds;
  final String? purchasingItemId;
  final bool buyingDiamonds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('다이아 상점', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '보유 Diamond $diamondBalance',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: buyingDiamonds ? null : onBuyDiamonds,
          icon: buyingDiamonds
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.diamond_outlined),
          label: Text(buyingDiamonds ? '결제 준비 중...' : 'Diamond 충전하기'),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            EconomyConstants.diamondRefundPolicy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ),
        const SizedBox(height: 16),
        ...ShopItemModel.catalog.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ShopItemCard(
              item: item,
              canAfford: diamondBalance >= item.diamondCost,
              loading: purchasingItemId == item.id,
              onPurchase: () => onPurchase(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.canAfford,
    required this.loading,
    required this.onPurchase,
  });

  final ShopItemModel item;
  final bool canAfford;
  final bool loading;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.electricBlue.withValues(alpha: 0.15),
            child: Icon(_iconFor(item.iconName), color: AppColors.electricBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '${item.diamondCost} ◆',
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: canAfford && !loading ? onPurchase : null,
                child: loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('구매'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    return switch (name) {
      'favorite' => Icons.favorite_rounded,
      'shield' => Icons.shield_rounded,
      'speed' => Icons.speed_rounded,
      'emoji_events' => Icons.emoji_events_rounded,
      _ => Icons.shopping_bag_rounded,
    };
  }
}
