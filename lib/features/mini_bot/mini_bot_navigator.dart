import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../core/navigation/app_route_nav.dart';
import '../../core/navigation/dashboard_tab_navigation.dart';
import '../../screens/challenge_detail_screen.dart';
import '../../screens/store_screen.dart';
import '../shop/providers/shop_tab_provider.dart';
import 'mini_bot_intent.dart';

/// Existing screens only. Does not join a room or start a purchase.
abstract final class MiniBotRoutes {
  static String? location(MiniBotDestination destination) {
    return switch (destination) {
      MiniBotDestination.beginnerRoom =>
        RouteNames.challengeDetailForRoom(RouteNames.beginner1kmRoomId),
      MiniBotDestination.challengeLobby => RouteNames.tournament,
      MiniBotDestination.cprStore =>
        RouteNames.storeWithFocus(StoreFocus.items.name),
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
        _openCprStore(context);
    }
  }

  /// Same store entry the home diamond badge already uses. The CPR card
  /// lives in the items section. This does not debit DIA or call purchase.
  static void _openCprStore(BuildContext context) {
    const focus = StoreFocus.items;
    ProviderScope.containerOf(context)
        .read(storeFocusProvider.notifier)
        .setFocus(focus);
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(
          RouteNames.store,
          queryParameters: const {'focus': 'items'},
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
      materialBuilder: (_) => const StoreScreen(initialFocus: focus),
    );
  }
}
