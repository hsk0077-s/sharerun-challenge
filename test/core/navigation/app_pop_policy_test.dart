import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/navigation/app_pop_policy.dart';
import 'package:share_run_challenge/core/navigation/dashboard_tab_navigation.dart';

void main() {
  test('tab URLs are roots; HoF and sponsor are not', () {
    expect(AppPopPolicy.isMainTabRoot(RouteNames.mainDashboard), isTrue);
    expect(AppPopPolicy.isMainTabRoot('${RouteNames.shop}?focus=donate'), isTrue);
    expect(AppPopPolicy.isMainTabRoot(RouteNames.crew), isTrue);
    expect(AppPopPolicy.isMainTabRoot(RouteNames.hallOfFame), isFalse);
    expect(AppPopPolicy.isMainTabRoot(RouteNames.personalSponsor), isFalse);
    expect(AppPopPolicy.isMainTabRoot(RouteNames.myWallet), isFalse);
  });

  test('spurious router.canPop at Home tab root confirms, does not pop', () {
    expect(
      AppPopPolicy.resolve(
        atTabRoot: true,
        canPopNearestNavigator: false,
        routerCanPop: true,
        tabIndex: DashboardTabNavigation.home,
      ),
      AppPopAction.confirmExit,
    );
  });

  test('spurious router.canPop at Shop tab goes Home, does not pop', () {
    expect(
      AppPopPolicy.resolve(
        atTabRoot: true,
        canPopNearestNavigator: false,
        routerCanPop: true,
        tabIndex: DashboardTabNavigation.shop,
      ),
      AppPopAction.goHome,
    );
  });

  test('HoF/sponsor with no stack go Home, never confirmExit', () {
    expect(
      AppPopPolicy.resolve(
        atTabRoot: false,
        canPopNearestNavigator: false,
        routerCanPop: false,
        tabIndex: DashboardTabNavigation.home,
      ),
      AppPopAction.goHome,
    );
  });

  test('real nearest stack pops even at a tab URL', () {
    expect(
      AppPopPolicy.resolve(
        atTabRoot: true,
        canPopNearestNavigator: true,
        routerCanPop: false,
        tabIndex: DashboardTabNavigation.home,
      ),
      AppPopAction.popDetail,
    );
  });

  test('sibling detail with router stack pops', () {
    expect(
      AppPopPolicy.resolve(
        atTabRoot: false,
        canPopNearestNavigator: false,
        routerCanPop: true,
        tabIndex: DashboardTabNavigation.crew,
      ),
      AppPopAction.popDetail,
    );
  });
}
