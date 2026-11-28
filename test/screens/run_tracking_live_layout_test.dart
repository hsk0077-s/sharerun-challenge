import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/run_tracking/models/run_telemetry.dart';
import 'package:share_run_challenge/features/run_tracking/run_recording_policy.dart';
import 'package:share_run_challenge/features/run_tracking/services/run_session_service.dart';
import 'package:share_run_challenge/features/run_tracking/widgets/run_tracking_hud.dart';
import 'package:share_run_challenge/features/world_tour/widgets/world_tour_run_path.dart';
import 'package:share_run_challenge/features/world_tour/widgets/world_tour_widgets.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_models.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_providers.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_run_end.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_shop_art.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/screens/run_tracking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/ko_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hud shows distance, time, and pace, and hides a short pace',
      (tester) async {
    await _pumpHud(
      tester,
      const RunTelemetry(
        distanceKm: 1.25,
        durationSeconds: 450,
        currentHeartRate: null,
        currentCadenceSpm: null,
        gyroStabilityScore: 0.95,
      ),
    );
    expect(find.text('1.25'), findsOneWidget);
    expect(find.text('07:30'), findsOneWidget);
    expect(find.text("6'00\"/km"), findsOneWidget);
    expect(find.text('--'), findsOneWidget);
    expect(find.textContaining('자이로'), findsNothing);
    expect(find.textContaining('심박'), findsNothing);
    expect(find.textContaining('케이던스'), findsNothing);
  });

  testWidgets('hud hides the heart line until a reading exists',
      (tester) async {
    await _pumpHud(
      tester,
      const RunTelemetry(
        distanceKm: 0,
        durationSeconds: 12,
        currentHeartRate: null,
        currentCadenceSpm: 172,
        gyroStabilityScore: 0.95,
      ),
    );
    expect(find.text('00:12'), findsOneWidget);
    expect(find.text('--'), findsWidgets);
    expect(find.textContaining('심박'), findsNothing);
    expect(find.textContaining('케이던스 172 SPM'), findsOneWidget);
    expect(find.textContaining('자이로'), findsNothing);
  });

  testWidgets('hud shows heart rate when the watch has one', (tester) async {
    await _pumpHud(
      tester,
      const RunTelemetry(
        distanceKm: 0.02,
        durationSeconds: 40,
        currentHeartRate: 148,
        currentCadenceSpm: null,
        gyroStabilityScore: 0.2,
      ),
    );
    expect(find.textContaining('심박 148 BPM'), findsOneWidget);
    expect(find.textContaining('케이던스'), findsNothing);
    expect(find.text('--'), findsWidgets);
  });

  testWidgets('numbers do not overflow on a small screen with large text',
      (tester) async {
    await _pumpHud(
      tester,
      const RunTelemetry(
        distanceKm: 12.34,
        durationSeconds: 3725,
        currentHeartRate: 160,
        currentCadenceSpm: 180,
        gyroStabilityScore: 0.95,
      ),
      size: const Size(280, 180),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the walker sits at 0%, 50%, and 100% of a straight road',
      (tester) async {
    await _pumpPath(tester, progressKm: 0, runKm: 0, targetKm: 10);
    expect(_fraction(tester), closeTo(0, 0.04));
    expect(find.byKey(WorldTourRunPath.arrivedKey), findsNothing);
    expect(find.byKey(WorldTourRunPath.backdropKey), findsOneWidget);

    await _pumpPath(tester, progressKm: 2, runKm: 3, targetKm: 10);
    expect(_fraction(tester), closeTo(0.5, 0.04));
    expect(find.byKey(WorldTourRunPath.arrivedKey), findsNothing);

    await _pumpPath(tester, progressKm: 4, runKm: 6, targetKm: 10);
    expect(_fraction(tester), closeTo(1, 0.04));
    final runner = tester.getRect(find.byKey(WorldTourRunPath.runnerKey));
    final landmark = tester.getRect(find.byKey(WorldTourRunPath.landmarkKey));
    expect(runner.right, lessThanOrEqualTo(landmark.left + 1));
    expect(runner.left, greaterThan(0));
    expect(find.byKey(WorldTourRunPath.arrivedKey), findsOneWidget);
    expect(find.text('도착'), findsOneWidget);
  });

  testWidgets('eiffel uses the existing village picture, faded, and cached',
      (tester) async {
    await _pumpPath(tester, progressKm: 0, runKm: 1, targetKm: 5);
    final image = tester.widget<Image>(
      find.byKey(WorldTourRunPath.backdropKey),
    );
    final resized = image.image as ResizeImage;
    expect(
      (resized.imageProvider as AssetImage).assetName,
      WorldTourShopArt.village('eiffel_tower'),
    );
    expect(resized.width, inInclusiveRange(1, 640));
    expect(image.opacity, isA<AlwaysStoppedAnimation<double>>());
    expect(
      (image.opacity! as AlwaysStoppedAnimation<double>).value,
      closeTo(0.35, 0.001),
    );
  });

  testWidgets('a country without a village still uses its landmark scene',
      (tester) async {
    await _pumpPath(
      tester,
      progressKm: 0,
      runKm: 0,
      targetKm: 4,
      landmarkId: 'gwanghwamun',
    );
    final image = tester.widget<Image>(
      find.byKey(WorldTourRunPath.backdropKey),
    );
    final resized = image.image as ResizeImage;
    expect(
      (resized.imageProvider as AssetImage).assetName,
      'assets/images/world_tour/gwanghwamun_approach_far.webp',
    );
  });

  testWidgets('no mission, or a landmark without art, hides the path',
      (tester) async {
    await _pumpPath(tester, progressKm: 0, runKm: 0, targetKm: 5, hide: true);
    expect(find.byKey(WorldTourRunPath.pathKey), findsNothing);

    await _pumpPath(
      tester,
      progressKm: 0,
      runKm: 0,
      targetKm: 5,
      landmarkId: 'not-a-landmark',
    );
    expect(find.byKey(WorldTourRunPath.pathKey), findsNothing);
  });

  testWidgets('the path does not overflow in a short band or with large text',
      (tester) async {
    await _pumpPath(
      tester,
      progressKm: 1,
      runKm: 1,
      targetKm: 4,
      size: const Size(160, 48),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(WorldTourRunPath.pathKey), findsOneWidget);
  });

  testWidgets('the chip remainder and the walker use the same kilometres',
      (tester) async {
    final mission = _mission(targetKm: 5, progressKm: 3);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldTourMeProvider.overrideWith(
            (ref) async => WorldTourMe(
              missions: [mission],
              passport: const [],
              completedCount: 0,
              totalCount: 1,
            ),
          ),
        ],
        child: _app(
          home: Scaffold(
            body: Column(
              children: [
                const WorldTourRunChip(
                  args: WorldTourRunArgs(
                    missionId: 'm1',
                    landmarkId: 'eiffel_tower',
                  ),
                  runKm: 1,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: WorldTourRunPath(
                    mission: mission,
                    runKm: 1,
                    runnerAsset: 'assets/images/characters/tier_turtle.png',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('에펠탑까지 1 km 남음'), findsOneWidget);
    expect(_fraction(tester), closeTo(0.8, 0.04));
  });

  testWidgets('the live screen hides gyro and asks before ending',
      (tester) async {
    SharedPreferences.setMockInitialValues({runChecklistCompletedKey: true});
    final session = _FakeSession();
    final profile =
        UserModel.dashboardDefault(uid: 'u1').copyWith(healthDataConsent: true);
    final mission = _mission(targetKm: 5, progressKm: 4);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionServiceProvider.overrideWithValue(session),
          activeUserProfileProvider.overrideWith(
            (ref) => Stream<UserModel>.value(profile),
          ),
          authStateChangesProvider.overrideWith(
            (ref) => Stream<User?>.value(_FakeUser()),
          ),
          worldTourMeProvider.overrideWith(
            (ref) async => WorldTourMe(
              missions: [mission],
              passport: const [],
              completedCount: 0,
              totalCount: 1,
            ),
          ),
        ],
        child: _app(
          home: const RunTrackingScreen(
            worldTourRun: WorldTourRunArgs(
              missionId: 'm1',
              landmarkId: 'eiffel_tower',
            ),
          ),
        ),
      ),
    );
    await _letStartFinish(tester);
    session.emit(
      const RunTelemetry(
        distanceKm: 3.2,
        durationSeconds: 960,
        currentHeartRate: 150,
        currentCadenceSpm: 174,
        gyroStabilityScore: 0.95,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('3.20'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
    expect(find.text("5'00\"/km"), findsOneWidget);
    expect(find.textContaining('자이로'), findsNothing);
    expect(find.textContaining('심박 150 BPM'), findsOneWidget);
    expect(find.textContaining('케이던스 174 SPM'), findsOneWidget);
    expect(find.byKey(WorldTourRunPath.backdropKey), findsOneWidget);
    expect(find.byKey(WorldTourRunChip.chipKey), findsOneWidget);

    await tester.tap(find.text('러닝 끝내고 검증하기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('run-leave-dialog')), findsOneWidget);
    expect(session.finishes, 0);

    await tester.tap(find.byKey(const Key('run-leave-continue')));
    await tester.pumpAndSettle();
    expect(session.finishes, 0);
    expect(find.byType(RunTrackingScreen), findsOneWidget);
  });
}

Future<void> _pumpHud(
  WidgetTester tester,
  RunTelemetry telemetry, {
  Size size = const Size(400, 360),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _app(
      textScale: textScale,
      home: Scaffold(
        body: Column(
          children: [
            Expanded(child: RunTrackingHud(telemetry: telemetry)),
            RunTrackingVitals(telemetry: telemetry),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpPath(
  WidgetTester tester, {
  required double progressKm,
  required double runKm,
  required double targetKm,
  String landmarkId = 'eiffel_tower',
  bool hide = false,
  Size size = const Size(300, 120),
  double textScale = 1,
}) async {
  final drawn = hide
      ? null
      : _mission(
          targetKm: targetKm,
          progressKm: progressKm,
          landmarkId: landmarkId,
        );
  await tester.binding.setSurfaceSize(const Size(400, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _app(
      textScale: textScale,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: WorldTourRunPath(
              mission: drawn,
              runKm: runKm,
              runnerAsset: 'assets/images/characters/tier_turtle.png',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _fraction(WidgetTester tester) {
  final path = tester.getRect(find.byKey(WorldTourRunPath.pathKey));
  final runner = tester.getRect(find.byKey(WorldTourRunPath.runnerKey));
  final landmark = tester.getRect(find.byKey(WorldTourRunPath.landmarkKey));
  final span = landmark.left - path.left - runner.width;
  return (runner.left - path.left) / span;
}

Widget _app({required Widget home, double textScale = 1}) {
  return MaterialApp(
    theme: SrcTheme.night,
    locale: koTestLocale,
    supportedLocales: koTestSupportedLocales,
    localizationsDelegates: koTestDelegates,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: home,
  );
}

WorldTourMission _mission({
  required double targetKm,
  required double progressKm,
  String landmarkId = 'eiffel_tower',
}) {
  return WorldTourMission(
    missionId: 'm1',
    title: 'landmark',
    countryCode: 'FR',
    landmarkId: landmarkId,
    targetKm: targetKm,
    order: 1,
    progressKm: progressKm,
    completed: false,
  );
}

class _FakeUser implements User {
  @override
  String get uid => 'u1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSession implements RunSessionService {
  final _telemetry = StreamController<RunTelemetry>.broadcast();
  var finishes = 0;

  void emit(RunTelemetry value) => _telemetry.add(value);

  @override
  Stream<RunTelemetry> get telemetryStream => _telemetry.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<CompletedRunSession> finish({
    String? activityId,
    String? userId,
  }) async {
    finishes++;
    throw UnimplementedError();
  }
}

Future<void> _letStartFinish(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
}
