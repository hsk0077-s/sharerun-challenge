import 'package:flutter/material.dart';

import '../../core/constants/economy_constants.dart';
import '../../core/strings/app_strings.dart';
import '../../core/theme/theme.dart';
import '../profile/widgets/retention_widgets.dart';

/// 지갑 카드. SHARE·VALUE 잔액을 누르면 충전·기부 화면으로 간다.
/// 홈에서 마이로 옮겼다. 글자와 눌렀을 때 가는 곳은 그대로다.
class HomeWalletCard extends StatelessWidget {
  const HomeWalletCard({
    required this.share,
    required this.value,
    required this.onWalletTap,
    required this.onShareTap,
    required this.onValueTap,
    required this.dailyKm,
    super.key,
  });

  final int share;
  final int value;
  final VoidCallback onWalletTap;
  final VoidCallback onShareTap;
  final VoidCallback onValueTap;
  final double dailyKm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      padding: EdgeInsets.all(tokens.spacing.lg),
      borderColor: tokens.colors.accent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            key: const Key('home-my-wallet-icon'),
            behavior: HitTestBehavior.opaque,
            onTap: onWalletTap,
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: tokens.colors.accent,
                  size: 22,
                ),
                SizedBox(width: tokens.spacing.xs),
                Text(
                  AppStrings.dashboardMyWallet,
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          _WalletTapSegment(
            onTap: onShareTap,
            child: Text(
              AppStrings.dashboardShareBalanceOf(_comma(share)),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.colors.accent,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          _WalletTapSegment(
            onTap: onValueTap,
            child: Text(
              AppStrings.dashboardValueBalanceOf(_comma(value)),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.colors.donation,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          DailyCapGauge(dailyKm: dailyKm),
        ],
      ),
    );
  }
}

/// 등급이 아직 없는 사람에게 보이는 "등급 배정 n/3회" 카드. 누르면 등급 심사 화면.
class HomeGradeEvalBanner extends StatelessWidget {
  const HomeGradeEvalBanner({
    required this.completedCount,
    required this.onTap,
    super.key,
  });

  final int completedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    const total = EconomyConstants.trialRunsRequired;
    final progress = (completedCount / total).clamp(0.0, 1.0);
    return Material(
      color: tokens.colors.accent.withValues(alpha: 0.10),
      borderRadius: tokens.radii.card,
      child: InkWell(
        key: const ValueKey('grade-eval-banner'),
        onTap: onTap,
        borderRadius: tokens.radii.card,
        splashColor: tokens.colors.accent.withValues(alpha: 0.15),
        child: Container(
          padding: EdgeInsets.all(tokens.spacing.md),
          decoration: BoxDecoration(
            borderRadius: tokens.radii.card,
            border: Border.all(
              color: tokens.colors.accent.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GradeProgressBar(progress: progress),
              SizedBox(height: tokens.spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.dashboardGradeRunLabel,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.colors.accent,
                      ),
                    ),
                  ),
                  Text(
                    '$completedCount/$total회 완료 >',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.colors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTapSegment extends StatelessWidget {
  const _WalletTapSegment({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radii.sm),
        splashColor: tokens.colors.accent.withValues(alpha: 0.15),
        highlightColor: tokens.colors.accent.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spacing.xs - 2,
            horizontal: tokens.spacing.xxs,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradeProgressBar extends StatelessWidget {
  const _GradeProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radii.xs),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: tokens.colors.outline),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tokens.colors.donation, tokens.colors.primary],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _comma(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final formatted = buffer.toString();
  return value < 0 ? '-$formatted' : formatted;
}
