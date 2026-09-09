import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/constants/economy_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../screens/solo_pedometer_screen.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../providers/practice_streak_provider.dart';

/// 지갑 카드 내부 일일 5km 채굴 게이지.
class DailyCapGauge extends StatelessWidget {
  const DailyCapGauge({super.key, required this.dailyKm});

  final double dailyKm;

  @override
  Widget build(BuildContext context) {
    final cap = EconomyConstants.dailyCapKm;
    final km = dailyKm < 0 ? 0.0 : dailyKm;
    final progress = (km / cap).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${km.toStringAsFixed(1)}km / ${cap.toStringAsFixed(1)}km 채굴 완료 ($percent%)',
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.tealAccent,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                const ColoredBox(
                  color: AppColors.settingsBackground,
                  child: SizedBox.expand(),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryMintLight,
                          AppColors.tealAccent,
                        ],
                      ),
                    ),
                    child: SizedBox.expand(),
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
  static const _mintGlow = Color(0xFF00D2B4);

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
      final uid = ref.read(activeUserProfileProvider).asData?.value.uid ?? '';
      final today = PedometerKstClock.dateKey();
      final prefix = 'solo_pedo_${uid}_$today';
      final backup =
          prefs.getInt(PedometerKstClock.backupStepsKey(today)) ?? 0;
      final legacy = prefs.getInt('$prefix.steps') ?? 0;
      final claimed = prefs.getInt('$prefix.claimedSteps') ?? 0;
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
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final pulse = 0.32 + _glow.value * 0.58;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: canCollect
                ? [
                    BoxShadow(
                      color: _mintGlow.withValues(alpha: pulse),
                      blurRadius: 20 + _glow.value * 16,
                      spreadRadius: 2 + _glow.value * 4,
                    ),
                    BoxShadow(
                      color: _mintGlow.withValues(alpha: pulse * 0.7),
                      blurRadius: 10 + _glow.value * 8,
                      spreadRadius: 0.5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.tealAccent.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primaryMintLight,
                  AppColors.tealAccent,
                ],
              ),
              border: Border.all(
                color: canCollect
                    ? _mintGlow
                    : AppColors.pulseCyan.withValues(alpha: 0.55),
                width: canCollect ? 2 : 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textWhite,
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
    final activities =
        ref.watch(recentActivitiesProvider).value ?? const [];
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
              color: stamped
                  ? AppColors.tealAccent
                  : AppColors.borderLight,
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
