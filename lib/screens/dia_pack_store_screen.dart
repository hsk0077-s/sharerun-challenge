import 'package:flutter/material.dart';

import '../core/navigation/app_route_nav.dart';
import '../core/theme/app_colors.dart';
import '../features/iap/models/dia_pack_product.dart';

/// DIA pack list. Buttons stay disabled until Play products exist.
class DiaPackStoreScreen extends StatelessWidget {
  const DiaPackStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('DIA 팩'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => AppRouteNav.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final pack in DiaPackProduct.catalog) ...[
            _DiaPackCard(pack: pack),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DiaPackCard extends StatelessWidget {
  const _DiaPackCard({required this.pack});

  final DiaPackProduct pack;

  @override
  Widget build(BuildContext context) {
    final price = pack.priceKrw.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pack.totalDia} DIA',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text('$price원 · ${pack.bonusLabel}'),
            const SizedBox(height: 2),
            Text(
              '기본 ${pack.baseDia} DIA · ${pack.productId}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            const FilledButton(
              onPressed: null,
              child: Text('준비 중'),
            ),
          ],
        ),
      ),
    );
  }
}
