import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/constants/economy_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../screens/solo_pedometer_screen.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../../pedometer/pedometer_harvest_ledger.dart';
import '../../pedometer/pedometer_health_cap.dart';
import '../../home/home_cards.dart';
import '../my_page_activity_stats.dart';

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

/// 홈 맨 위 걸음 카드. 오늘 걸음과 줍기 대기 SHARE를 보여 주고, 줍기는 걷기 챌린지
/// 화면에서 한다(서버가 확인한 뒤에만 SHARE가 늘어난다). 걸음 수 기준은 걷기
/// 화면과 같은 장부(`PedometerHarvestLedger`)다.
class SoloQuickStartBanner extends ConsumerStatefulWidget {
  const SoloQuickStartBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  static const stepsKey = Key('home-hero-steps');
  static const pendingKey = Key('home-hero-pending');
  static const receivedKey = Key('home-hero-received');
  static const buttonKey = Key('home-hero-button');
  static const otherPhoneKey = Key('home-hero-hint');

  @override
  ConsumerState<SoloQuickStartBanner> createState() =>
      _SoloQuickStartBannerState();
}

/// 카드에 쓰는 숫자. 걸음 수와 이미 주운 걸음 수에서만 나온다.
class HomeHeroNumbers {
  const HomeHeroNumbers({
    required this.steps,
    required this.pendingShare,
    required this.receivedShare,
    required this.progress,
  });

  /// [serverReceived]: 서버가 오늘 계정에 지급한 SHARE(같은 계정은 어느 폰에서나 같다).
  factory HomeHeroNumbers.from({
    required int steps,
    required int claimed,
    required int serverReceived,
  }) {
    final safeSteps = steps < 0 ? 0 : steps;
    return HomeHeroNumbers(
      steps: safeSteps,
      pendingShare: PedometerHarvestLedger.pendingShareFloor(
        steps: safeSteps,
        claimedSteps: claimed,
      ),
      receivedShare: serverReceived < 0 ? 0 : serverReceived,
      progress:
          (safeSteps / PedometerHarvestLedger.stepsForDailyCap).clamp(0.0, 1.0),
    );
  }

  final int steps;
  final int pendingShare;
  final int receivedShare;
  final double progress;
}

class _SoloQuickStartBannerState extends ConsumerState<SoloQuickStartBanner> {
  var _storedSteps = 0;
  var _claimedSteps = 0;

