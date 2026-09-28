import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../core/navigation/app_route_nav.dart';
import '../../core/navigation/dashboard_tab_navigation.dart';
import '../../screens/battle_pass_screen.dart';
import '../../screens/brand_sponsor_screen.dart';
import '../../screens/challenge_detail_screen.dart';
import '../../screens/in_app_billing_screen.dart';
import '../../screens/personal_sponsor_screen.dart';
import '../../screens/store_screen.dart';
import '../../screens/subscription_management_screen.dart';
import '../iap/widgets/coach_plus_upsell_sheet.dart';
import '../shop/providers/shop_tab_provider.dart';
import 'mini_bot_intent.dart';

/// Existing screens only. Does not join a room or start a purchase.
abstract final class MiniBotRoutes {
  static String? location(MiniBotDestination destination) {
    return switch (destination) {
      MiniBotDestination.beginnerRoom =>
        RouteNames.challengeDetailForRoom(RouteNames.beginner1kmRoomId),
      MiniBotDestination.challengeLobby => RouteNames.tournament,
      MiniBotDestination.cprStore ||
      MiniBotDestination.safeGuardStore =>
        RouteNames.storeWithFocus(StoreFocus.items.name),
      MiniBotDestination.donateStore =>
        RouteNames.storeWithFocus(StoreFocus.donate.name),
      MiniBotDestination.shareCharge => RouteNames.inAppBilling,
      MiniBotDestination.personalSponsor => RouteNames.personalSponsor,
      MiniBotDestination.brandSponsor => RouteNames.brandSponsor,
      MiniBotDestination.subscription => RouteNames.subscriptionManagement,
      MiniBotDestination.coachPlus => null,
      MiniBotDestination.battlePass => RouteNames.battlePass,
      MiniBotDestination.none => null,
    };
  }
}

abstract final class MiniBotNavigator {
  static void go(BuildContext context, MiniBotDestination destination) {
    switch (destination) {
      case MiniBotDestination.none:
        return;
      case MiniBotDestination.beginnerRoom:
        final location = MiniBotRoutes.location(destination);
        if (location == null) return;
        AppRouteNav.push<void>(
          context,
          location,
          extra: RouteNames.beginner1kmRoomId,
          materialBuilder: (_) => const ChallengeDetailScreen(
            roomId: RouteNames.beginner1kmRoomId,
          ),
        );
      case MiniBotDestination.challengeLobby:
        DashboardTabNavigation.go(context, DashboardTabNavigation.challenge);
      case MiniBotDestination.cprStore:
      case MiniBotDestination.safeGuardStore:
        _openStore(context, StoreFocus.items);
      case MiniBotDestination.donateStore:
        _openStore(context, StoreFocus.donate);
      case MiniBotDestination.shareCharge:
        _push(
          context,
          RouteNames.inAppBilling,
          (_) => const InAppBillingScreen(),
        );
      case MiniBotDestination.personalSponsor:
        _push(
          context,
          RouteNames.personalSponsor,
          (_) => const PersonalSponsorScreen(),
        );
      case MiniBotDestination.brandSponsor:
        _push(
          context,
          RouteNames.brandSponsor,
          (_) => const BrandSponsorScreen(),
        );
      case MiniBotDestination.subscription:
        _push(
          context,
          RouteNames.subscriptionManagement,
          (_) => const SubscriptionManagementScreen(),
        );
      case MiniBotDestination.coachPlus:
        CoachPlusUpsellSheet.show(context);
      case MiniBotDestination.battlePass:
        _push(
          context,
          RouteNames.battlePass,
          (_) => const BattlePassScreen(),
        );
    }
  }

  /// Same store entry the home diamond badge already uses.
  /// Opens the items or donate section. Does not debit or call purchase.
  static void _openStore(BuildContext context, StoreFocus focus) {
    ProviderScope.containerOf(context)
        .read(storeFocusProvider.notifier)
        .setFocus(focus);
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(
          RouteNames.store,
          queryParameters: {'focus': focus.name},
        );
        return;
      } catch (_) {
        context.go(RouteNames.storeWithFocus(focus.name));
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.storeWithFocus(focus.name),
      extra: focus,
      materialBuilder: (_) => StoreScreen(initialFocus: focus),
    );
  }

  static void _push(
    BuildContext context,
    String location,
    WidgetBuilder builder,
  ) {
    AppRouteNav.push<void>(
      context,
      location,
      materialBuilder: builder,
    );
  }
}
