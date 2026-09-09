import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/wallet_state_provider.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';

/// 온보딩 플로우 기록 결과 화면 (Screen 11).
class OnboardingRunResultScreen extends ConsumerStatefulWidget {
  const OnboardingRunResultScreen({super.key});

  @override
  ConsumerState<OnboardingRunResultScreen> createState() =>
      _OnboardingRunResultScreenState();
}

class _OnboardingRunResultScreenState
    extends ConsumerState<OnboardingRunResultScreen> {
  static const _shareReward = 200;
  static const _valueReward = 100;
  static const _donationAmount = 100;
  static const _mockDistanceKm = '8.35';

  var _rewardsApplied = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _applyRunRewards();
      await _saveRunDataToFirebase();
    });
  }

  Future<void> _applyRunRewards() async {
    if (_rewardsApplied || !mounted) return;
    _rewardsApplied = true;
    final wallet = ref.read(walletProvider.notifier);
    wallet.creditShare(_shareReward);
    wallet.creditValueToken(_valueReward);
  }

  /// Placeholder for persisting the run log to Cloud Firestore.
  Future<void> _saveRunDataToFirebase() async {
    // ignore: avoid_print
    print(
      '[OnboardingRunResult] _saveRunDataToFirebase — '
      'distanceKm=$_mockDistanceKm, '
      'time=${AppStrings.runResultFinalTimeValue}, '
      'share=+$_shareReward, value=+$_valueReward',
    );
  }

  Future<void> _onDonate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('기부 확인'),
          content: const Text(
            '유니세프 결식아동에게 100 VALUE를 기부하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('기부하기'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final wallet = ref.read(walletProvider);
    if (wallet.valueTokenBalance < _donationAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기부할 VALUE가 부족합니다.')),
      );
      return;
    }

    ref.read(walletProvider.notifier).donateValueToken(_donationAmount);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기부가 성공적으로 완료되었습니다!')),
    );
  }

  Future<void> _onShare() async {
    final shareText =
        'SRC 앱에서 ${_mockDistanceKm}km 완주 후 기부에 동참했습니다! '
        '⏱ 기록: ${AppStrings.runResultFinalTimeValue}';

    // share_plus is not in pubspec — clipboard fallback.
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '클립보드에 기록이 복사되었습니다. SNS에 붙여넣기 해주세요!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    16,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    children: [
                      const _CelebrationGraphic(),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.runResultTitle,
                        style: AppTextStyles.header1.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const _RecordCard(),
                      const SizedBox(height: 14),
                      const _RewardCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppShapes.termsHorizontalPadding,
                  8,
                  AppShapes.termsHorizontalPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: AppColors.primaryMint,
                      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _onDonate,
                        child: SizedBox(
                          height: AppShapes.buttonHeight,
                          child: Center(
                            child: Text(
                              AppStrings.runResultDonate,
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.textBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: AppColors.garminAuthButton,
                      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _onShare,
                        child: SizedBox(
                          height: AppShapes.buttonHeight,
                          child: Center(
                            child: Text(
                              AppStrings.runResultShare,
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrationGraphic extends StatelessWidget {
  const _CelebrationGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 72,
            color: AppColors.primaryMint.withValues(alpha: 0.35),
          ),
          Positioned(
            top: 8,
            left: 24,
            child: Icon(
              Icons.auto_awesome,
              size: 28,
              color: AppColors.progressYellow.withValues(alpha: 0.9),
            ),
          ),
          Positioned(
            top: 16,
            right: 32,
            child: Icon(
              Icons.auto_awesome,
              size: 22,
              color: AppColors.primaryMint,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 48,
            child: _ConfettiDot(color: AppColors.error.withValues(alpha: 0.8)),
          ),
          Positioned(
            top: 28,
            right: 56,
            child: _ConfettiDot(color: AppColors.primaryMint),
          ),
          Positioned(
            bottom: 20,
            right: 40,
            child: _ConfettiDot(color: AppColors.progressYellow),
          ),
          Positioned(
            top: 40,
            left: 72,
            child: _ConfettiDot(color: const Color(0xFF42A5F5)),
          ),
        ],
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard();

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      child: Column(
        children: [
          _RecordLine(
            label: AppStrings.runResultFinalTimeLabel,
            value: AppStrings.runResultFinalTimeValue,
          ),
          const SizedBox(height: 12),
          _RecordLine(
            label: AppStrings.runResultAvgPaceLabel,
            value: AppStrings.runResultAvgPaceValue,
          ),
        ],
      ),
    );
  }
}

class _RecordLine extends StatelessWidget {
  const _RecordLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.agreementLabel.copyWith(fontSize: 16),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard();

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _ShareCoinIcon(size: 56),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.runResultShareAmount,
                    style: AppTextStyles.header1.copyWith(fontSize: 36),
                  ),
                  Text(
                    AppStrings.runResultShareEarned,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.agreementBoxFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.runResultValueReward,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ShareCoinIcon extends StatelessWidget {
  const _ShareCoinIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.progressYellow,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.progressYellow.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'S',
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.textWhite,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
