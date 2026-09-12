import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/navigation/app_route_nav.dart';
import 'package:share_run_challenge/core/widgets/src_exit_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  bool didRequestExit() => platformCalls.any(
        (call) => call.method == 'SystemNavigator.pop',
      );

  List<bool> frameworkHandlesBackArgs() => platformCalls
      .where((call) => call.method == 'SystemNavigator.setFrameworkHandlesBack')
      .map((call) => call.arguments as bool)
      .toList();

  testWidgets(
      'each of 5 tab roots: first BACK does not exit (cold start)',
      (tester) async {
    const tabs = <(String, String)>[
      (RouteNames.mainDashboard, 'HOME_ROOT'),
      (RouteNames.shop, 'SHOP_ROOT'),
      (RouteNames.tournament, 'CHALLENGE_ROOT'),
      (RouteNames.crew, 'CREW_ROOT'),
      (RouteNames.myPage, 'MY_ROOT'),
    ];

    for (final (location, label) in tabs) {
      platformCalls.clear();
      final router = _fiveTabRouter(initialLocation: location);
      await tester.pumpWidget(_nestedApp(router));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pump();
      expect(handled, isTrue, reason: '$location first BACK should be handled');
      expect(didRequestExit(), isFalse, reason: '$location must not exit');
    }
  });

  testWidgets(
      'imperative leftover then go(Shop): first BACK goes Home, no exit',
      (tester) async {
    final router = _fiveTabRouter(initialLocation: RouteNames.mainDashboard);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();

    router.push(RouteNames.hallOfFame);
    await tester.pumpAndSettle();
    expect(find.text('HOF_STAND_IN'), findsOneWidget);

    router.go(RouteNames.shop);
    await tester.pumpAndSettle();
    expect(find.text('SHOP_ROOT'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'Android: tab shell claims BACK after cold start (last flag true)',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final router = _fiveTabRouter(initialLocation: RouteNames.shop);
      await tester.pumpWidget(_nestedApp(router));
      await tester.pumpAndSettle();
      expect(find.text('SHOP_ROOT'), findsOneWidget);

      final flags = frameworkHandlesBackArgs();
      expect(flags, isNotEmpty, reason: 'shell must claim Android BACK');
      expect(
        flags.last,
        isTrue,
        reason: 'must not leave frameworkHandlesBack false',
      );
      expect(didRequestExit(), isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'Android: branch canHandlePop=false must not leave BACK to the Activity',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final router = _fiveTabRouter(initialLocation: RouteNames.shop);
      await tester.pumpWidget(_nestedApp(router));
      await tester.pumpAndSettle();
      platformCalls.clear();

      final shopContext = tester.element(find.text('SHOP_ROOT'));
      const NavigationNotification(canHandlePop: false).dispatch(shopContext);
      await tester.pump();

      final flags = frameworkHandlesBackArgs();
      expect(flags, isNotEmpty);
      expect(flags.last, isTrue);
      expect(didRequestExit(), isFalse);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.text('HOME_ROOT'), findsOneWidget);
      expect(didRequestExit(), isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('pushed HoF still pops; does not exit', (tester) async {
    final router = _fiveTabRouter(initialLocation: RouteNames.mainDashboard);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();

    router.push(RouteNames.hallOfFame);
    await tester.pumpAndSettle();
    expect(find.text('HOF_STAND_IN'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(didRequestExit(), isFalse);
  });
}

/// Same nesting as [ShareRunChallengeApp] → [AuthenticatedApp].
Widget _nestedApp(GoRouter router) {
  return MaterialApp(
    home: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final inner = router.routerDelegate.navigatorKey.currentState;
        if (inner != null && inner.mounted) {
          inner.maybePop();
        }
      },
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

GoRouter _fiveTabRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SrcExitGuard(
            navigationShell: navigationShell,
            child: Scaffold(
              body: navigationShell,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: navigationShell.goBranch,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.store_rounded),
                    label: 'Shop',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events_rounded),
                    label: 'Challenge',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.groups_rounded),
                    label: 'Crew',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'My',
                  ),
                ],
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.mainDashboard,
                builder: (context, state) => const Center(
                  child: Text('HOME_ROOT'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.shop,
                builder: (context, state) => const Center(
                  child: Text('SHOP_ROOT'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.tournament,
                builder: (context, state) => const Center(
                  child: Text('CHALLENGE_ROOT'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.crew,
                builder: (context, state) => const Center(
                  child: Text('CREW_ROOT'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.myPage,
                builder: (context, state) => const Center(
                  child: Text('MY_ROOT'),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.hallOfFame,
        builder: (context, state) => const _PushedDetailStandIn(
          label: 'HOF_STAND_IN',
        ),
      ),
    ],
  );
}

class _PushedDetailStandIn extends StatelessWidget {
  const _PushedDetailStandIn({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppRouteNav.popOrHome(context);
      },
      child: Scaffold(
        body: Center(
          child: Text(label),
        ),
      ),
    );
  }
}
