import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/navigation/app_route_nav.dart';

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

/// Same PopScope + popOrHome used by HallOfFameScreen / PersonalSponsorScreen.
class _PushedDetailStandIn extends StatelessWidget {
  const _PushedDetailStandIn({required this.label});

  final String label;

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