  static const _green = Color(0xFF0E3B2E);
  static const _greenLight = Color(0xFF1B6B54);
  static const _gold = Color(0xFFE8B84B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hydrateStepsFromPrefs());
    });
  }

  Future<void> _hydrateStepsFromPrefs() async {
    try {
      final prefs = await PedometerHealthCap.fresh();
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid ??
          ref.read(activeUserProfileProvider).asData?.value.uid ??
          '';
      final today = PedometerKstClock.dateKey();
      final prefix = PedometerHarvestLedger.prefix(uid: uid, dateKey: today);
      final backup = prefs.getInt(PedometerKstClock.backupStepsKey(today)) ?? 0;
      final legacy = prefs.getInt('$prefix.steps') ?? 0;
      final steps = PedometerHealthCap.cap(
        backup > legacy ? backup : legacy,
        PedometerHealthCap.fromPrefs(prefs, todayKey: today),
      );
      final claimed = PedometerHarvestLedger.coalesceClaimed(
        current: _claimedSteps,
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
        fromSession: PedometerHarvestLedger.sessionClaimed(today),
        steps: steps,
      );
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
    final today = PedometerKstClock.dateKey();
    final claimed = PedometerHarvestLedger.coalesceClaimed(
      current: _claimedSteps,
      fromTodayKey: 0,
      fromPrefix: 0,
      fromSession: PedometerHarvestLedger.sessionClaimed(today),
    );
    // 같은 계정의 다른 폰이 이미 올린 걸음은 서버 기준선에 들어 있다.
    final profile = ref.watch(activeUserProfileProvider).asData?.value;
    final serverToday = profile != null && profile.pedometerHarvestDateKey == today;
    final serverClaimed = serverToday ? profile.pedometerClaimedSteps : 0;
    final effectiveClaimed = claimed > serverClaimed ? claimed : serverClaimed;
    final numbers = HomeHeroNumbers.from(
      steps: steps,
      claimed: effectiveClaimed,
      serverReceived: PedometerHarvestLedger.displayHarvestedShare(
        dateKey: profile?.pedometerHarvestDateKey ?? '',
        harvestedShare: profile?.pedometerHarvestedShare ?? 0,
        todayKey: today,
      ),
    );
    final otherPhoneAhead = serverClaimed > steps;
    final canCollect = PedometerHarvestLedger.pickupReady(
      steps: steps,
      claimedSteps: effectiveClaimed,
    );
    final tier = ref.watch(activeUserTierStructProvider) ??
        UserTier.unratedFallback;
    final km = ref.watch(pedometerStateProvider).km;
    final tokens = context.srcTokens;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_green, _greenLight],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // 캐릭터 그림은 배경이 흰색이라 둥근 흰 판 안에 넣는다.
                  ClipOval(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Image.asset(
                        tier.avatarAssetPath,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 72, height: 72),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘 걸음 (이 폰)',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${groupedNumber(numbers.steps)} 걸음',
                            key: SoloQuickStartBanner.stepsKey,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          otherPhoneAhead
                              ? '다른 폰에서 이미 SHARE가 반영됐어요'
                              : '100걸음 → 10 SHARE · 하루 최대 600',
                          key: SoloQuickStartBanner.otherPhoneKey,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: numbers.progress,
                  minHeight: 6,
                  color: const Color(0xFF7FE3C0),
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HeroChip(
                      label: '오늘 거리 ${km.toStringAsFixed(1)} km',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroChip(
                      key: SoloQuickStartBanner.receivedKey,
                      label: '받은 SHARE ${numbers.receivedShare}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroChip(
                      key: SoloQuickStartBanner.pendingKey,
                      label: '줍기 대기 ${numbers.pendingShare}',
                      highlight: canCollect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: SoloQuickStartBanner.buttonKey,
                  onPressed: widget.onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: tokens.radii.card,
                    ),
                  ),
                  child: Text(
                    canCollect
                        ? '${numbers.pendingShare} SHARE 줍기'
                        : '걷기 챌린지 보기',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({super.key, required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? const Color(0xFFE8B84B) : Colors.white24,
        ),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: highlight ? const Color(0xFFE8B84B) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
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
    final stats = ref.watch(myPageActivityStatsProvider);
    final streak = stats.streakDays;
    final marked = stats.stampedWeekdays;

    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md,
        14,
        tokens.spacing.md,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🔥 $streak일째 불꽃 유지 중!',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: tokens.colors.warning,
            ),
          ),
          SizedBox(height: tokens.spacing.xxs + 2),
          Text(
            '7일 연속 실천 완료 시 10 다이아몬드(DIA) 보너스 획득! 💎',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.4,
              color: tokens.colors.muted,
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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stamped
                ? tokens.colors.accent.withValues(alpha: 0.16)
                : tokens.colors.outline.withValues(alpha: 0.45),
            border: Border.all(
              color: stamped ? tokens.colors.accent : tokens.colors.outline,
            ),
          ),
          child: Icon(
            Icons.directions_run_rounded,
            size: 18,
            color: stamped ? tokens.colors.accent : tokens.colors.muted,
          ),
        ),
        SizedBox(height: tokens.spacing.xxs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: stamped ? FontWeight.w700 : FontWeight.w500,
            color: stamped ? tokens.colors.accent : tokens.colors.muted,
          ),
        ),
      ],
    );
  }
}
