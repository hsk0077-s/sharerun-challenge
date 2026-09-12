import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/navigation/app_route_nav.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
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

  testWidgets(
      'leftover router.canPop at Shop tab: first BACK goes Home, no exit',
      (tester) async {
    final router = _leftoverShellRouter(initialLocation: RouteNames.shop);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('SHOP_ROOT'), findsOneWidget);
    expect(router.canPop(), isTrue, reason: 'outer ShellRoute leftover');

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('SHOP_ROOT'), findsNothing);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'leftover router.canPop at Home tab: first BACK snacks, does not exit',
      (tester) async {
    final router = _leftoverShellRouter(
      initialLocation: RouteNames.mainDashboard,
    );
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(router.canPop(), isTrue, reason: 'outer ShellRoute leftover');

    var handled = await tester.binding.handlePopRoute();
    await tester.pump();
    expect(handled, isTrue);
    expect(find.text(AppStrings.exitGuardMessage), findsOneWidget);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(didRequestExit(), isFalse);

    handled = await tester.binding.handlePopRoute();
    await tester.pump();
    expect(handled, isTrue);
    expect(didRequestExit(), isTrue);
  });

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
      'leftover tab shell: pushed HoF still pops, never exits',
      (tester) async {
    final router = _leftoverShellRouter(
      initialLocation: RouteNames.mainDashboard,
    );
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

/// Extra [ShellRoute] match so [GoRouter.canPop] is true at tab roots —
/// the leftover state after a fresh install / unvisited branches.
GoRouter _leftoverShellRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => child,
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
            ],
          ),
          GoRoute(
            path: RouteNames.hallOfFame,
            builder: (context, state) => const _PushedDetailStandIn(
              label: 'HOF_STAND_IN',
            ),
          ),
        ],
      ),
    ],
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
