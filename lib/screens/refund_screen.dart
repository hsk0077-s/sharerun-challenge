import 'package:flutter/material.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';

/// 결제 취소 및 환불 화면 (Screen 21).
class RefundScreen extends StatelessWidget {
  const RefundScreen({super.key});

  static const _saveNavy = Color(0xFF1A2B4A);

  void _onCancelRefund() {
    debugPrint('버튼 클릭됨');
  }

  @override
  Widget build(BuildContext context) {
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
                      _RefundHeader(onBack: () => Navigator.pop(context)),
                      const SizedBox(height: 20),
                      const _RefundPolicyCard(),
                      const SizedBox(height: 14),
                      const _RefundTargetCard(),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    4,
                    AppShapes.termsHorizontalPadding,
                    12,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.9,
                      height: AppShapes.buttonHeight,
                      child: Material(
                        color: _saveNavy,
                        borderRadius: BorderRadius.circular(
                          AppShapes.cardRadius,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _onCancelRefund,
                          child: Center(
                            child: Text(
                              AppStrings.refundCancelCta,
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.textWhite,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefundHeader extends StatelessWidget {
  const _RefundHeader({required this.onBack});

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
            AppStrings.refundTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RefundWhiteCard extends StatelessWidget {
  const _RefundWhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }
}

class _RefundPolicyCard extends StatelessWidget {
  const _RefundPolicyCard();

  @override
  Widget build(BuildContext context) {
    return _RefundWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppColors.paymentButtonBlue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.refundGuaranteeTitle,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 14),
          Text(
            AppStrings.refundPolicy1,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.refundPolicy2,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundTargetCard extends StatelessWidget {
  const _RefundTargetCard();

  @override
  Widget build(BuildContext context) {
    return _RefundWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.progressYellow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'S',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.refundTargetItem,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.agreementBoxFill,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primaryMint),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.primaryMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.refundPaymentDate,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 14),
          Text(
            AppStrings.refundTotalAmount,
            style: AppTextStyles.header1.copyWith(fontSize: 17),
          ),
        ],
      ),
    );
  }
}
