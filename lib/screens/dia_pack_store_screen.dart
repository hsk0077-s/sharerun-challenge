import '../features/iap/widgets/dia_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_env.dart';
import '../core/navigation/app_route_nav.dart';
import '../features/iap/widgets/purchases_closed_page.dart';
import '../core/theme/app_colors.dart';
import '../features/iap/models/dia_pack_product.dart';
import '../features/iap/providers/iap_providers.dart';
import '../l10n/remaining_surface.dart';

/// DIA pack list. Buttons buy only when both purchase switches are on.
class DiaPackStoreScreen extends ConsumerWidget {
  const DiaPackStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppEnv.inAppPurchasesEnabled) {
      return PurchasesClosedPage(
        title: RemainingSurface.tr(context, 'dia_pack_store.title', 'DIA 팩'),
      );
    }
    final canBuy = AppEnv.diaPacksEnabled;
    final storePrices =
        ref.watch(diaPackPriceLabelsProvider).asData?.value ?? const {};
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          RemainingSurface.tr(context, 'dia_pack_store.title', 'DIA 팩'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => AppRouteNav.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final pack in DiaPackProduct.catalog) ...[
            _DiaPackCard(
              pack: pack,
              storePrice: storePrices[pack.productId],
              enabled: canBuy,
              onBuy: canBuy
                  ? () => ref
                      .read(iapPurchaseControllerProvider)
                      .buyDiaPack(pack)
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          const DiaNoticeCard(),
        ],
      ),
    );
  }
}

class _DiaPackCard extends StatelessWidget {
  const _DiaPackCard({
    required this.pack,
    required this.enabled,
    this.storePrice,
    this.onBuy,
  });

  final DiaPackProduct pack;
  final bool enabled;
  final String? storePrice;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    String grouped(int value) => value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    final price = grouped(pack.priceKrw);
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${grouped(pack.totalDia)} DIA',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              storePrice == null
                  ? RemainingSurface.tr(
                      context,
                      'dia_pack_store.body',
                      '$price원 · ${pack.bonusLabel}',
                      {'price': price, 'pack.bonusLabel': pack.bonusLabel},
                    )
                  : '$storePrice · ${pack.bonusLabel}',
            ),
            const SizedBox(height: 2),
            Text(
              RemainingSurface.tr(
                context,
                'dia_pack_store.body.2',
                '기본 ${pack.baseDia} DIA · ${pack.productId}',
                {'pack.baseDia': pack.baseDia, 'pack.productId': pack.productId},
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: enabled ? onBuy : null,
              child: Text(
                enabled
                    ? RemainingSurface.tr(context, 'dia_pack_store.buy', '구매')
                    : RemainingSurface.tr(context, 'common.preparing', '준비 중'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
