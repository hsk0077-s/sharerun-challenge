import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:share_run_challenge/core/theme/theme.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/auth/health_data_consent_store.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/widgets/async_value_section.dart';
import '../core/widgets/currency_badge.dart';
import '../data/models/tournament_model.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/profile/widgets/gender_profile_avatar.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';
import '../features/profile/widgets/retention_widgets.dart';
import '../features/run_tracking/utils/home_start_gate.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/tournaments/providers/local_joined_ids_provider.dart';
import '../features/wallet/debug_economy_status.dart';
import '../features/wallet/providers/wallet_provider.dart';
import 'in_app_billing_screen.dart';
import 'in_challenge_screen.dart';
import 'my_wallet_screen.dart';
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

  Future<void> _onStartRun() async {
    if (_startingRun) {
      return;
    }
    _startingRun = true;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final firebaseUser = ref.read(authStateChangesProvider).value;
      final localUid = ref.read(persistedAuthSessionProvider)?.uid;
      final signedIn =
          firebaseUser != null || (localUid != null && localUid.isNotEmpty);
      final profileConsent =
          ref.read(activeUserProfileProvider).value?.healthDataConsent ?? false;
      final prefsConsent = await HealthDataConsentStore().readAgreed();
      final blocked = HomeStartGate.startBlockReason(
        signedIn: signedIn,
        healthConsent: profileConsent || prefsConsent,
      );
      if (blocked != null) {
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(blocked),
            backgroundColor: context.srcTokens.colors.danger,
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
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final wallet = ref.watch(walletProvider);
    final userTierAsync = ref.watch(activeUserTierProvider);
    final challengesAsync = ref.watch(tournamentRoomsProvider);
    final joinedIds = ref.watch(effectiveJoinedTournamentIdsProvider);
    final onboarding = ref.watch(onboardingProvider);
    final showGradeEval = onboarding.currentStep != OnboardingStep.completed;
    final trialDone = onboarding.preliminaryPaceSeconds.length.clamp(0, 5);

    return ListView(
      padding: EdgeInsets.all(tokens.spacing.page),
      children: [
        const HomeUserIdentityHeader(),
        SizedBox(height: tokens.spacing.md),
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
              backgroundColor: tokens.colors.primary,
              foregroundColor: tokens.colors.onPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.md,
                vertical: tokens.spacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: tokens.radii.capsule,
              ),
            ),
            icon: _linkingWatch
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.colors.onPrimary,
                    ),
                  )
                : const Icon(Icons.watch_rounded),
            label: Text(
              _linkingWatch ? '연동 중...' : '워치 연동',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: tokens.colors.onPrimary,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        if (showGradeEval) ...[
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(RouteNames.preliminaryEvalName),
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text(
              '등급 심사 (예비 $trialDone/5회)',
              style:
                  textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(height: tokens.spacing.xl),
        ] else
          SizedBox(height: tokens.spacing.xl),
        SrcSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                key: const Key('home-my-wallet-icon'),
                behavior: HitTestBehavior.opaque,
                onTap: () => MyWalletScreen.open(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: tokens.colors.accent,
                      size: 22,
                    ),
                    SizedBox(width: tokens.spacing.xs),
                    Expanded(
                      child: Text(
                        'My Wallet',
                        style: textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              Row(
                children: [
                  Expanded(
                    child: _HomeWalletBadgeTap(
                      onTap: _onOpenInAppBilling,
                      child: CurrencyBadge(
                        label: 'Share',
                        amount: wallet.shareBalance,
                        color: tokens.colors.accent,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  Expanded(
                    child: _HomeWalletBadgeTap(
                      onTap: () => _onOpenStore(focus: StoreFocus.items),
                      child: CurrencyBadge(
                        label: 'Diamond',
                        amount: wallet.diamondBalance,
                        color: tokens.colors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  Expanded(
                    child: _HomeWalletBadgeTap(
                      onTap: () => _onOpenStore(focus: StoreFocus.donate),
                      child: CurrencyBadge(
                        label: 'Value',
                        amount: wallet.valueBalance,
                        color: tokens.colors.donation,
                      ),
                    ),
                  ),
                ],
              ),
              const DebugEconomyStatusLine(),
              SizedBox(height: tokens.spacing.sm),
              DailyCapGauge(dailyKm: ref.watch(retentionDailyKmProvider)),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        SoloQuickStartBanner(onTap: _onOpenSoloRun),
        SizedBox(height: tokens.spacing.sm),
        const AngelSponsorBanner(),
        SizedBox(height: tokens.spacing.xxl),
        _HomeStartButton(onPressed: _onStartRun),
        SizedBox(height: tokens.spacing.xxl),
        Text('Active Challenges', style: textTheme.titleLarge),
        SizedBox(height: tokens.spacing.md),
        AsyncValueSection<List<TournamentModel>>(
          asyncValue: challengesAsync,
          dataBuilder: (context, rooms) {
            final userTier = userTierAsync.value ?? 1;
            final activeChallenges =
                rooms.where((room) => room.isRecruiting).take(10).toList();

            if (activeChallenges.isEmpty) {
              return SrcSurfaceCard(
                child: Text(
                  'No recruiting tournament rooms yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.colors.muted,
                  ),
                ),
              );
            }

            return SizedBox(
              height: 156,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activeChallenges.length,
                separatorBuilder: (_, __) => SizedBox(width: tokens.spacing.sm),
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
        SizedBox(height: tokens.spacing.xl),
        Text('다이아몬드 잔액', style: textTheme.titleLarge),
        SizedBox(height: tokens.spacing.sm),
        SrcSurfaceCard(
          borderColor: tokens.colors.primary.withValues(alpha: 0.45),
          child: Row(
            children: [
              Icon(
                Icons.diamond_rounded,
                color: tokens.colors.primary,
                size: 36,
              ),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diamond Balance',
                      style: textTheme.labelMedium?.copyWith(
                        color: tokens.colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.xxs),
                    Text(
                      wallet.diamondBalance.toString(),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tokens.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final locked = room.lockedForTier(userTier);
    final full = room.isFull;
    final highlight = isJoined || (!full && !locked);
    final highlightColor =
        highlight ? tokens.colors.donation : tokens.colors.muted;

    return SrcSurfaceCard(
      width: 240,
      height: 156,
      padding: EdgeInsets.all(tokens.spacing.sm),
      onTap: onTap,
      borderColor: highlight
          ? tokens.colors.donation.withValues(alpha: 0.35)
          : tokens.colors.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                locked ? Icons.lock_rounded : Icons.emoji_events_rounded,
                color: locked ? tokens.colors.muted : tokens.colors.primary,
                size: 18,
              ),
              SizedBox(width: tokens.spacing.xs),
              Expanded(
                child: Text(
                  room.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            '${room.targetDistanceKm.toStringAsFixed(1)}km · ${room.entryFeeShare} Share',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
          ),
          SizedBox(height: tokens.spacing.xxs),
          Text(
            room.recruitmentSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: tokens.colors.muted),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final tokens = context.srcTokens;
    return Material(
      color: Colors.transparent,
      borderRadius: tokens.radii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: tokens.radii.card,
        splashColor: tokens.colors.accent.withValues(alpha: 0.15),
        highlightColor: tokens.colors.accent.withValues(alpha: 0.06),
        child: child,
      ),
    );
  }
}

class _HomeStartButton extends StatelessWidget {
  const _HomeStartButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _size = 184.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: tokens.colors.primary.withValues(alpha: 0.32),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            ...AppShadows.raised,
          ],
        ),
        child: SizedBox.square(
          dimension: _size,
          child: FilledButton(
            key: const Key('home-start-cta'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: const CircleBorder(),
              elevation: 0,
              padding: EdgeInsets.zero,
              minimumSize: const Size(_size, _size),
            ),
            onPressed: onPressed,
            child: Text(
              'START',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    letterSpacing: 1.2,
                    color: scheme.onPrimary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
