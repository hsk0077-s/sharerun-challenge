import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/src_bottom_nav.dart';
import '../../data/models/activity_model.dart';
import '../../features/jena_validation/models/jena_validation_result.dart';
import '../../features/shop/providers/shop_tab_provider.dart';
import '../../screens/appeal_center_screen.dart';
import '../../screens/battle_pass_screen.dart';
import '../../screens/brand_sponsor_screen.dart';
import '../../screens/challenge_detail_screen.dart';
import '../../screens/challenge_lobby_screen.dart';
import '../../screens/create_challenge_room_screen.dart';
import '../../screens/crew_manager_screen.dart';
import '../../screens/device_connection_screen.dart';
import '../../screens/external_oauth_webview.dart';
import '../../screens/watch_connection_screen.dart';
import '../../screens/hall_of_fame_screen.dart';
import '../../screens/health_data_consent_screen.dart';
import '../../screens/item_inventory_screen.dart';
import '../../screens/in_challenge_screen.dart';
import '../../screens/live_running_screen.dart';
import '../../screens/main_dashboard_screen.dart';
import '../../screens/my_wallet_screen.dart';
import '../../screens/my_tournaments_screen.dart';
import '../../screens/notification_center_screen.dart';
import '../../screens/onboarding_my_page_screen.dart';
import '../../screens/store_screen.dart';
import '../../screens/in_app_billing_screen.dart';
import '../../screens/angel_book_page.dart';
import '../../screens/snail_to_cheetah_book_page.dart';
import '../../screens/payment_webview_screen.dart';
import '../../screens/personal_sponsor_screen.dart';
import '../../screens/preliminary_eval_screen.dart';
import '../../screens/pro_tools_screen.dart';
import '../../screens/refund_screen.dart';
import '../../screens/run_result_screen.dart';
import '../../screens/run_tracking_screen.dart';
import '../../screens/running_crew_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/solo_pedometer_screen.dart';
import '../../screens/sponsor_payment_screen.dart';
import '../../screens/stamp_tour_screen.dart';
import '../../screens/subscription_management_screen.dart';
import '../../screens/tournament_detail_screen.dart';
import '../../screens/tournament_screen.dart';
import '../../screens/web3_wallet_screen.dart';
import '../../screens/winner_demo_screen.dart';
import 'route_names.dart';

