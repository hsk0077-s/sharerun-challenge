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
class HallOfFameScreen extends ConsumerStatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  ConsumerState<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends ConsumerState<HallOfFameScreen> {
  static const _saveNavy = Color(0xFF1A2B4A);
  static const _donateValue = 500;

  static const _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Colors.white],
  );

  /// No server VALUE donation exists for this screen. Latch so a second tap
  /// cannot debit again while the local receipt write is in flight.
  var _donating = false;

  Future<void> _onDonate() async {
    if (_donating) return;
    _donating = true;
    setState(() {});
    try {
      final balance = ref.read(walletProvider).valueBalance;
      if (balance < _donateValue) {
        _snack('VALUE가 부족합니다.');
        return;
      }
      ref.read(walletProvider.notifier).debitValue(_donateValue);
      await ref
          .read(userProfileNotifierProvider.notifier)
          .writeTransactionReceipt(
            title: AppStrings.hallOfFameDonateHistoryTitle,
            amount: -_donateValue,
            assetType: 'VALUE',
          );
      if (!mounted) return;
      final left = ref.read(walletProvider).valueBalance;
      _snack(
        '이 기기에서 $_donateValue VALUE를 차감했습니다. '
        '명예의 전당 순위에는 반영되지 않습니다. · 잔액 $left',
      );
    } finally {
      _donating = false;
      if (mounted) setState(() {});
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _EmptyLeaderboard(),
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
                              onPressed: _donating ? null : _onDonate,
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
  const _HallOfFameHeader({required this.onBack});

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
            AppStrings.hallOfFameTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 17),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
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
      child: Text(
        '아직 기록이 없어요',
        textAlign: TextAlign.center,
        style: AppTextStyles.agreementLabel.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}
