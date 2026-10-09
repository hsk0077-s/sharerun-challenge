import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/screens/preliminary_eval_screen.dart';

ProviderScope _scope(Widget child, {bool healthConsent = false}) {
  final profile = UserModel.dashboardDefault(uid: 'u1')
      .copyWith(healthDataConsent: healthConsent);
  return ProviderScope(
    overrides: [
      activeUserProfileProvider.overrideWith(
        (ref) => Stream<UserModel>.value(profile),
      ),
    ],
    child: child,
  );
}

void main() {
  testWidgets('right after sign-up there is a way out to the home shell',
      (tester) async {
    await tester.pumpWidget(
      _scope(
        MaterialApp(
          routes: {
            RouteNames.home: (_) => const Scaffold(body: Text('home-shell')),
          },
          home: const PreliminaryEvalScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No GoRouter here, so a run cannot start from this screen.
    expect(find.byKey(PreliminaryEvalScreen.startRunKey), findsNothing);
    expect(find.byKey(PreliminaryEvalScreen.goHomeKey), findsOneWidget);
    expect(find.text('홈으로 가기'), findsOneWidget);

    await tester.tap(find.byKey(PreliminaryEvalScreen.goHomeKey));
    await tester.pumpAndSettle();

    expect(find.text('home-shell'), findsOneWidget);
    expect(find.byType(PreliminaryEvalScreen), findsNothing);
  });

  testWidgets('opened from home the start button runs the preflight',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const PreliminaryEvalScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      _scope(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PreliminaryEvalScreen.goHomeKey), findsNothing);
    expect(find.byKey(PreliminaryEvalScreen.startRunKey), findsOneWidget);

    // Health consent is missing, so the preflight asks for it.
    await tester.tap(find.byKey(PreliminaryEvalScreen.startRunKey));
    await tester.pumpAndSettle();
    expect(find.text('건강정보 동의 필요'), findsOneWidget);
  });
}