/// [2단계] 5대 탭 실물 루트 + 17장 시나리오 하위 경로.
List<RouteBase> buildMainShellAndDetailRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return SrcBottomNav(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1 — 홈/대시보드 (src-5)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.mainDashboard,
              pageBuilder: _fadePage(const MainDashboardScreen()),
            ),
          ],
        ),
        // Tab 2 — 상점/기부 (src-13)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.shop,
              name: RouteNames.store,
              pageBuilder: (context, state) {
                final focus = StoreFocus.tryParse(
                      state.uri.queryParameters['focus'],
                    ) ??
                    StoreFocus.tryParse(state.extra);
                return NoTransitionPage<void>(
                  key: state.pageKey,
                  child: StoreScreen(initialFocus: focus),
                );
              },
            ),
          ],
        ),
        // Tab 3 — 챌린지/대회 (src-7 로비, tournamentId 시 토너먼트 보드)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.tournament,
              pageBuilder: (context, state) {
                final tournamentId =
                    state.uri.queryParameters['tournamentId'];
                if (tournamentId != null && tournamentId.isNotEmpty) {
                  return _fadePage(
                    TournamentScreen(initialTournamentId: tournamentId),
                  )(context, state);
                }
                return _fadePage(const ChallengeLobbyScreen())(
                  context,
                  state,
                );
              },
            ),
          ],
        ),
        // Tab 4 — 러닝크루 (src-18)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.crew,
              pageBuilder: _fadePage(const RunningCrewScreen()),
            ),
          ],
        ),
        // Tab 5 — 마이페이지/일지 (src-12)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.myPage,
              name: RouteNames.myPage,
              pageBuilder: _fadePage(const OnboardingMyPageScreen()),
            ),
          ],
        ),
      ],
    ),

    // Alias redirects → 탭 루트
    GoRoute(
      path: RouteNames.home,
      name: RouteNames.home,
      redirect: (context, state) => RouteNames.mainDashboard,
    ),
    GoRoute(
      path: RouteNames.wallet,
      redirect: (context, state) => RouteNames.myWallet,
    ),
    GoRoute(
      path: RouteNames.myWallet,
      name: RouteNames.myWalletName,
      pageBuilder: _fadePage(const MyWalletScreen()),
    ),
    GoRoute(
      path: RouteNames.mapCrew,
      redirect: (context, state) => RouteNames.crew,
    ),

    // ── 셸 밖 상세 화면: 정상 Navigator Pop (종료 가드 비개입) ──

    // 홈 탭 하위
    GoRoute(
      path: RouteNames.preliminaryEval,
      name: RouteNames.preliminaryEvalName,
      pageBuilder: _fadePage(const PreliminaryEvalScreen()),
    ),
    GoRoute(
      path: RouteNames.soloRunTracking,
      name: RouteNames.soloRunTrackingName,
      pageBuilder: _fadePage(const InChallengeScreen()),
    ),
    GoRoute(
      path: RouteNames.soloPedometerPath,
      name: RouteNames.soloPedometer,
      pageBuilder: _fadePage(const SoloPedometerScreen()),
    ),
    GoRoute(
      path: RouteNames.notificationCenter,
      name: RouteNames.notifications,
      pageBuilder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        final payment = tab == RouteNames.notificationTabPayment ||
            tab == 'history' ||
            tab == '1';
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: NotificationCenterScreen(initialTabIndex: payment ? 1 : 0),
        );
      },
    ),
    GoRoute(
      path: RouteNames.walletHistory,
      name: RouteNames.walletHistory,
      pageBuilder: _fadePage(
        const NotificationCenterScreen(initialTabIndex: 1),
      ),
    ),

    // 상점 탭 하위
    GoRoute(
      path: RouteNames.paymentWebView,
      pageBuilder: (context, state) {
        final args = state.extra as PaymentWebViewArgs?;
        if (args == null) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: const _MissingRouteArgsScreen(
              message: '결제 정보가 없어 PG 화면을 열 수 없습니다.',
            ),
          );
        }
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: PaymentWebViewScreen(args: args),
        );
      },
    ),
    GoRoute(
      path: RouteNames.externalPayment,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final amount = extra is int
            ? extra
            : int.tryParse(state.uri.queryParameters['amount'] ?? '') ?? 0;
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: InAppBillingScreen(highlightAmountWon: amount),
        );
      },
    ),
    GoRoute(
      path: RouteNames.inAppBilling,
      name: RouteNames.inAppBilling,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final amount = extra is int ? extra : 0;
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: InAppBillingScreen(highlightAmountWon: amount),
        );
      },
    ),
    GoRoute(
      path: RouteNames.tierBook,
      name: RouteNames.tierBook,
      pageBuilder: _fadePage(const SnailToCheetahBookPage()),
    ),
    GoRoute(
      path: RouteNames.angelBookPath,
      name: RouteNames.angelBook,
      pageBuilder: _fadePage(const AngelBookPage()),
    ),
    GoRoute(
      path: RouteNames.itemInventory,
      pageBuilder: _fadePage(const ItemInventoryScreen()),
    ),
    GoRoute(
      path: RouteNames.battlePass,
      pageBuilder: _fadePage(const BattlePassScreen()),
    ),
    GoRoute(
      path: RouteNames.subscriptionManagement,
      pageBuilder: _fadePage(const SubscriptionManagementScreen()),
    ),

    // 챌린지 탭 하위
    GoRoute(
      path: RouteNames.challengeLobby,
      pageBuilder: _fadePage(const ChallengeLobbyScreen()),
    ),
    GoRoute(
      path: RouteNames.createChallengeRoom,
      pageBuilder: _fadePage(const CreateChallengeRoomScreen()),
    ),
    GoRoute(
      path: RouteNames.challengeDetail,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final roomId = extra is String
            ? extra
            : state.uri.queryParameters['roomId'];
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: ChallengeDetailScreen(roomId: roomId),
        );
      },
    ),
    GoRoute(
      path: '/tournaments/:tournamentId',
      pageBuilder: (context, state) {
        final tournamentId = state.pathParameters['tournamentId'] ?? '';
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: TournamentDetailScreen(tournamentId: tournamentId),
        );
      },
    ),
    GoRoute(
      path: RouteNames.liveRunning,
      pageBuilder: _fadePage(const LiveRunningScreen()),
    ),
    GoRoute(
      path: RouteNames.inChallenge,
      pageBuilder: _fadePage(const InChallengeScreen()),
    ),
    GoRoute(
      path: RouteNames.runTracking,
      pageBuilder: _fadePage(const RunTrackingScreen()),
    ),
    GoRoute(
      path: RouteNames.runResult,
      pageBuilder: (context, state) {
        final args = state.extra as ResultScreenArgs?;
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: ResultScreen(
            activityId: args?.activityId ?? fallbackRunResult.activityId,
            result: args?.result ?? fallbackRunResult.result,
            routePoints: args?.routePoints ?? const [],
            distanceKm: args?.distanceKm ?? 0,
            durationSeconds: args?.durationSeconds ?? 0,
            totalSteps: args?.totalSteps,
            playerName: args?.playerName,
          ),
        );
      },
    ),
    GoRoute(
      path: RouteNames.brandSponsor,
      pageBuilder: _fadePage(const BrandSponsorScreen()),
    ),
    GoRoute(
      path: RouteNames.personalSponsor,
      name: RouteNames.personalSponsor,
      pageBuilder: _fadePage(const PersonalSponsorScreen()),
    ),
    GoRoute(
      path: RouteNames.sponsorPayment,
      pageBuilder: (context, state) {
        final args = state.extra as SponsorPaymentArgs?;
        if (args == null) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: const _MissingRouteArgsScreen(
              message: '대회 정보가 없어 스폰서 결제를 열 수 없습니다.',
            ),
          );
        }
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: SponsorPaymentScreen(args: args),
        );
      },
    ),

    // 러닝크루 탭 하위
    GoRoute(
      path: RouteNames.crewManager,
      pageBuilder: _fadePage(const CrewManagerScreen()),
    ),

    // 마이페이지 하위
    GoRoute(
      path: RouteNames.settings,
      pageBuilder: _fadePage(const SettingsScreen()),
    ),
    GoRoute(
      path: RouteNames.settingsLegal,
      pageBuilder: _fadePage(const SettingsLegalWebViewScreen()),
    ),
    GoRoute(
      path: RouteNames.proTools,
      pageBuilder: _fadePage(const ProToolsScreen()),
    ),
    GoRoute(
      path: RouteNames.refund,
      pageBuilder: _fadePage(const RefundScreen()),
    ),
    GoRoute(
      path: RouteNames.web3Wallet,
      pageBuilder: _fadePage(const Web3WalletScreen()),
    ),
    GoRoute(
      path: RouteNames.stampTour,
      pageBuilder: _fadePage(const StampTourScreen()),
    ),
    GoRoute(
      path: RouteNames.hallOfFame,
      pageBuilder: _fadePage(const HallOfFameScreen()),
    ),
    GoRoute(
      path: RouteNames.appeal,
      name: RouteNames.appealCenter,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: AppealCenterScreen(
            activityId: ActivityModel.idFromRouteExtra(state.extra),
          ),
        );
      },
    ),

    // 기존 보조 경로 유지
    GoRoute(
      path: RouteNames.healthDataConsent,
      pageBuilder: _fadePage(const HealthDataConsentScreen()),
    ),
    GoRoute(
      path: RouteNames.winnerDemo,
      pageBuilder: _fadePage(const WinnerDemoScreen()),
    ),
    GoRoute(
      path: RouteNames.watchSettings,
      pageBuilder: _fadePage(const DeviceConnectionScreen()),
    ),
    GoRoute(
      path: RouteNames.smartWatchSync,
      pageBuilder: _fadePage(const WatchConnectionScreen()),
    ),
    GoRoute(
      path: RouteNames.garminAuth,
      pageBuilder: _fadePage(const ExternalOauthWebview()),
    ),
    GoRoute(
      path: RouteNames.myTournaments,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: const Scaffold(
            body: SafeArea(child: MyTournamentsScreen()),
          ),
        );
      },
    ),
  ];
}

const fallbackRunResult = ResultScreenArgs(
  activityId: 'unknown-activity',
  result: JenaValidationResult(
    verified: false,
    decision: JenaDecision.rejectedUnknown,
    reason: 'No validation result was provided.',
    valueTokenReward: 0,
  ),
  routePoints: [],
);

Page<void> Function(BuildContext, GoRouterState) _fadePage(Widget child) {
  return (context, state) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: child,
    );
  };
}

class _MissingRouteArgsScreen extends StatelessWidget {
  const _MissingRouteArgsScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SRC')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(RouteNames.tournament),
              child: const Text('대회 목록으로'),
            ),
          ],
        ),
      ),
    );
  }
}
