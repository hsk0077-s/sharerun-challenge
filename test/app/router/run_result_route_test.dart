import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/main_shell_routes.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/features/jena_validation/models/jena_validation_result.dart';
import 'package:share_run_challenge/screens/run_result_screen.dart';

const _verified = JenaValidationResult(
  verified: true,
  decision: JenaDecision.verified,
  reason: 'ok',
  valueTokenReward: 0,
);

/// Opens /run-result the way the app does and returns what the route built.
Future<void> _open(WidgetTester tester, Object? extra) async {
  final router = GoRouter(
    initialLocation: RouteNames.runResult,
    initialExtra: extra,
    routes: buildMainShellAndDetailRoutes(),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pump();
}

void main() {
  group('/run-result route extra', () {
    // run_tracking_screen.dart sends this class after every tracked run.
    testWidgets('RunResultArgs opens the result screen without a cast error',
        (tester) async {
      await _open(
        tester,
        const RunResultArgs(
          activityId: 'act-1',
          result: _verified,
          routePoints: [],
        ),
      );

      expect(tester.takeException(), isNull);
      final screen = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(screen.activityId, 'act-1');
      expect(screen.result, _verified);
      expect(find.byType(RunResultScreen), findsOneWidget);
    });

    testWidgets('ResultScreenArgs keeps distance and time', (tester) async {
      await _open(
        tester,
        const ResultScreenArgs(
          activityId: 'act-2',
          result: _verified,
          routePoints: [],
          distanceKm: 5.25,
          durationSeconds: 1800,
        ),
      );

      expect(tester.takeException(), isNull);
      final screen = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(screen.activityId, 'act-2');
      expect(screen.distanceKm, 5.25);
      expect(screen.durationSeconds, 1800);
    });

    testWidgets('no extra opens the fallback result', (tester) async {
      await _open(tester, null);

      expect(tester.takeException(), isNull);
      final screen = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(screen.activityId, fallbackRunResult.activityId);
      expect(screen.distanceKm, 0);
      expect(screen.durationSeconds, 0);
    });

    testWidgets('an unknown extra type also opens the fallback',
        (tester) async {
      await _open(tester, 'not args');

      expect(tester.takeException(), isNull);
      final screen = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(screen.activityId, fallbackRunResult.activityId);
    });
  });

  group('distance and time on the screen', () {
    const verifiedArgs = ResultScreenArgs(
      activityId: 'act-3',
      result: _verified,
      routePoints: [],
      distanceKm: 5.25,
      durationSeconds: 1800,
    );

    testWidgets('/run-result shows distance and time', (tester) async {
      await _open(tester, verifiedArgs);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('5.25 km'), findsOneWidget);
      expect(find.textContaining('30:00'), findsOneWidget);
    });

    testWidgets('an hour or more shows h:mm:ss', (tester) async {
      await _open(
        tester,
        const ResultScreenArgs(
          activityId: 'act-4',
          result: _verified,
          routePoints: [],
          distanceKm: 10.0,
          durationSeconds: 4500,
        ),
      );

      expect(find.textContaining('10.00 km'), findsOneWidget);
      expect(find.textContaining('1:15:00'), findsOneWidget);
    });

    testWidgets('the fallback hides the distance and time lines',
        (tester) async {
      await _open(tester, null);

      expect(find.byType(RunResultScreen), findsOneWidget);
      expect(find.textContaining('km'), findsNothing);
      expect(find.textContaining('00:00'), findsNothing);
    });

    testWidgets('the old RunResultArgs has no distance, so the lines hide',
        (tester) async {
      await _open(
        tester,
        const RunResultArgs(
          activityId: 'act-5',
          result: _verified,
          routePoints: [],
        ),
      );

      expect(find.textContaining('km'), findsNothing);
    });

    // in_challenge_screen opens ResultScreen directly with Navigator.
    testWidgets('ResultScreen opened directly shows distance and time',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResultScreen(
              activityId: 'act-6',
              result: _verified,
              routePoints: [],
              distanceKm: 3.1,
              durationSeconds: 905,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('3.10 km'), findsOneWidget);
      expect(find.textContaining('15:05'), findsOneWidget);
    });
  });
}
