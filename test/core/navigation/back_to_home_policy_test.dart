import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/navigation/back_to_home_policy.dart';
import 'package:share_run_challenge/core/navigation/dashboard_tab_navigation.dart';

void main() {
  test('main tab roots include first-entry dashboard and aliases', () {
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.mainDashboard), isTrue);
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.home), isTrue);
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.shop), isTrue);
    expect(
      BackToHomePolicy.isMainTabRoot('${RouteNames.shop}?focus=donate'),
      isTrue,
    );
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.tournament), isTrue);
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.crew), isTrue);
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.myPage), isTrue);
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.hallOfFame), isFalse);
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.personalSponsor), isFalse);
    expect(BackToHomePolicy.isMainTabRoot(RouteNames.myWallet), isFalse);
  });

  test('real detail pops even at a tab root (never block normal pops)', () {
    expect(
      BackToHomePolicy.resolve(
        atTabRoot: true,
        canPopDetail: true,
        tabIndex: DashboardTabNavigation.home,
      ),
      BackToHomeAction.popDetail,
    );
  });

  test('first cold start on Home tab confirms exit instead of popping', () {
    expect(
      BackToHomePolicy.resolve(
        atTabRoot: true,
        canPopDetail: false,
        tabIndex: DashboardTabNavigation.home,
      ),
      BackToHomeAction.confirmExit,
    );
  });

  test('non-home tab root goes Home; HoF-as-root goes Home (never exit)', () {
    expect(
      BackToHomePolicy.resolve(
        atTabRoot: true,
        canPopDetail: false,
        tabIndex: DashboardTabNavigation.shop,
      ),
      BackToHomeAction.goHome,
    );
    expect(
      BackToHomePolicy.resolve(
        atTabRoot: false,
        canPopDetail: true,
        tabIndex: DashboardTabNavigation.home,
      ),
      BackToHomeAction.popDetail,
    );
    expect(
      BackToHomePolicy.resolve(
        atTabRoot: false,
        canPopDetail: false,
        tabIndex: DashboardTabNavigation.home,
      ),
      BackToHomeAction.goHome,
    );
  });
}
