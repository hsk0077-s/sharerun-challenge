import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/iap/models/iap_ui_event.dart';
import '../features/iap/models/share_iap_product.dart';
import '../features/iap/providers/iap_providers.dart';

/// src-14 Google Play 인앱 충전소.
class InAppBillingScreen extends ConsumerStatefulWidget {
  const InAppBillingScreen({
    super.key,
    this.highlightAmountWon = 0,
  });

  final int highlightAmountWon;

  @override
  ConsumerState<InAppBillingScreen> createState() => _InAppBillingScreenState();
}

class _InAppBillingScreenState extends ConsumerState<InAppBillingScreen> {
  var _busyProductId = '';

  @override
  Widget build(BuildContext context) {
    final featured = ShareIapProduct.byPriceKrw(widget.highlightAmountWon);

    ref.listen<AsyncValue<IapUiEvent>>(iapUiEventsProvider, (previous, next) {
      final event = next.asData?.value;
      if (event == null || !mounted) return;
      setState(() => _busyProductId = '');
      if (event.isVerified) {
        _popSuccess();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: Stack(
        children: [
          const _MintGlowBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textBlack,
                        onPressed: _busyProductId.isNotEmpty ? null : _close,
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.iapBillingTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.header1.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textBlack,
                        onPressed: _busyProductId.isNotEmpty ? null : _close,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: _GooglePlaySecurityChip()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    children: [
                      for (final product in ShareIapProduct.catalog) ...[
                        _IapProductCard(
                          product: product,
                          featured: featured?.productId == product.productId ||
                              (featured == null &&
                                  product.productId ==
                                      ShareIapProduct.pack5000.productId),
                          busy: _busyProductId == product.productId,
                          enabled: _busyProductId.isEmpty,
                          onBuy: () => _buy(product),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(ShareIapProduct product) async {
    if (_busyProductId.isNotEmpty) return;
    setState(() => _busyProductId = product.productId);
    try {
      await ref.read(iapPurchaseControllerProvider).buyConsumablePack(product);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busyProductId = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제를 시작하지 못했습니다. $error')),
      );
    }
  }

  void _popSuccess() {
    try {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop(true);
        return;
      }
      GoRouter.maybeOf(context)?.pop(true);
    } catch (_) {}
  }

  void _close() {
    try {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
        return;
      }
      GoRouter.maybeOf(context)?.pop();
    } catch (_) {}
  }
}

class _GooglePlaySecurityChip extends StatelessWidget {
  const _GooglePlaySecurityChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tealAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 14,
            color: AppColors.tealAccent.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '🔒 ${AppStrings.iapBillingSubtitle}',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IapProductCard extends StatelessWidget {
  const _IapProductCard({
    required this.product,
    required this.featured,
    required this.busy,
    required this.enabled,
    required this.onBuy,
  });

  final ShareIapProduct product;
  final bool featured;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final price = product.priceKrw.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: AppColors.surfaceWhite.withValues(alpha: featured ? 0.78 : 0.64),
          child: InkWell(
            onTap: enabled ? onBuy : null,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: featured
                      ? AppColors.tealAccent
                      : AppColors.tealAccent.withValues(alpha: 0.28),
                  width: featured ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tealAccent.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.tealAccent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.tealAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.label,
                          style: AppTextStyles.agreementLabel.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$price원 · ${product.productId}',
                          style: AppTextStyles.caption.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.tealAccent,
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.tealAccent.withValues(alpha: 0.9),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MintGlowBackdrop extends StatelessWidget {
  const _MintGlowBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.tealAccent.withValues(alpha: 0.16),
            AppColors.bgGradientMid,
            AppColors.bgGradientEnd,
          ],
        ),
      ),
    );
  }
}
