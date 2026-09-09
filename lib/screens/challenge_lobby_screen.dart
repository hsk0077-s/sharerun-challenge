import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
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

  List<Widget> _liveTournamentCards(WidgetRef ref) {
    final asyncRooms = ref.watch(tournamentListProvider);
    return asyncRooms.maybeWhen(
      data: (rooms) {
        if (rooms.isEmpty) return const [];
        return [
          const SizedBox(height: 16),
          Text(
            '실시간 개설 · 참가 가능 방',
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          for (final room in rooms) ...[
            _LightMintRoomCard(
              title: room.title,
              subtitle:
                  '${room.targetDistanceKm.toStringAsFixed(0)}km · '
                  '${room.participantCount}/${room.maxParticipants}명 · '
                  'BEP ${((room.participantCount / room.minParticipantsBep.clamp(1, 1 << 20)) * 100).clamp(0, 999).toStringAsFixed(0)}%',
              onEnter: () => _onOpenLiveRoom(room),
            ),
            const SizedBox(height: 12),
          ],
        ];
      },
      orElse: () => const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppShapes.termsHorizontalPadding,
                  8,
                  AppShapes.termsHorizontalPadding,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: _onCreateRoom,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryMint,
                      side: const BorderSide(
                        color: AppColors.primaryMint,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      AppStrings.lobbyCreateRoom,
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.primaryMint,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppShapes.termsHorizontalPadding,
                  12,
                  AppShapes.termsHorizontalPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.lobbyTitle,
                      style: AppTextStyles.header1.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.lobbySubtitle,
                      style: AppTextStyles.termsSubtitle,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _onOpenBattlePass,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryMintDark,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.lobbyBattlePassCta,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryMintDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    0,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  children: [
                    _SponsorBlackRoomCard(
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
                    const SizedBox(height: 12),
                    _LightMintRoomCard(
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
                    const SizedBox(height: 12),
                    _SolidMintRoomCard(
                      title: AppStrings.lobbyRoom2Title,
                      subtitle: AppStrings.lobbyRoom2Sub,
                      onEnter: _onEnterRoom,
                    ),
                    const SizedBox(height: 12),
                    const _LockedRoomCard(
                      title: AppStrings.lobbyRoom3Title,
                      subtitle: AppStrings.lobbyRoom3Sub,
                    ),
                    ..._liveTournamentCards(ref),
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

class _SponsorBlackRoomCard extends StatelessWidget {
  const _SponsorBlackRoomCard({
    required this.title,
    required this.subtitle,
    required this.onEnter,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.nikeBlack,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: AppColors.voltYellow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.nikeBlack.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.voltYellow,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textWhite.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.voltYellow,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEnter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  AppStrings.lobbyEnterRoom,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.nikeBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LightMintRoomCard extends StatelessWidget {
  const _LightMintRoomCard({
    required this.title,
    required this.subtitle,
    required this.onEnter,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.agreementBoxFill,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: AppColors.primaryMint, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.primaryMintDark,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEnter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  AppStrings.lobbyEnterRoom,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidMintRoomCard extends StatelessWidget {
  const _SolidMintRoomCard({
    required this.title,
    required this.subtitle,
    required this.onEnter,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMint,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMintDark.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textWhite.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.primaryMintDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.textWhite, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEnter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  AppStrings.lobbyEnterRoom,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textGreyLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textGrey,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.lobbyGradeBlocked,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
