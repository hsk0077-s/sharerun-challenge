import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cosmetics_catalog.dart';

/// Direct cosmetic purchase. No random box. Prices shown are the catalog
/// the server returned, or the code defaults until that request finishes.
class CosmeticsShopSection extends StatelessWidget {
  const CosmeticsShopSection({
    super.key,
    required this.catalog,
    required this.diamondBalance,
    required this.ownedIds,
    required this.loadout,
    required this.busyId,
    required this.onPurchase,
    required this.onEquip,
  });

  final CosmeticsCatalog catalog;
  final int diamondBalance;
  final Set<String> ownedIds;
  final CosmeticLoadout loadout;
  final String busyId;
  final Future<void> Function(CosmeticItem item) onPurchase;
  final Future<void> Function(CosmeticItem item, bool equip) onEquip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.storeCosmeticsTitle,
          style: AppTextStyles.header1.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.storeCosmeticsNote,
          style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        for (final category in const [runnerAvatar, shoeSkin, shareFrame]) ...[
          Text(
            cosmeticCategoryLabel(category),
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in catalog.items)
            if (item.category == category) ...[
              _CosmeticRow(
                item: item,
                onSale: catalog.onSale(item),
                owned: ownedIds.contains(item.id),
                equipped: loadout.slotFor(category).id == item.id,
                canAfford: diamondBalance >= item.price,
                busy: busyId == item.id,
                onPurchase: () => onPurchase(item),
                onEquip: (equip) => onEquip(item, equip),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ],
    );
  }
}

class _CosmeticRow extends StatelessWidget {
  const _CosmeticRow({
    required this.item,
    required this.onSale,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.busy,
    required this.onPurchase,
    required this.onEquip,
  });

  final CosmeticItem item;
  final bool onSale;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final bool busy;
  final VoidCallback onPurchase;
  final ValueChanged<bool> onEquip;

  @override
  Widget build(BuildContext context) {
    final accent = cosmeticAccentColor(item.accent);
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            _Preview(item: item, accent: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (item.limited)
                    Text(
                      '${AppStrings.storeCosmeticLimited} · ${item.season}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.progressYellow,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    owned
                        ? AppStrings.storeCosmeticOwned
                        : '${item.price} DIA',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.tealAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _Action(
              item: item,
              onSale: onSale,
              owned: owned,
              equipped: equipped,
              canAfford: canAfford,
              busy: busy,
              onPurchase: onPurchase,
              onEquip: onEquip,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item, required this.accent});

  final CosmeticItem item;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    if (item.asset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          item.asset,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _icon(accent),
        ),
      );
    }
    return _icon(accent);
  }

  Widget _icon(Color? color) {
    final icon = item.category == shoeSkin
        ? Icons.directions_run_rounded
        : Icons.crop_square_rounded;
    return Icon(icon, color: color ?? AppColors.tealAccent, size: 36);
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.item,
    required this.onSale,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.busy,
    required this.onPurchase,
    required this.onEquip,
  });

  final CosmeticItem item;
  final bool onSale;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final bool busy;
  final VoidCallback onPurchase;
  final ValueChanged<bool> onEquip;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (owned) {
      return TextButton(
        key: Key('cosmetic-equip-${item.id}'),
        onPressed: () => onEquip(!equipped),
        child: Text(
          equipped
              ? AppStrings.storeCosmeticUnequip
              : AppStrings.storeCosmeticEquip,
        ),
      );
    }
    if (!onSale) {
      return Text(
        AppStrings.storeCosmeticSeasonEnded,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
      );
    }
    return TextButton(
      key: Key('cosmetic-buy-${item.id}'),
      onPressed: canAfford ? onPurchase : null,
      child: Text('${item.price} DIA'),
    );
  }
}
