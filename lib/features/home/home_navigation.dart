import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../core/navigation/app_route_nav.dart';
import '../../core/navigation/dashboard_tab_navigation.dart';
import '../../screens/in_app_billing_screen.dart';
import '../../screens/store_screen.dart';
import '../shop/providers/shop_tab_provider.dart';

/// 홈과 마이 화면이 같이 쓰는 이동 함수. 화면이 바뀌어도 가는 곳은 그대로다.
abstract final class HomeNavigation {
  /// SHARE 잔액을 누르면 가는 충전 화면.
  static void openInAppBilling(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.inAppBilling);
        return;
      } catch (_) {
        context.push(RouteNames.inAppBilling);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.inAppBilling,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  /// 상점은 탭이다. 탭으로 옮겨야 뒤로가기가 홈으로 돌아온다.
  static void openStore(
    BuildContext context,
    WidgetRef ref, {
    required StoreFocus focus,
  }) {
    ref.read(storeFocusProvider.notifier).setFocus(focus);
    if (GoRouter.maybeOf(context) != null) {
      DashboardTabNavigation.go(context, DashboardTabNavigation.shop);
      return;
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.storeWithFocus(focus.name),
      extra: focus,
      materialBuilder: (_) => StoreScreen(initialFocus: focus),
    );
  }
}
