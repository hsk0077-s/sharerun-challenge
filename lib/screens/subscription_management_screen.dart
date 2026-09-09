import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';

/// 구독 및 정기 후원 관리 화면 (Screen 25).
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  static const _saveNavy = Color(0xFF1A2B4A);

  static const _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Colors.white],
  );

  var _donationEnabled = true;
  var _premiumEnabled = false;

  void _onChangePayment() {
    debugPrint('버튼 클릭됨');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SRCGradientBackground(
        gradient: _screenGradient,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SubscriptionHeader(
                        onBack: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 20),
                      _DonationSubscriptionCard(
                        enabled: _donationEnabled,
                        onChanged: (value) =>
                            setState(() => _donationEnabled = value),
                      ),
                      const SizedBox(height: 20),
                      _PremiumMembershipCard(
                        enabled: _premiumEnabled,
                        onChanged: (value) =>
                            setState(() => _premiumEnabled = value),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                          onTap: _onChangePayment,
                          child: Center(
                            child: Text(
                              AppStrings.subscriptionPaymentMethodCta,
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

class _SubscriptionHeader extends StatelessWidget {
  const _SubscriptionHeader({required this.onBack});

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppStrings.subscriptionTitle,
              style: AppTextStyles.header1.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionWhiteCard extends StatelessWidget {
  const _SubscriptionWhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DonationSubscriptionCard extends StatelessWidget {
  const _DonationSubscriptionCard({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SubscriptionWhiteCard(
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.volunteer_activism_outlined,
              size: 72,
              color: AppColors.borderLight.withValues(alpha: 0.8),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.subscriptionDonationTitle,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                        height: 1.3,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: enabled,
                    activeTrackColor: AppColors.primaryMint,
                    onChanged: onChanged,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.subscriptionDonationStatus,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGrey,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumMembershipCard extends StatelessWidget {
  const _PremiumMembershipCard({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SubscriptionWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  AppStrings.subscriptionPremiumTitle,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                    height: 1.3,
                  ),
                ),
              ),
              CupertinoSwitch(
                value: enabled,
                activeTrackColor: AppColors.primaryMint,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _BenefitRow(text: AppStrings.subscriptionPremiumBenefit1),
          const SizedBox(height: 6),
          const _BenefitRow(text: AppStrings.subscriptionPremiumBenefit2),
          const Spacer(),
          const Text(
            AppStrings.subscriptionPremiumPrice,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryMintDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '✔️',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textBlack,
            ),
          ),
        ),
      ],
    );
  }
}
