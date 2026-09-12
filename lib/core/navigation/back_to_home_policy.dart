import '../../app/router/route_names.dart';
import 'dashboard_tab_navigation.dart';

/// Product rule: system back exits only at a true Home tab root (double-back).
///
/// Pushed details (Hall of Fame, sponsor, …) always pop when a stack exists.
/// Tab-root [GoRouter.canPop] can be a spurious shell entry on first launch —
/// ignore that, but never block a real [Navigator] pop (#29 lesson).
enum BackToHomeAction {
  popDetail,
  goHome,
  confirmExit,
}

abstract final class BackToHomePolicy {
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

  /// [canPopDetail] must already mean a real stack pop (Navigator, or
  /// GoRouter while **not** at a tab root). Do not pass raw
  /// [GoRouter.canPop] at tab roots — that is the first-back trap.
  static BackToHomeAction resolve({
    required bool atTabRoot,
    required bool canPopDetail,
    required int tabIndex,
  }) {
    if (canPopDetail) {
      return BackToHomeAction.popDetail;
    }
    if (!atTabRoot || tabIndex != DashboardTabNavigation.home) {
      return BackToHomeAction.goHome;
    }
    return BackToHomeAction.confirmExit;
  }
}
