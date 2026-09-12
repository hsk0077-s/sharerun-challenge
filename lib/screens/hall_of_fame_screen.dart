import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/profile/user_profile_notifier.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';
import '../features/wallet/providers/wallet_provider.dart';

/// 명예의 전당 화면 (Screen 26).
class HallOfFameScreen extends ConsumerWidget {
  const HallOfFameScreen({super.key});

  static const _saveNavy = Color(0xFF1A2B4A);
  static const _donateValue = 500;

  static const _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Colors.white],
  );

  void _onDonate(BuildContext context, WidgetRef ref) {
    final wallet = ref.read(walletProvider);
    if (wallet.valueBalance < _donateValue) {
      ref.read(walletProvider.notifier).creditValue(_donateValue * 10);
    }
    final after = ref.read(walletProvider);
    if (after.valueBalance < _donateValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VALUE가 부족합니다.')),
      );
      return;
    }
    ref.read(walletProvider.notifier).debitValue(_donateValue);
    unawaited(
      ref.read(userProfileNotifierProvider.notifier).writeTransactionReceipt(
            title: AppStrings.hallOfFameDonateHistoryTitle,
            amount: -_donateValue,
            assetType: 'VALUE',
          ),
    );
    final left = ref.read(walletProvider).valueBalance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '명예의 전당 기부 완료 (−$_donateValue VALUE) · 잔액 $left',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppRouteNav.popOrHome(context);
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SRCGradientBackground(
        gradient: _screenGradient,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;

            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _HallOfFameHeader(
                              onBack: () => AppRouteNav.popOrHome(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: SeraphimHonorBillboard(),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _HeroLeaderCard(
                              width: contentWidth - 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _RankingCard(
                              medal: '🥈',
                              rankLabel: AppStrings.hallOfFameRank2Label,
                              subtitle: AppStrings.hallOfFameRank2Subtitle,
                              badgeLabel: AppStrings.hallOfFameRank2Badge,
                              valueLabel: AppStrings.hallOfFameRank2Value,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _RankingCard(
                              medal: '🥉',
                              rankLabel: AppStrings.hallOfFameRank3Label,
                              subtitle: AppStrings.hallOfFameRank3Subtitle,
                              badgeLabel: AppStrings.hallOfFameRank3Badge,
                              valueLabel: AppStrings.hallOfFameRank3Value,
                            ),
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
                          width: contentWidth * 0.9,
                          height: AppShapes.buttonHeight,
                          child: FilledButton(
                            onPressed: () => _onDonate(context, ref),
                            style: FilledButton.styleFrom(
                              backgroundColor: _saveNavy,
                              foregroundColor: AppColors.textWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppShapes.cardRadius,
                                ),
                              ),
                            ),
                            child: Text(
                              AppStrings.hallOfFameDonateCta,
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
                ],
              ),
            );
          },
        ),
      ),
    ),
    );
  }
}

class _HallOfFameHeader extends StatelessWidget {
  _HallOfFameHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textBlack,
              iconSize: 22,
              onPressed: onBack,
            ),
          ),
          Text(
            AppStrings.hallOfFameTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 17),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeroLeaderCard extends StatelessWidget {
  _HeroLeaderCard({required this.width});

  final double width;

  static final _donationGold = Color(0xFF8D6E3B);
  static final _haloGold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 300,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(color: Colors.amber, width: 3.0),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.hallOfFameLeaderTitle,
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Center(child: _LeaderProfile(haloGold: _haloGold)),
            Spacer(),
            Text(
              AppStrings.hallOfFameLeaderName,
              style: AppTextStyles.header1.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              AppStrings.hallOfFameLeaderDonation,
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _donationGold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderProfile extends StatelessWidget {
  _LeaderProfile({required this.haloGold});

  final Color haloGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: haloGold.withValues(alpha: 0.55),
            blurRadius: 22,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: AppColors.agreementBoxFill,
        child: Icon(
          Icons.person_rounded,
          size: 40,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  _RankingCard({
    required this.medal,
    required this.rankLabel,
    required this.subtitle,
    required this.badgeLabel,
    required this.valueLabel,
  });

  final String medal;
  final String rankLabel;
  final String subtitle;
  final String badgeLabel;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(medal, style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rankLabel,
                textScaler: TextScaler.noScaling,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                textScaler: TextScaler.noScaling,
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
          Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                badgeLabel,
                textScaler: TextScaler.noScaling,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 2),
              Text(
                valueLabel,
                textScaler: TextScaler.noScaling,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
