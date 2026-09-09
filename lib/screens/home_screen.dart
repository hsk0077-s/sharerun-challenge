import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/theme/app_colors.dart' as src_colors;
import '../core/widgets/async_value_section.dart';
import '../core/widgets/currency_badge.dart';
import '../data/models/tournament_model.dart';
import '../data/models/wallet_model.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/profile/widgets/gender_profile_avatar.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';
import '../features/profile/widgets/retention_widgets.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import 'in_app_billing_screen.dart';
import 'in_challenge_screen.dart';
import 'store_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _linkingWatch = false;
  var _startingRun = false;
  var _openingSolo = false;

  void _onOpenInAppBilling() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.inAppBilling);
        return;
      } catch (_) {
        context.push(RouteNames.inAppBilling);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.inAppBilling,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  void _onOpenStore({required StoreFocus focus}) {
    ref.read(storeFocusProvider.notifier).setFocus(focus);
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(
          RouteNames.store,
          queryParameters: {'focus': focus.name},
        );
        return;
      } catch (_) {
        context.go(RouteNames.storeWithFocus(focus.name));
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.storeWithFocus(focus.name),
      extra: focus,
      materialBuilder: (_) => StoreScreen(initialFocus: focus),
    );
  }

  void _onOpenSoloRun() {
    if (_openingSolo) return;
    _openingSolo = true;
    if (GoRouter.maybeOf(context) != null) {
      context.pushNamed(RouteNames.soloPedometer);
    } else {
      Navigator.of(context).pushNamed(RouteNames.soloPedometerPath);
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _openingSolo = false;
    });
  }

  static const _healthTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVITY_INTENSITY,
  ];

  static const _healthPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(activeWalletProvider);
    final userTierAsync = ref.watch(activeUserTierProvider);
    final challengesAsync = ref.watch(tournamentRoomsProvider);
    final joinedIds = ref.watch(joinedTournamentIdsProvider).value ?? const {};
    final onboarding = ref.watch(onboardingProvider);
    final showGradeEval =
        onboarding.currentStep != OnboardingStep.completed;
    final trialDone = onboarding.preliminaryPaceSeconds.length.clamp(0, 5);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const HomeUserIdentityHeader(),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _linkingWatch
                ? null
                : () async {
                    try {
                      final health = Health();
                      await health.configure();
                      final granted = await health.requestAuthorization(
                        [
                          HealthDataType.HEART_RATE,
                          HealthDataType.STEPS,
                          HealthDataType.DISTANCE_DELTA,
                          HealthDataType.WORKOUT,
                          HealthDataType.ACTIVITY_INTENSITY,
                        ],
                        permissions: [
                          HealthDataAccess.READ,
                          HealthDataAccess.READ,
                          HealthDataAccess.READ,
                          HealthDataAccess.READ,
                          HealthDataAccess.READ,
                        ],
                      );
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted
                                ? 'Health Connect 권한이 허용되었습니다.'
                                : 'Health Connect 권한이 거부되었거나 취소되었습니다.',
                          ),
                        ),
                      );
                    } catch (error) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Health Connect 권한 요청 실패: $error'),
                        ),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neonLime,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: _linkingWatch
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.watch_rounded),
            label: Text(
              _linkingWatch ? '연동 중...' : '워치 연동',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (showGradeEval) ...[
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(RouteNames.preliminaryEvalName),
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text(
              '등급 심사 (예비 $trialDone/5회)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: src_colors.AppColors.tealAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'My Wallet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AsyncValueSection<WalletModel>(
          asyncValue: walletAsync,
          dataBuilder: (context, wallet) => Row(
            children: [
              Expanded(
                child: _HomeWalletBadgeTap(
                  onTap: _onOpenInAppBilling,
                  child: CurrencyBadge(
                    label: 'Share',
                    amount: wallet.shareBalance,
                    color: AppColors.electricBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeWalletBadgeTap(
                  onTap: () => _onOpenStore(focus: StoreFocus.items),
                  child: CurrencyBadge(
                    label: 'Diamond',
                    amount: wallet.diamondBalance,
                    color: Colors.purpleAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeWalletBadgeTap(
                  onTap: () => _onOpenStore(focus: StoreFocus.donate),
                  child: CurrencyBadge(
                    label: 'Value',
                    amount: wallet.valueTokenBalance,
                    color: AppColors.neonLime,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DailyCapGauge(dailyKm: ref.watch(retentionDailyKmProvider)),
        const SizedBox(height: 12),
        SoloQuickStartBanner(onTap: _onOpenSoloRun),
        const SizedBox(height: 14),
        const AngelSponsorBanner(),
        const SizedBox(height: 42),
        Center(
          child: SizedBox.square(
            dimension: 184,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neonLime,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                elevation: 12,
                shadowColor: AppColors.neonLime.withValues(alpha: 0.4),
              ),
              onPressed: () async {
                if (_startingRun) {
                  return;
                }
                _startingRun = true;

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final isHealthDataAgreed =
                      prefs.getBool('isHealthDataAgreed') ?? false;
                  if (!isHealthDataAgreed) {
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('마이페이지에서 민감정보 수집에 동의해주세요'),
                        backgroundColor: AppColors.dangerRed,
                      ),
                    );
                    return;
                  }

                  final health = Health();
                  await health.configure();

                  var granted = await health.hasPermissions(
                    _healthTypes,
                    permissions: _healthPermissions,
                  );

                  if (granted != true) {
                    await health.requestAuthorization(
                      _healthTypes,
                      permissions: _healthPermissions,
                    );
                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );
                    granted = await health.hasPermissions(
                      _healthTypes,
                      permissions: _healthPermissions,
                    );
                  }

                  if (granted == false) {
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Health Connect 권한이 필요합니다. 상단 워치 연동을 먼저 완료해 주세요.',
                        ),
                      ),
                    );
                    return;
                  }

                  if (!mounted) {
                    return;
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const InChallengeScreen(),
                      ),
                    );
                  });
                } finally {
                  _startingRun = false;
                }
              },
              child: const Text(
                'START',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text('Active Challenges', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        AsyncValueSection<List<TournamentModel>>(
          asyncValue: challengesAsync,
          dataBuilder: (context, rooms) {
            final userTier = userTierAsync.value ?? 1;
            final activeChallenges = rooms
                .where((room) => room.isRecruiting)
                .take(10)
                .toList();

            if (activeChallenges.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text('No recruiting tournament rooms yet.'),
              );
            }

            return SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activeChallenges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final room = activeChallenges[index];
                  return _ActiveChallengeCard(
                    room: room,
                    userTier: userTier,
                    isJoined: joinedIds.contains(room.id),
                    onTap: () =>
                        context.go(RouteNames.tournamentDetail(room.id)),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Text('다이아몬드 잔액', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AsyncValueSection<WalletModel>(
          asyncValue: walletAsync,
          dataBuilder: (context, wallet) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.purpleAccent.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  color: Colors.purpleAccent,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diamond Balance',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        wallet.diamondBalance.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.purpleAccent,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ActiveChallengeCard extends StatelessWidget {
  const _ActiveChallengeCard({
    required this.room,
    required this.userTier,
    required this.isJoined,
    required this.onTap,
  });

  final TournamentModel room;
  final int userTier;
  final bool isJoined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = room.lockedForTier(userTier);
    final full = room.isFull;

    return Material(
      color: AppColors.cardBlack,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    locked ? Icons.lock_rounded : Icons.emoji_events_rounded,
                    color: locked ? AppColors.textSecondary : AppColors.neonLime,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      room.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${room.targetDistanceKm.toStringAsFixed(1)}km · ${room.entryFeeShare} Share',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                room.recruitmentSummary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                isJoined
                    ? 'Joined · +${room.winnerRewardValue} Value on verified finish'
                    : locked
                        ? 'Tier ${room.requiredTier} room locked'
                        : full
                            ? 'Room full'
                            : '+${room.winnerRewardValue} Value on verified finish',
                style: TextStyle(
                  color: isJoined || (!full && !locked)
                      ? AppColors.neonLime
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWalletBadgeTap extends StatelessWidget {
  const _HomeWalletBadgeTap({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: src_colors.AppColors.tealAccent.withValues(alpha: 0.15),
        highlightColor: src_colors.AppColors.tealAccent.withValues(alpha: 0.06),
        child: child,
      ),
    );
  }
}
