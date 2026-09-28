import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/coach_plus_product.dart';
import '../providers/coach_plus_providers.dart';
import '../providers/iap_providers.dart';

/// Thin Coach+ upsell. Free line vs heart-rate coaching, month / year only.
class CoachPlusUpsellSheet extends ConsumerStatefulWidget {
  const CoachPlusUpsellSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const CoachPlusUpsellSheet(),
    );
  }

  @override
  ConsumerState<CoachPlusUpsellSheet> createState() =>
      _CoachPlusUpsellSheetState();
}

class _CoachPlusUpsellSheetState extends ConsumerState<CoachPlusUpsellSheet> {
  final _prices = <String, String>{};
  String? _busyProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPrices();
    });
  }

  Future<void> _loadPrices() async {
    final labels =
        await ref.read(iapPurchaseControllerProvider).queryCoachPlusPriceLabels();
    if (!mounted) return;
    setState(() => _prices.addAll(labels));
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(coachPlusActiveProvider);
    ref.listen<bool>(coachPlusActiveProvider, (previous, next) {
      if (next && previous != true && mounted) {
        Navigator.of(context).maybePop();
      }
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Coach+',
              style: AppTextStyles.header1.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const _PlanLine(label: '무료', body: '기본 러닝 안내'),
            const SizedBox(height: 6),
            const _PlanLine(label: 'Coach+', body: '심박·상황에 맞춘 심층 코칭'),
            const SizedBox(height: 16),
            if (active)
              Text(
                'Coach+ 이용 중',
                textAlign: TextAlign.center,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealAccent,
                ),
              )
            else ...[
              for (final plan in CoachPlusPlan.catalog) ...[
                FilledButton(
                  key: Key('coach-plus-${plan.productId}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.tealAccent,
                    foregroundColor: AppColors.textWhite,
                  ),
                  onPressed: _busyProductId == null ? () => _buy(plan) : null,
                  child: _busyProductId == plan.productId
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '${plan.periodLabel} · ${_prices[plan.productId] ?? plan.fallbackPriceLabel}',
                        ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                key: const Key('coach-plus-restore'),
                onPressed: _busyProductId == null ? _restore : null,
                child: const Text('구매 복원'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _buy(CoachPlusPlan plan) async {
    setState(() => _busyProductId = plan.productId);
    try {
      await ref.read(iapPurchaseControllerProvider).buyCoachPlus(plan);
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  Future<void> _restore() async {
    setState(() => _busyProductId = 'restore');
    try {
      await ref.read(iapPurchaseControllerProvider).restorePurchases();
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(body, style: AppTextStyles.agreementLabel)),
      ],
    );
  }
}
