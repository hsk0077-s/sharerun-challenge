import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/constants/economy_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../screens/solo_pedometer_screen.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../../pedometer/pedometer_harvest_ledger.dart';
import '../providers/practice_streak_provider.dart';

/// 지갑 카드 내부 일일 5km 채굴 게이지.
class DailyCapGauge extends StatelessWidget {
  const DailyCapGauge({super.key, required this.dailyKm});

  final double dailyKm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final cap = EconomyConstants.dailyCapKm;
    final km = dailyKm < 0 ? 0.0 : dailyKm;
    final progress = (km / cap).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${km.toStringAsFixed(1)}km / ${cap.toStringAsFixed(1)}km 채굴 완료 ($percent%)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.colors.accent,
              ),
        ),
        SizedBox(height: tokens.spacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radii.sm),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                ColoredBox(
                  color: tokens.colors.outline,
                  child: const SizedBox.expand(),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tokens.colors.primary,
                          tokens.colors.accent,
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 워킹챌린지 홈 CTA. 오늘 걸음 > 주운 걸음이면 줍기 글로우로 전환.
class SoloQuickStartBanner extends ConsumerStatefulWidget {
  const SoloQuickStartBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  ConsumerState<SoloQuickStartBanner> createState() =>
      _SoloQuickStartBannerState();
}

class _SoloQuickStartBannerState extends ConsumerState<SoloQuickStartBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  var _storedSteps = 0;
  var _claimedSteps = 0;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hydrateStepsFromPrefs());
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _hydrateStepsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid ??
          ref.read(activeUserProfileProvider).asData?.value.uid ??
          '';
      final today = PedometerKstClock.dateKey();
      final prefix = PedometerHarvestLedger.prefix(uid: uid, dateKey: today);
      final backup = prefs.getInt(PedometerKstClock.backupStepsKey(today)) ?? 0;
      final legacy = prefs.getInt('$prefix.steps') ?? 0;
      final claimed = PedometerHarvestLedger.coalesceClaimed(
        current: 0,
        fromTodayKey:
            prefs.getInt(PedometerHarvestLedger.todayClaimedKey(today)) ?? 0,
        fromPrefix: prefs.getInt('$prefix.claimedSteps') ?? 0,
        fromGlobal: PedometerHarvestLedger.claimedFromGlobal(
          storedDate:
              prefs.getString(PedometerHarvestLedger.globalClaimedDateKey),
          storedClaimed:
              prefs.getInt(PedometerHarvestLedger.globalClaimedKey) ?? 0,
          todayKey: today,
        ),
        steps: backup > legacy ? backup : legacy,
      );
      final steps = backup > legacy ? backup : legacy;
      if (!mounted) return;
      if (_storedSteps == steps && _claimedSteps == claimed) return;
      setState(() {
        _storedSteps = steps;
        _claimedSteps = claimed;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final liveSteps = ref.watch(pedometerStateProvider).steps;
    ref.listen<double>(walkingPendingShareProvider, (prev, next) {
      unawaited(_hydrateStepsFromPrefs());
    });
    ref.listen<PedometerData>(pedometerStateProvider, (prev, next) {
      unawaited(_hydrateStepsFromPrefs());
    });
    final steps = liveSteps > _storedSteps ? liveSteps : _storedSteps;
    final canCollect = steps > 0 && steps > _claimedSteps;
    final label = canCollect ? '워킹챌린지 코인줍기' : '워킹 챌린지 시작';
    final tokens = context.srcTokens;
    final glowColor = tokens.colors.primary;
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final pulse = 0.32 + _glow.value * 0.58;
        return Container(
          decoration: BoxDecoration(
            borderRadius: tokens.radii.panel,
            boxShadow: canCollect
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: pulse),
                      blurRadius: 20 + _glow.value * 16,
                      spreadRadius: 2 + _glow.value * 4,
                    ),
                    BoxShadow(
                      color: glowColor.withValues(alpha: pulse * 0.7),
                      blurRadius: 10 + _glow.value * 8,
                      spreadRadius: 0.5,
                    ),
                  ]
                : AppShadows.card,
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: tokens.radii.panel,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: tokens.radii.panel,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  tokens.colors.primary,
                  tokens.colors.accent,
                ],
              ),
              border: Border.all(
                color: canCollect
                    ? glowColor
                    : tokens.colors.accent.withValues(alpha: 0.55),
                width: canCollect ? 2 : 1.2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.md,
                vertical: tokens.spacing.sm,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tokens.colors.onPrimary,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 마이페이지 월–일 실천 스트릭.
class DailyStreakCard extends ConsumerWidget {
  const DailyStreakCard({super.key});

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(retentionAlertControllerProvider);
    final streakState = ref.watch(practiceStreakProvider);
    final streak = streakState.count;
    if (streakState.diaRewardPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final current = ref.read(practiceStreakProvider);
        if (!current.diaRewardPending) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('+10 Dia 획득!')),
        );
        ref.read(practiceStreakProvider.notifier).consumeDiaReward();
      });
    }
    final activities = ref.watch(recentActivitiesProvider).value ?? const [];
    final now = DateTime.now();
    final marked = RetentionMetrics.markedWeekdays(activities, now);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🔥 $streak일째 불꽃 유지 중!',
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.warningOrange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '7일 연속 실천 완료 시 10 다이아몬드(DIA) 보너스 획득! 💎',
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _StreakStamp(
                    label: _labels[i],
                    stamped: marked.contains(i + 1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakStamp extends StatelessWidget {
  const _StreakStamp({
    required this.label,
    required this.stamped,
  });

  final String label;
  final bool stamped;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stamped
                ? AppColors.tealAccent.withValues(alpha: 0.16)
                : AppColors.settingsBackground,
            border: Border.all(
              color: stamped ? AppColors.tealAccent : AppColors.borderLight,
            ),
          ),
          child: Icon(
            Icons.directions_run_rounded,
            size: 18,
            color: stamped ? AppColors.tealAccent : AppColors.textGreyLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: stamped ? FontWeight.w700 : FontWeight.w500,
            color: stamped ? AppColors.tealAccent : AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
