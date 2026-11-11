import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/jena_validation/models/jena_validation_result.dart';
import 'package:share_run_challenge/features/jena_validation/services/activity_validation_service.dart';
import 'package:share_run_challenge/features/run_tracking/models/activity_packet.dart';
import 'package:share_run_challenge/features/run_tracking/models/route_point.dart';
import 'package:share_run_challenge/features/run_tracking/models/run_telemetry.dart';
import 'package:share_run_challenge/features/run_tracking/run_recording_policy.dart';
import 'package:share_run_challenge/features/run_tracking/services/ephemeral_sensor_buffer.dart';
import 'package:share_run_challenge/features/run_tracking/services/run_session_service.dart';
import 'package:share_run_challenge/screens/run_tracking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/ko_localization.dart';

class _FakeUser implements User {
  @override
  String get uid => 'u1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 센서 없이 호출만 센다. 시작을 느리게 하고 싶으면 [startGate]를 쓴다.
class _FakeSession implements RunSessionService {
  _FakeSession({this.startGate});

  final Completer<void>? startGate;
  final _telemetry = StreamController<RunTelemetry>.broadcast();
  var starts = 0;
  var finishes = 0;
  var disposes = 0;

  @override
  Stream<RunTelemetry> get telemetryStream => _telemetry.stream;

  @override
  Future<void> start() async {
    starts++;
    await startGate?.future;
  }

  @override
  Future<CompletedRunSession> finish({String? activityId, String? userId}) async {
    finishes++;
    final at = DateTime.utc(2026, 11, 12, 6);
    return CompletedRunSession(
      telemetry: RunTelemetry.empty,
      sensorBuffer: EphemeralSensorBuffer(),
      routePoints: const [],
      startedAt: at,
      endedAt: at,
      totalSteps: 0,
      activityPacket: ActivityPacket(
        activityId: 'a',
        userId: 'u1',
        startedAt: at,
        endedAt: at,
        distanceKm: 0,
        durationSeconds: 0,
        gpsTrajectory: const [],
        heartRateSeries: const [],
        cadenceSeries: const [],
        accelerometerData: const [],
      ),
    );
  }

