import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/run_tracking/models/run_telemetry.dart';
import 'package:share_run_challenge/features/run_tracking/music_controls.dart';
import 'package:share_run_challenge/features/run_tracking/run_recording_policy.dart';
import 'package:share_run_challenge/features/run_tracking/services/run_session_service.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_models.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_providers.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_run_end.dart';
import 'package:share_run_challenge/screens/run_tracking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/ko_localization.dart';

/// Saves a phone-sized PNG when RUN_TRACKING_SHOT=before or after.
/// The suite skips it so CI does not write artifacts.
void main() {
  final shot = Platform.environment['RUN_TRACKING_SHOT'];
  testWidgets(
    'save the run screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({runChecklistCompletedKey: true});
      final session = _ShotSession();
      final profile = UserModel.dashboardDefault(uid: 'u1').copyWith(
        healthDataConsent: true,
        gradeRank: 6,
      );
      const mission = WorldTourMission(
        missionId: 'm1',
        title: '에펠탑',
        countryCode: 'FR',
        landmarkId: 'eiffel_tower',
        targetKm: 5,
        order: 1,
        progressKm: 1,
        completed: false,
      );
      await tester.runAsync(_loadPretendard);
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            runSessionServiceProvider.overrideWithValue(session),
            musicBridgeProvider.overrideWithValue(_ShotMusic()),
            activeUserProfileProvider.overrideWith(
              (ref) => Stream<UserModel>.value(profile),
            ),
            authStateChangesProvider.overrideWith(
              (ref) => Stream<User?>.value(_ShotUser()),
            ),
            worldTourMeProvider.overrideWith(
              (ref) async => const WorldTourMe(
                missions: [mission],
                passport: [],
                completedCount: 0,
                totalCount: 1,
              ),
            ),
          ],
          child: MaterialApp(
            theme: SrcTheme.night,
            locale: koTestLocale,
            supportedLocales: koTestSupportedLocales,
            localizationsDelegates: koTestDelegates,
            home: const _KeepProfile(
              child: RepaintBoundary(
                key: Key('run-shot'),
                child: RunTrackingScreen(
                  worldTourRun: WorldTourRunArgs(
                    missionId: 'm1',
                    landmarkId: 'eiffel_tower',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      session.emit(
        const RunTelemetry(
          distanceKm: 1.5,
          durationSeconds: 450,
          currentHeartRate: 148,
          currentCadenceSpm: 172,
          gyroStabilityScore: 0.95,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('run-shot')),
      );
      final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.png),
      );
      final file = File('/opt/cursor/artifacts/run-tracking-$shot.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    },
    skip: shot == null,
  );
}

class _KeepProfile extends ConsumerWidget {
  const _KeepProfile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activeUserProfileProvider);
    return child;
  }
}

Future<void> _loadPretendard() async {
  final loader = FontLoader('Pretendard');
  for (final file in [
    'Pretendard-Regular.otf',
    'Pretendard-SemiBold.otf',
    'Pretendard-Black.otf',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

class _ShotUser implements User {
  @override
  String get uid => 'u1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ShotMusic implements MusicBridge {
  @override
  bool get supported => true;

  @override
  Future<bool> openApp() async => true;

  @override
  Future<bool> send(MusicKey key) async => true;
}

class _ShotSession implements RunSessionService {
  final _telemetry = StreamController<RunTelemetry>.broadcast();

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
    throw UnimplementedError();
  }
}
