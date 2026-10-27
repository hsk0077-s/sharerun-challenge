import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/navigation/root_back_fallback.dart';

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

  bool didRequestExit() =>
      platformCalls.any((call) => call.method == 'SystemNavigator.pop');

  testWidgets('a screen with no back stack and no guard goes Home on back',
      (tester) async {
    final router = _router(initialLocation: '/plain');
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();
    expect(find.text('PLAIN_ROOT'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('PLAIN_ROOT'), findsNothing);
    expect(didRequestExit(), isFalse);
  });

  testWidgets('a pushed screen still just closes to the previous one',
      (tester) async {
    final router = _router(initialLocation: RouteNames.home);
    await tester.pumpWidget(_nestedApp(router));
    await tester.pumpAndSettle();

    router.push('/plain');
    await tester.pumpAndSettle();
    expect(find.text('PLAIN_ROOT'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('HOME_ROOT'), findsOneWidget);
    expect(find.text('PLAIN_ROOT'), findsNothing);
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
        backWithHomeFallback(router);
      },
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

GoRouter _router({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('HOME_ROOT'))),
      ),
      GoRoute(
        path: '/plain',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('PLAIN_ROOT'))),
      ),
    ],
  );
}
