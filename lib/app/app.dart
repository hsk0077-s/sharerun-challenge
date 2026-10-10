import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/launch/intro_screen.dart';
import '../features/launch/launch_splash.dart';
import '../screens/settings_screen.dart';
import '../screens/personal_sponsor_screen.dart';
import '../screens/store_screen.dart';
import '../screens/in_app_billing_screen.dart';
import '../screens/angel_book_page.dart';
import '../screens/snail_to_cheetah_book_page.dart';
import '../screens/notification_center_screen.dart';
import '../screens/onboarding_my_page_screen.dart';
import '../screens/onboarding_run_result_screen.dart';
import '../screens/in_challenge_screen.dart';
import '../screens/live_running_screen.dart';
import '../screens/challenge_detail_screen.dart';
import '../screens/challenge_lobby_screen.dart';
import '../screens/create_challenge_room_screen.dart';
import '../screens/main_dashboard_screen.dart';
import '../screens/external_oauth_webview.dart';
import '../screens/login_screen.dart';
import '../screens/watch_connection_screen.dart';
import '../screens/appeal_center_screen.dart';
import '../screens/health_data_consent_screen.dart';
import '../screens/terms_agreement_screen.dart';
import '../screens/donation_settlement_screen.dart';
import '../screens/fair_earning_policy_screen.dart';
import '../screens/preliminary_eval_screen.dart';
import '../screens/security_privacy_center_screen.dart';
import '../screens/wallet_history_screen.dart';
import '../screens/solo_pedometer_screen.dart';
import '../screens/my_wallet_screen.dart';
import 'authenticated_app.dart';
import 'app_config.dart';
import 'root_navigator.dart';
import 'router/dashboard_router.dart';
import 'router/route_names.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../data/models/activity_model.dart';
import '../core/theme/src_theme.dart';
import 'theme/app_theme.dart';

class ShareRunChallengeApp extends StatelessWidget {
  const ShareRunChallengeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '쉐어런',
      theme: SrcTheme.light,
      darkTheme: AppTheme.dark,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: rootNavigatorKey,
      home: AppConfig.showIntro
          ? FirstRunSplash(
              child: IntroScreen(
                onFinished: () => rootNavigatorKey.currentState
                    ?.pushReplacementNamed(RouteNames.login),
              ),
            )
          : AppConfig.initialRoute == RouteNames.home
              ? const LaunchSplashGate(child: AuthenticatedApp())
              : const LoginScreen(),
      routes: {
        RouteNames.login: (_) => const LoginScreen(),
        RouteNames.termsAgreement: (_) => const TermsAgreementScreen(),
        RouteNames.smartWatchSync: (_) => const WatchConnectionScreen(),
        RouteNames.healthDataConsent: (_) => const HealthDataConsentScreen(),
        RouteNames.garminAuth: (_) => const ExternalOauthWebview(),
        RouteNames.mainDashboard: (_) => const MainDashboardScreen(),
        // levelTestRunning == preliminaryEval (동일 경로 alias)
        RouteNames.preliminaryEval: (_) => const PreliminaryEvalScreen(),
        RouteNames.challengeLobby: (_) => const ChallengeLobbyScreen(),
        RouteNames.createChallengeRoom: (_) => const CreateChallengeRoomScreen(),
        RouteNames.challengeDetail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final roomId = args is String ? args : null;
          return ChallengeDetailScreen(roomId: roomId);
        },
        RouteNames.liveRunning: (_) => const LiveRunningScreen(),
        RouteNames.inChallenge: (_) => const InChallengeScreen(),
        RouteNames.soloRunTracking: (_) => const InChallengeScreen(),
        RouteNames.soloRunTrackingName: (_) => const InChallengeScreen(),
        RouteNames.soloPedometer: (_) => const SoloPedometerScreen(),
        RouteNames.soloPedometerPath: (_) => const SoloPedometerScreen(),
        RouteNames.appeal: (context) {
          final extra = ModalRoute.of(context)?.settings.arguments;
          return AppealCenterScreen(
            activityId: ActivityModel.idFromRouteExtra(extra),
          );
        },
        RouteNames.appealCenter: (context) {
          final extra = ModalRoute.of(context)?.settings.arguments;
          return AppealCenterScreen(
            activityId: ActivityModel.idFromRouteExtra(extra),
          );
        },
        RouteNames.runResult: (_) => const OnboardingRunResultScreen(),
        RouteNames.onboardingMyPage: (_) => const OnboardingMyPageScreen(),
        RouteNames.settings: (_) => const SettingsScreen(),
        RouteNames.personalSponsor: (_) => const PersonalSponsorScreen(),
        RouteNames.settingsLegal: (_) => const SettingsLegalWebViewScreen(),
        RouteNames.securityCenter: (_) => const SecurityPrivacyCenterScreen(),
        RouteNames.fairEarningPolicy: (_) => const FairEarningPolicyScreen(),
        RouteNames.securityTransactions: (_) => const WalletHistoryScreen(),
        RouteNames.donationSettlement: (_) => const DonationSettlementScreen(),
        RouteNames.onboardingStoreFunding: (_) => const StoreScreen(),
        RouteNames.inAppBilling: (_) => const InAppBillingScreen(),
        RouteNames.myWallet: (_) => const MyWalletScreen(),
        RouteNames.wallet: (_) => const MyWalletScreen(),
        RouteNames.tierBook: (_) => const SnailToCheetahBookPage(),
        RouteNames.angelBook: (_) => const AngelBookPage(),
        RouteNames.angelBookPath: (_) => const AngelBookPage(),
        RouteNames.notificationCenter: (_) => const NotificationCenterScreen(),
        RouteNames.walletHistory: (_) =>
            const NotificationCenterScreen(initialTabIndex: 1),
        RouteNames.externalPayment: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final amount = args is int ? args : 0;
          return InAppBillingScreen(highlightAmountWon: amount);
        },
        RouteNames.shop: (_) =>
            DashboardTabNavigation.rootForIndex(DashboardTabNavigation.shop),
        RouteNames.crew: (_) =>
            DashboardTabNavigation.rootForIndex(DashboardTabNavigation.crew),
        RouteNames.tournament: (_) => DashboardTabNavigation.rootForIndex(
              DashboardTabNavigation.challenge,
            ),
        RouteNames.myPage: (_) =>
            DashboardTabNavigation.rootForIndex(DashboardTabNavigation.myPage),
        RouteNames.home: (_) => const AuthenticatedApp(),
      },
      onUnknownRoute: (settings) {
        final fallback = AppConfig.initialRoute == RouteNames.home
            ? RouteNames.home
            : RouteNames.login;
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: fallback),
          builder: (_) => fallback == RouteNames.home
              ? const AuthenticatedApp()
              : const LoginScreen(),
        );
      },
    );
  }
}

/// Clears session and returns to the login route via the root navigator.
void navigateToLoginScreen() {
  // 대시보드 라우터는 앱이 켜져 있는 동안 유지된다. 다시 로그인했을 때
  // 로그아웃하던 화면이 아니라 홈이 나오도록 위치를 홈으로 돌려 둔다.
  final context = rootNavigatorKey.currentContext;
  if (context != null) {
    try {
      ProviderScope.containerOf(context, listen: false)
          .read(dashboardRouterProvider)
          .go(RouteNames.mainDashboard);
    } catch (_) {}
  }
  rootNavigatorKey.currentState?.pushReplacementNamed(RouteNames.login);
}
