import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/main_shell_routes.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/features/friends/screens/friends_screen.dart';

import '../../support/ko_localization.dart';

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    locale: koTestLocale,
    supportedLocales: koTestSupportedLocales,
    localizationsDelegates: koTestDelegates,
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('the friends route is /friends', () {
    expect(RouteNames.friends, '/friends');
  });

  testWidgets('the row shows "친구" and opens /friends', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(body: Column(children: [MyPageFriendsEntry()])),
        ),
        GoRoute(
          path: RouteNames.friends,
          builder: (_, __) => const Scaffold(body: Text('friends-page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pump(tester, router);

    expect(find.byKey(MyPageFriendsEntry.entryKey), findsOneWidget);
    expect(find.text('친구'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.byKey(MyPageFriendsEntry.entryKey));
    await tester.pumpAndSettle();

    expect(find.text('friends-page'), findsOneWidget);
  });

  test('the app router registers the friends screen', () {
    final paths = buildMainShellAndDetailRoutes()
        .whereType<GoRoute>()
        .map((r) => r.path)
        .toSet();
    expect(paths, contains(RouteNames.friends));
  });

  test('the app router registers the cheer inbox screen', () {
    expect(RouteNames.cheerInbox, '/friends/cheers');
    final paths = buildMainShellAndDetailRoutes()
        .whereType<GoRoute>()
        .map((r) => r.path)
        .toSet();
    expect(paths, contains(RouteNames.cheerInbox));
  });
}
