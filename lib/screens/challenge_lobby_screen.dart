import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../data/models/tournament_model.dart';
import '../features/challenge/providers/challenge_room_providers.dart';
import '../features/challenge/widgets/challenge_look.dart';
import '../features/mini_bot/mini_bot_sheet.dart';
import 'battle_pass_screen.dart';
import 'challenge_detail_screen.dart';
import 'create_challenge_room_screen.dart';
import 'my_tournaments_screen.dart';
import 'tournament_screen.dart';
import '../l10n/remaining_surface.dart';

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

  /// 실시간으로 열린 방. 번호는 앞 목록에 이어서 붙인다.
  List<_RoomRow> _liveTournamentRows(BuildContext context, WidgetRef ref) {
    final asyncRooms = ref.watch(tournamentListProvider);
    return asyncRooms.maybeWhen(
      data: (rooms) => [for (final room in rooms) room],
      orElse: () => const [],
    ).map((room) => _RoomRow(
          number: 0,
          title: room.title,
          subtitle: room.maxParticipants > 0
              ? RemainingSurface.tr(
                  context,
                  'challenge_lobby.body',
                  '${room.targetDistanceKm.toStringAsFixed(0)}km · '
                      '${room.participantCount}/${room.maxParticipants}명',
                  {
                    'room.targetDistanceKm.toStringAsFixed(0)':
                        room.targetDistanceKm.toStringAsFixed(0),
                    'room.participantCount': room.participantCount,
                    'room.maxParticipants': room.maxParticipants,
                  },
                )
              : RemainingSurface.tr(
                  context,
                  'challenge_lobby.body.2',
                  '${room.targetDistanceKm.toStringAsFixed(0)}km · '
                      '참가자 ${room.participantCount}명',
                  {
                    'room.targetDistanceKm.toStringAsFixed(0)':
                        room.targetDistanceKm.toStringAsFixed(0),
                    'room.participantCount': room.participantCount,
                  },
                ),
          onEnter: () => _onOpenLiveRoom(room),
        )).toList();
  }

  Widget _challengeTab(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final live = _liveTournamentRows(context, ref);
    final fixed = <_RoomRow>[
      _RoomRow(
        number: 0,
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
      _RoomRow(
        number: 0,
        title: AppStrings.lobbyRoom2Title,
        subtitle: AppStrings.lobbyRoom2Sub,
        onEnter: _onEnterRoom,
      ),
      _RoomRow(
        number: 0,
        title: AppStrings.lobbyRoom3Title,
        subtitle: AppStrings.lobbyRoom3Sub,
        onEnter: () {
          AppRouteNav.push<void>(
            context,
            RouteNames.challengeDetailForRoom(RouteNames.beginner1kmRoomId),
            extra: RouteNames.beginner1kmRoomId,
            materialBuilder: (_) => const ChallengeDetailScreen(
              roomId: RouteNames.beginner1kmRoomId,
            ),
          );
        },
      ),
    ];
    // 맨 위 큰 카드가 1번이라 목록은 2번부터 센다.
    final total = 1 + fixed.length + live.length;
    var n = 2;
    Widget numbered(_RoomRow row) => _RoomRow(
          number: n++,
          title: row.title,
          subtitle: row.subtitle,
          onEnter: row.onEnter,
        );
    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.page,
        tokens.spacing.md,
        tokens.spacing.page,
        96,
      ),
      children: [
        Text(
          RemainingSurface.tr(
            context,
            'challenge_lobby.body.3',
            '$total개 챌린지가\n열려 있어요',
            {'total': total},
          ),
          style: textTheme.headlineMedium?.copyWith(
            color: tokens.colors.ink,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        SizedBox(height: tokens.spacing.xs),
        Text(
          AppStrings.lobbySubtitle,
          style: textTheme.bodyMedium?.copyWith(color: tokens.colors.muted),
        ),
        SizedBox(height: tokens.spacing.md),
        // 실제 스폰서가 없을 때는 눌러도 가지 않는 "준비 중" 카드로 둔다.
        _HeroRoomCard(
          title: AppStrings.lobbySponsorRoomTitle,
          subtitle: AppStrings.lobbySponsorRoomSub,
        ),
        SizedBox(height: tokens.spacing.xs),
        for (final row in fixed) numbered(row),
        if (live.isNotEmpty) ...[
          ChallengeSectionLabel(
            RemainingSurface.tr(
              context,
              'challenge_lobby.body.4',
              '실시간 개설 · 참가 가능 대회',
            ),
          ),
          for (final row in live) numbered(row),
        ],
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
                fontWeight: FontWeight.w800,
                color: tokens.colors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final night = SrcTheme.night;
    final tokens = SrcTokens.night;
    final textTheme = night.textTheme;
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Theme(
      data: night,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: tokens.colors.canvas,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spacing.page,
                    tokens.spacing.sm,
                    tokens.spacing.page,
                    0,
                  ),
                  child: Row(
                    children: [
                      const ChallengeTag('CHALLENGE'),
                      const Spacer(),
                      OutlinedButton(
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
                          minimumSize: Size.zero,
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tokens.spacing.xs),
                TabBar(
                  key: const Key('lobby-top-tabs'),
                  dividerColor: tokens.colors.outline,
                  indicatorColor: tokens.colors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: tokens.colors.ink,
                  unselectedLabelColor: tokens.colors.muted,
                  labelStyle: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelStyle: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  tabs: [
                    const Tab(text: '챌린지'),
                    const Tab(text: '대회'),
                    Tab(
                      text: RemainingSurface.tr(
                        context,
                        'challenge_lobby.body.5',
                        '내 기록',
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Builder(
                        builder: (tabContext) => _challengeTab(tabContext, ref),
                      ),
                      const TournamentScreen(),
                      const MyTournamentsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton:
              embedNav ? miniBotEntryForTab(_currentNavIndex) : null,
          bottomNavigationBar: embedNav
              ? DashboardBottomNav(
                  currentIndex: _currentNavIndex,
                  onTap: _onNavTap,
                )
              : null,
        ),
      ),
    );
    return embedNav
        ? SrcExitGuard(
            tabIndex: DashboardTabNavigation.challenge,
            child: scaffold,
          )
        : scaffold;
  }
}

/// 맨 위 큰 사진 카드. 후원 방으로 들어간다.
class _HeroRoomCard extends StatelessWidget {
  const _HeroRoomCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      key: const Key('lobby-sponsor-card'),
      height: 210,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/challenge_track.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.4),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  // 눌러도 아무 데도 가지 않는 안내 표시. 글자만 "준비 중".
                  Container(
                    key: const Key('lobby-sponsor-preparing'),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: tokens.spacing.sm - 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: tokens.radii.capsule,
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                    child: Text(
                      AppStrings.lobbySponsorPreparing,
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 번호 붙은 한 줄. 지도의 `02 모닝런 챌린지` 모양.
class _RoomRow extends StatelessWidget {
  const _RoomRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onEnter,
  });

  final int number;
  final String title;
  final String subtitle;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.colors.outline)),
      ),
      child: Row(
        children: [
          if (number > 0)
            SizedBox(
              width: 48,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: textTheme.headlineSmall?.copyWith(
                  color: tokens.colors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
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