  @override
  Future<void> dispose() async => disposes++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeValidation implements ActivityValidationService {
  final submitted = <double>[];

  @override
  Future<JenaValidationResult> validateAndPersistResult({
    required String activityId,
    required String userId,
    required double distanceKm,
    required int durationSeconds,
    required double gyroStabilityScore,
    required List<RoutePoint> routePoints,
    required EphemeralSensorBuffer sensorBuffer,
    WatchType watchType = WatchType.none,
    DateTime? startedAt,
    DateTime? endedAt,
    String? tournamentId,
    int? totalSteps,
  }) async {
    submitted.add(distanceKm);
    return const JenaValidationResult(
      verified: false,
      decision: JenaDecision.pending,
      reason: 'test',
      valueTokenReward: 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeSession session,
  required _FakeValidation validation,
}) async {
  SharedPreferences.setMockInitialValues({runChecklistCompletedKey: true});
  final profile = UserModel.dashboardDefault(uid: 'u1')
      .copyWith(healthDataConsent: true);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(RouteNames.runTracking),
              child: const Text('go-run'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.runTracking,
        builder: (_, __) => const RunTrackingScreen(),
      ),
      GoRoute(
        path: RouteNames.runResult,
        builder: (_, __) => const Scaffold(body: Text('result-screen')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runSessionServiceProvider.overrideWithValue(session),
        activityValidationServiceProvider.overrideWithValue(validation),
        activeUserProfileProvider.overrideWith(
          (ref) => Stream<UserModel>.value(profile),
        ),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(_FakeUser()),
        ),
      ],
      child: MaterialApp.router(
        locale: koTestLocale,
        supportedLocales: koTestSupportedLocales,
        localizationsDelegates: koTestDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // 앱에서는 다른 화면이 프로필을 계속 보고 있어 이미 불러와져 있다. 테스트에서도 그렇게 해 둔다.
  final container = ProviderScope.containerOf(tester.element(find.text('go-run')));
  final keep = container.listen(activeUserProfileProvider, (_, __) {});
  addTearDown(keep.close);
  final keepAuth = container.listen(authStateChangesProvider, (_, __) {});
  addTearDown(keepAuth.close);
  await tester.pump();
  await tester.tap(find.text('go-run'));
  await tester.pump();
}

const _dialog = Key('run-leave-dialog');

/// 화면이 프로필을 기다린 뒤(0.5초) 시작을 부르고 끝낼 때까지 시간을 흘려 보낸다.
Future<void> _letStartFinish(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('recording: system back asks "end your run?" and keeps tracking until answered',
      (tester) async {
    final session = _FakeSession();
    await _pump(tester, session: session, validation: _FakeValidation());
    await _letStartFinish(tester);
    expect(session.starts, 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(_dialog), findsOneWidget);
    expect(find.text('달리기를 끝낼까요?'), findsOneWidget);
    expect(find.text('계속 달리기'), findsOneWidget);
    expect(find.text('끝내기'), findsOneWidget);
    expect(find.byType(RunTrackingScreen), findsOneWidget);
    expect(session.finishes, 0);
    expect(session.disposes, 0);
  });

  testWidgets('recording: the app bar back button asks too', (tester) async {
    final session = _FakeSession();
    await _pump(tester, session: session, validation: _FakeValidation());
    await _letStartFinish(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(_dialog), findsOneWidget);
    expect(find.byType(RunTrackingScreen), findsOneWidget);
  });

  testWidgets('"계속 달리기" keeps the screen and the tracking running', (tester) async {
    final session = _FakeSession();
    final validation = _FakeValidation();
    await _pump(tester, session: session, validation: validation);
    await _letStartFinish(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('run-leave-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(_dialog), findsNothing);
    expect(find.byType(RunTrackingScreen), findsOneWidget);
    expect(session.finishes, 0, reason: 'nothing is stopped or submitted');
    expect(session.disposes, 0);
    expect(validation.submitted, isEmpty);
  });

  testWidgets('"끝내기" reuses the normal finish flow and closes the screen', (tester) async {
    final session = _FakeSession();
    final validation = _FakeValidation();
    await _pump(tester, session: session, validation: validation);
    await _letStartFinish(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('run-leave-end')));
    await tester.pumpAndSettle();

    // Same path as the "러닝 끝내고 검증하기" button: finish() then the usual validation.
    expect(session.finishes, 1);
    expect(validation.submitted, hasLength(1));
    expect(validation.submitted.single, 0, reason: 'only the real measured value, no invented number');
    expect(find.byType(RunTrackingScreen), findsNothing);
    expect(find.text('result-screen'), findsOneWidget);
    // The properly finished session is not disposed a second time by the safety net.
    expect(session.disposes, 0);
  });

  testWidgets('before the run starts, back leaves at once without a dialog', (tester) async {
    final gate = Completer<void>();
    final session = _FakeSession(startGate: gate);
    await _pump(tester, session: session, validation: _FakeValidation());
    await _letStartFinish(tester);
    expect(session.starts, 1, reason: 'still starting: no recording yet');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(_dialog), findsNothing);
    expect(find.byType(RunTrackingScreen), findsNothing);
    expect(find.text('go-run'), findsOneWidget);
    gate.complete();
  });

  testWidgets('leaving without a proper finish still cleans up (dispose safety net)',
      (tester) async {
    final session = _FakeSession();
    await _pump(tester, session: session, validation: _FakeValidation());
    await _letStartFinish(tester);

    // Replace the whole tree, as when the route is torn down without a finish.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(session.disposes, greaterThanOrEqualTo(1));
  });
}
