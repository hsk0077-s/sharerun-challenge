import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/app.dart';
import 'package:share_run_challenge/app/root_navigator.dart';
import 'package:share_run_challenge/app/router/dashboard_router.dart';
import 'package:share_run_challenge/app/router/route_names.dart';

void main() {
  testWidgets('signing out puts the dashboard router back on the home tab',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/security',
      routes: [
        GoRoute(
          path: RouteNames.mainDashboard,
          builder: (_, __) => const SizedBox(),
        ),
        GoRoute(path: '/security', builder: (_, __) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dashboardRouterProvider.overrideWithValue(router)],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          routes: {
            RouteNames.login: (_) => const Text('login'),
          },
          home: const Text('app'),
        ),
      ),
    );
    await tester.pump();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/security',
    );

    navigateToLoginScreen();
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.mainDashboard,
    );
  });
}
