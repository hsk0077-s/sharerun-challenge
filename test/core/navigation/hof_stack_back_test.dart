import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/navigation/app_route_nav.dart';
import 'package:share_run_challenge/core/navigation/dashboard_tab_navigation.dart';
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

  bool get didRequestExit => platformCalls.any(
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
                      builder: (_) => const _HofStandIn(),
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

    await tester.tap(find.byKey(const Key('hof-back')));
    await tester.pumpAndSettle();

    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(didRequestExit, isFalse);
  });

  testWidgets('system back from pushed HoF pops to previous', (tester) async {
    final router = _shellRouter(initialLocation: RouteNames.mainDashboard);
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
    expect(didRequestExit, isFalse);
  });

  testWidgets('system back from HoF-as-root goes Home, never exits',
      (tester) async {
    final router = _shellRouter(initialLocation: RouteNames.hallOfFame);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('HOF_STAND_IN'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('HOF_STAND_IN'), findsNothing);
    expect(didRequestExit, isFalse);
  });

  testWidgets('sponsor-as-root back goes Home without exiting', (tester) async {
    final router = _shellRouter(initialLocation: RouteNames.personalSponsor);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('SPONSOR_STAND_IN'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(didRequestExit, isFalse);
  });

  testWidgets('Home tab first back confirms; second back exits', (tester) async {
    final router = _shellRouter(initialLocation: RouteNames.mainDashboard);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text(AppStrings.exitGuardMessage), findsOneWidget);
    expect(didRequestExit, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(didRequestExit, isTrue);
  });

  testWidgets('Shop tab first back goes Home (does not block tab back)',
      (tester) async {
    final router = _shellRouter(initialLocation: RouteNames.shop);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('SHOP_ROOT'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(didRequestExit, isFalse);
  });
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
                builder: (context, state) => SrcExitGuard(
                  tabIndex: DashboardTabNavigation.shop,
                  child: const Center(child: Text('SHOP_ROOT')),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.hallOfFame,
        builder: (context, state) => const _HofStandIn(),
      ),
      GoRoute(
        path: RouteNames.personalSponsor,
        builder: (context, state) => const _SponsorStandIn(),
      ),
    ],
  );
}

/// Mirrors HallOfFameScreen / PersonalSponsorScreen PopScope + popOrHome.
class _HofStandIn extends StatelessWidget {
  const _HofStandIn();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: AppRouteNav.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppRouteNav.popOrHome(context);
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('HOF_STAND_IN'),
              IconButton(
                key: const Key('hof-back'),
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

class _SponsorStandIn extends StatelessWidget {
  const _SponsorStandIn();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: AppRouteNav.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppRouteNav.popOrHome(context);
      },
      child: const Scaffold(
        body: Center(child: Text('SPONSOR_STAND_IN')),
      ),
    );
  }
}
