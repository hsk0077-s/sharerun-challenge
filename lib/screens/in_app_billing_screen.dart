import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/iap/models/coach_plus_product.dart';
import '../app/router/route_names.dart';
import '../features/iap/widgets/coach_plus_upsell_sheet.dart';
import 'dia_pack_store_screen.dart';
import 'share_dia_exchange_screen.dart';

/// src-14 Google Play 인앱 충전소.
class InAppBillingScreen extends StatelessWidget {
  const InAppBillingScreen({
    super.key,
    this.highlightAmountWon = 0,
  });

  /// 예전 SHARE 원 팩 강조 금액. 팩을 더 이상 팔지 않아 화면에서는 쓰지 않는다.
  final int highlightAmountWon;

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () => _close(context),
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
                        onPressed: () => _close(context),
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
                      const _CoachPlusBillingEntry(),
                      const SizedBox(height: 14),
                      const _DiaExchangeEntry(),
                      const SizedBox(height: 14),
                      const _DiaPackStoreEntry(),
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

  void _close(BuildContext context) {
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

class _DiaExchangeEntry extends StatelessWidget {
  const _DiaExchangeEntry();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('dia-share-exchange'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final router = GoRouter.maybeOf(context);
          if (router != null) {
            context.push(RouteNames.shareToDia);
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ShareDiaExchangeScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tealAccent, width: 1.6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIA · SHARE로 교환',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text('120 SHARE = 1 DIA · 주간 한도 안에서 교환'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaPackStoreEntry extends StatelessWidget {
  const _DiaPackStoreEntry();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('dia-pack-store'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final router = GoRouter.maybeOf(context);
          if (router != null) {
            context.push(RouteNames.diaPackStore);
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DiaPackStoreScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tealAccent, width: 1.6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIA 팩',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text('Play 상품 준비 중 · 결제해도 DIA가 지급되지 않습니다'),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachPlusBillingEntry extends StatelessWidget {
  const _CoachPlusBillingEntry();

  @override
  Widget build(BuildContext context) {
    final monthly = CoachPlusPlan.monthly;
    final yearly = CoachPlusPlan.yearly;
    return Material(
      color: AppColors.surfaceWhite.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('coach-plus-billing'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => CoachPlusUpsellSheet.show(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tealAccent, width: 1.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coach+',
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '무료 기본 러닝 안내 · 심박·상황에 맞춘 심층 코칭',
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '${monthly.periodLabel} ${monthly.fallbackPriceLabel} · '
                '${yearly.periodLabel} ${yearly.fallbackPriceLabel}',
                style: AppTextStyles.agreementLabel.copyWith(
                  color: AppColors.tealAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
