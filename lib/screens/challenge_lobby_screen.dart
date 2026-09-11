import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../core/widgets/src_gradient_background.dart';
import '../data/models/tournament_model.dart';
import '../features/challenge/providers/challenge_room_providers.dart';
import 'battle_pass_screen.dart';
import 'brand_sponsor_screen.dart';
import 'challenge_detail_screen.dart';
import 'create_challenge_room_screen.dart';

/// 다자간 챌린지 실시간 로비 화면 (Screen 7).
class ChallengeLobbyScreen extends ConsumerStatefulWidget {
  const ChallengeLobbyScreen({super.key});

  @override
  ConsumerState<ChallengeLobbyScreen> createState() =>
      _ChallengeLobbyScreenState();
}

class _ChallengeLobbyScreenState extends ConsumerState<ChallengeLobbyScreen> {
  static const _currentNavIndex = DashboardTabNavigation.challenge;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    DashboardTabNavigation.go(context, index);
  }

  void _onCreateRoom() {
    AppRouteNav.push<void>(
      context,
      RouteNames.createChallengeRoom,
      materialBuilder: (_) => const CreateChallengeRoomScreen(),
    );
  }

  void _onEnterRoom() {
    debugPrint('버튼 클릭됨');
  }

  void _onOpenBattlePass() {
    AppRouteNav.push<void>(
      context,
      RouteNames.battlePass,
      materialBuilder: (_) => const BattlePassScreen(),
    );
  }

  void _onOpenLiveRoom(TournamentModel room) {
    AppRouteNav.push<void>(
      context,
      RouteNames.challengeDetailForRoom(room.id),
      extra: room.id,
      materialBuilder: (_) => ChallengeDetailScreen(roomId: room.id),
    );
  }

  List<Widget> _liveTournamentCards(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final asyncRooms = ref.watch(tournamentListProvider);
    return asyncRooms.maybeWhen(
      data: (rooms) {
        if (rooms.isEmpty) return const [];
        return [
          SizedBox(height: tokens.spacing.md),
          Text(
            '실시간 개설 · 참가 가능 방',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.colors.ink,
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          for (final room in rooms) ...[
            _OpenRoomCard(
              title: room.title,
              subtitle:
                  '${room.targetDistanceKm.toStringAsFixed(0)}km · '
                  '${room.participantCount}/${room.maxParticipants}명 · '
                  'BEP ${((room.participantCount / room.minParticipantsBep.clamp(1, 1 << 20)) * 100).clamp(0, 999).toStringAsFixed(0)}%',
              onEnter: () => _onOpenLiveRoom(room),
            ),
            SizedBox(height: tokens.spacing.sm),
          ],
        ];
      },
      orElse: () => const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Scaffold(
      backgroundColor: tokens.colors.canvas,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.page,
                  tokens.spacing.xs,
                  tokens.spacing.page,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    key: const Key('lobby-create-room'),
                    onPressed: _onCreateRoom,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.colors.primary,
                      side: BorderSide(
                        color: tokens.colors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: tokens.radii.capsule,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.md,
                        vertical: tokens.spacing.xs,
                      ),
                    ),
                    child: Text(
                      AppStrings.lobbyCreateRoom,
                      style: textTheme.labelLarge?.copyWith(
                        color: tokens.colors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.page,
                  tokens.spacing.sm,
                  tokens.spacing.page,
                  tokens.spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.lobbyTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tokens.colors.ink,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.xs),
                    Text(
                      AppStrings.lobbySubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.colors.muted,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('lobby-battle-pass'),
                        onPressed: _onOpenBattlePass,
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.colors.accent,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.lobbyBattlePassCta,
                          style: textTheme.labelMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spacing.page,
                    0,
                    tokens.spacing.page,
                    tokens.spacing.md,
                  ),
                  children: [
                    _SponsorRoomCard(
                      title: AppStrings.lobbySponsorRoomTitle,
                      subtitle: AppStrings.lobbySponsorRoomSub,
                      onEnter: () {
                        AppRouteNav.push<void>(
                          context,
                          RouteNames.brandSponsor,
                          materialBuilder: (_) => const BrandSponsorScreen(),
                        );
                      },
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    _OpenRoomCard(
                      title: AppStrings.lobbyRoom1Title,
                      subtitle: AppStrings.lobbyRoom1Sub,
                      onEnter: () {
                        AppRouteNav.push<void>(
                          context,
                          RouteNames.challengeDetail,
                          materialBuilder: (_) => const ChallengeDetailScreen(),
                        );
                      },
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    _FeaturedRoomCard(
                      title: AppStrings.lobbyRoom2Title,
                      subtitle: AppStrings.lobbyRoom2Sub,
                      onEnter: _onEnterRoom,
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    const _LockedRoomCard(
                      title: AppStrings.lobbyRoom3Title,
                      subtitle: AppStrings.lobbyRoom3Sub,
                    ),
                    ..._liveTournamentCards(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: embedNav
          ? DashboardBottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            )
          : null,
    );
    return embedNav
        ? SrcExitGuard(
            tabIndex: DashboardTabNavigation.challenge,
            child: scaffold,
          )
        : scaffold;
  }
}

class _LobbyEnterChip extends StatelessWidget {
  const _LobbyEnterChip({
    required this.onEnter,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.buttonKey,
  });

  final VoidCallback onEnter;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: tokens.radii.capsule,
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: buttonKey,
        onTap: onEnter,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: tokens.spacing.sm - 2,
          ),
          child: Text(
            AppStrings.lobbyEnterRoom,
            style: textTheme.labelLarge?.copyWith(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsorRoomCard extends StatelessWidget {
  const _SponsorRoomCard({
    required this.title,
    required this.subtitle,
    required this.onEnter,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final onDonation = Theme.of(context).colorScheme.onTertiary;
    return SrcSurfaceCard(
      key: const Key('lobby-sponsor-card'),
      color: tokens.colors.donation.withValues(alpha: 0.14),
      borderColor: tokens.colors.donation.withValues(alpha: 0.55),
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tokens.colors.donation,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs + 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.colors.ink.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          _LobbyEnterChip(
            buttonKey: const Key('lobby-sponsor-enter'),
            onEnter: onEnter,
            background: tokens.colors.donation,
            foreground: onDonation,
          ),
        ],
      ),
    );
  }
}

class _OpenRoomCard extends StatelessWidget {
  const _OpenRoomCard({
    required this.title,
    required this.subtitle,
    required this.onEnter,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      color: tokens.colors.primary.withValues(alpha: 0.10),
      borderColor: tokens.colors.primary.withValues(alpha: 0.55),
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.colors.ink,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs + 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.colors.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          _LobbyEnterChip(
            onEnter: onEnter,
            background: tokens.colors.primary,
            foreground: tokens.colors.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _FeaturedRoomCard extends StatelessWidget {
  const _FeaturedRoomCard({
    required this.title,
    required this.subtitle,
    required this.onEnter,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      color: tokens.colors.primary,
      borderColor: tokens.colors.primary,
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.colors.onPrimary,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs + 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.colors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          _LobbyEnterChip(
            onEnter: onEnter,
            background: tokens.colors.accent,
            foreground: tokens.colors.onAccent,
            borderColor: tokens.colors.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _LockedRoomCard extends StatelessWidget {
  const _LockedRoomCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      color: tokens.colors.outline.withValues(alpha: 0.45),
      borderColor: tokens.colors.outline,
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.colors.muted,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs + 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.colors.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: tokens.colors.muted,
                size: 22,
              ),
              SizedBox(height: tokens.spacing.xxs),
              Text(
                AppStrings.lobbyGradeBlocked,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tokens.colors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
