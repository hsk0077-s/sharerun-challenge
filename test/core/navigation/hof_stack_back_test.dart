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

  testWidgets('popOrHome pops a pushed HoF and does not exit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: const Text('HOME_ROOT'),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _PushedDetailStandIn(
                        label: 'HOF_STAND_IN',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('HOF_STAND_IN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('detail-back')));
    await tester.pumpAndSettle();

    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(didRequestExit(), isFalse);
  });

  testWidgets('system back from pushed HoF pops to previous', (tester) async {
    final router = _detailRouter(initialLocation: RouteNames.mainDashboard);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);

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

  testWidgets('system back from HoF-as-root goes Home, never exits',
      (tester) async {
    final router = _detailRouter(initialLocation: RouteNames.hallOfFame);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('HOF_STAND_IN'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(didRequestExit(), isFalse);
  });

  testWidgets('system back from sponsor-as-root goes Home, never exits',
      (tester) async {
    final router = _detailRouter(initialLocation: RouteNames.personalSponsor);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('SPONSOR_STAND_IN'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'nested MaterialApp: HoF-as-root back goes Home, never exits',
      (tester) async {
    final router = _detailRouter(initialLocation: RouteNames.hallOfFame);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('HOF_STAND_IN'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'nested MaterialApp: sponsor-as-root back goes Home, never exits',
      (tester) async {
    final router = _detailRouter(initialLocation: RouteNames.personalSponsor);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('SPONSOR_STAND_IN'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(didRequestExit(), isFalse);
  });

  testWidgets(
      'nested MaterialApp: pushed HoF pops; Home tab still double-back exits',
      (tester) async {
    final router = _shellRouter(initialLocation: RouteNames.mainDashboard);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);

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

  testWidgets(
      'nested MaterialApp: Shop tab first back goes Home (no blanket block)',
      (tester) async {
    final router = _shellRouter(initialLocation: RouteNames.shop);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('SHOP_ROOT'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
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

GoRouter _detailRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.mainDashboard,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('HOME_ROOT')),
        ),
      ),
      GoRoute(
        path: RouteNames.hallOfFame,
        builder: (context, state) => const _PushedDetailStandIn(
          label: 'HOF_STAND_IN',
        ),
      ),
      GoRoute(
        path: RouteNames.personalSponsor,
        builder: (context, state) => const _PushedDetailStandIn(
          label: 'SPONSOR_STAND_IN',
        ),
      ),
    ],
  );
}

GoRouter _shellRouter({required String initialLocation}) {
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
  );
}

/// Same PopScope + popOrHome used by HallOfFameScreen / PersonalSponsorScreen.
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              IconButton(
                key: const Key('detail-back'),
                onPressed: () => AppRouteNav.popOrHome(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
