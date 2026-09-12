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
      'cold start: Home first BACK snacks, does not exit (no tab visits)',
      (tester) async {
    final router = _fiveTabRouter(initialLocation: RouteNames.mainDashboard);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pump();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text(AppStrings.exitGuardMessage), findsOneWidget);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'cold start: each non-home tab first BACK goes Home, never exits',
      (tester) async {
    const tabs = <(String, String)>[
      (RouteNames.shop, 'SHOP_ROOT'),
      (RouteNames.tournament, 'CHALLENGE_ROOT'),
      (RouteNames.crew, 'CREW_ROOT'),
      (RouteNames.myPage, 'MYPAGE_ROOT'),
    ];

    for (final tab in tabs) {
      platformCalls.clear();
      final router = _fiveTabRouter(initialLocation: tab.$1);
      await tester.pumpWidget(_nestedApp(router));
      await tester.pumpAndSettle();
      expect(find.text(tab.$2), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue, reason: tab.$1);
      expect(find.text('HOME_ROOT'), findsOneWidget, reason: tab.$1);
      expect(find.text(tab.$2), findsNothing, reason: tab.$1);
      expect(didRequestExit(), isFalse, reason: tab.$1);
    }
  });

  testWidgets(
      'leftover GoRouter.canPop at Home first BACK snacks, does not pop shell',
      (tester) async {
    final router = _leftoverParentRouter(
      initialLocation: RouteNames.mainDashboard,
    );
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(router.canPop(), isTrue, reason: 'parent / is leftover canPop');

    final handled = await tester.binding.handlePopRoute();
    await tester.pump();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('BOOT_LEFTOVER'), findsNothing);
    expect(find.text(AppStrings.exitGuardMessage), findsOneWidget);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'leftover GoRouter.canPop at Shop first BACK goes Home, not leftover',
      (tester) async {
    final router = _leftoverParentRouter(initialLocation: RouteNames.shop);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('SHOP_ROOT'), findsOneWidget);
    expect(router.canPop(), isTrue);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('BOOT_LEFTOVER'), findsNothing);
    expect(find.text('SHOP_ROOT'), findsNothing);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'leftover canPop: pushed HoF still pops; Home double-back still exits',
      (tester) async {
    final router = _leftoverParentRouter(
      initialLocation: RouteNames.mainDashboard,
    );
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();

    router.push(RouteNames.hallOfFame);
    await tester.pumpAndSettle();
    expect(find.text('HOF_STAND_IN'), findsOneWidget);

    var handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(didRequestExit(), isFalse);

    handled = await tester.binding.handlePopRoute();
    await tester.pump();
    expect(handled, isTrue);
    expect(find.text(AppStrings.exitGuardMessage), findsOneWidget);
    expect(didRequestExit(), isFalse);

    handled = await tester.binding.handlePopRoute();
    await tester.pump();
    expect(handled, isTrue);
    expect(didRequestExit(), isTrue);
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
      _tabShell(),
      _hofRoute(),
    ],
  );
}

/// Parent `/` stays on the GoRouter match list so [GoRouter.canPop] is true
/// at tab URLs — the leftover that first-back used to pop (app exit).
GoRouter _leftoverParentRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Text('BOOT_LEFTOVER'),
        routes: [
          _tabShell(relativeTabPaths: true),
        ],
      ),
      _hofRoute(),
    ],
  );
}

StatefulShellRoute _tabShell({bool relativeTabPaths = false}) {
  String path(String absolute) =>
      relativeTabPaths ? absolute.substring(1) : absolute;

  return StatefulShellRoute.indexedStack(
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
            path: path(RouteNames.mainDashboard),
            builder: (context, state) => const Center(child: Text('HOME_ROOT')),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: path(RouteNames.shop),
            builder: (context, state) => const Center(child: Text('SHOP_ROOT')),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: path(RouteNames.tournament),
            builder: (context, state) =>
                const Center(child: Text('CHALLENGE_ROOT')),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: path(RouteNames.crew),
            builder: (context, state) => const Center(child: Text('CREW_ROOT')),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: path(RouteNames.myPage),
            builder: (context, state) =>
                const Center(child: Text('MYPAGE_ROOT')),
          ),
        ],
      ),
    ],
  );
}

GoRoute _hofRoute() {
  return GoRoute(
    path: RouteNames.hallOfFame,
    builder: (context, state) => const _PushedDetailStandIn(
      label: 'HOF_STAND_IN',
    ),
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
