import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../screens/challenge_lobby_screen.dart';
import '../../screens/main_dashboard_screen.dart';
import '../../screens/onboarding_my_page_screen.dart';
import '../../screens/store_screen.dart';
import '../../screens/running_crew_screen.dart';

/// 메인 5대 탭 인덱스 및 Material / GoRouter 공통 전환 헬퍼.
abstract final class DashboardTabNavigation {
  static const home = 0;
  static const shop = 1;
  static const challenge = 2;
  static const crew = 3;
  static const myPage = 4;

  /// GoRouter 셸 안에서는 셸 하단바가 담당하므로 임베디드 바를 숨긴다.
  static bool useEmbeddedBottomNav(BuildContext context) =>
      GoRouter.maybeOf(context) == null;

  static String pathForIndex(int index) {
    return switch (index) {
      shop => RouteNames.shop,
      challenge => RouteNames.tournament,
      crew => RouteNames.crew,
      myPage => RouteNames.myPage,
      _ => RouteNames.mainDashboard,
    };
  }

  /// Material 경로용 탭 루트 위젯.
  static Widget rootForIndex(int index) {
    return switch (index) {
      shop => const StoreScreen(),
      challenge => const ChallengeLobbyScreen(),
      crew => const RunningCrewScreen(),
      myPage => const OnboardingMyPageScreen(),
      _ => const MainDashboardScreen(),
    };
  }

  static void go(BuildContext context, int index) {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      shell.goBranch(
        index,
        initialLocation: index == shell.currentIndex,
      );
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(pathForIndex(index));
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => rootForIndex(index)),
    );
  }
}
