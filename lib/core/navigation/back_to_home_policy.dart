import '../../app/router/route_names.dart';
import 'dashboard_tab_navigation.dart';

/// Product rule: system back on a main tab root never exits immediately.
/// Non-home tabs converge to Home; Home requires a second back to exit.
///
/// First cold start used to pop a spurious GoRouter history entry and leave
/// the app. Tab roots must not [pop] even when [GoRouter.canPop] is true.
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

  static BackToHomeAction resolve({
    required bool atTabRoot,
    required bool canPopDetail,
    required int tabIndex,
  }) {
    if (!atTabRoot && canPopDetail) {
      return BackToHomeAction.popDetail;
    }
    if (tabIndex != DashboardTabNavigation.home) {
      return BackToHomeAction.goHome;
    }
    return BackToHomeAction.confirmExit;
  }
}
