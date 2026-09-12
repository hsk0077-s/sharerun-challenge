import 'package:flutter/widgets.dart';

import '../../app/router/route_names.dart';
import 'dashboard_tab_navigation.dart';

/// System back: pop a real stack, else Home. Exit only at Home tab root
/// (double-back). Never treat a leftover [GoRouter.canPop] at a tab URL as
/// a detail — that first-launch pop finishes the app.
enum AppPopAction { popDetail, goHome, confirmExit }

abstract final class AppPopPolicy {
  static bool isMainTabRoot(String location) {
    final path = Uri.tryParse(location)?.path ?? location.split('?').first;
    return path == RouteNames.mainDashboard ||
        path == RouteNames.home ||
        path == RouteNames.shop ||
        path == RouteNames.store ||
        path == RouteNames.tournament ||
        path == RouteNames.crew ||
        path == RouteNames.crews ||
        path == RouteNames.myPage ||
        path == RouteNames.mapCrew;
  }

  /// [canPopNearestNavigator] is a real Material / nested stack.
  /// [routerCanPop] is trusted only when the **root URL** is not a tab.
  static AppPopAction resolve({
    required bool atTabRoot,
    required bool canPopNearestNavigator,
    required bool routerCanPop,
    required int tabIndex,
  }) {
    if (canPopNearestNavigator) {
      return AppPopAction.popDetail;
    }
    if (!atTabRoot && routerCanPop) {
      return AppPopAction.popDetail;
    }
    if (!atTabRoot || tabIndex != DashboardTabNavigation.home) {
      return AppPopAction.goHome;
    }
    return AppPopAction.confirmExit;
  }

  /// Nested [MaterialApp]s must not [SystemNavigator.pop] when a child
  /// navigator reports it cannot pop. Home double-back still exits via
  /// [SrcExitGuard] calling [SystemNavigator.pop] directly.
  static bool consumeNavigationNotification(NavigationNotification _) => true;
}
