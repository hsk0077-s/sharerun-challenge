import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/repositories/user_repository.dart';
import 'dart:async';
import 'package:share_run_challenge/features/run_tracking/services/ble_heart_rate_service.dart';
import 'package:share_run_challenge/features/run_tracking/services/health_data_service.dart';
import 'package:share_run_challenge/screens/device_connection_screen.dart';
import 'package:share_run_challenge/screens/wearable_brand_guide_sheet.dart';

class _FakeUser implements User {
  @override
  String get uid => 'u1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepo implements UserRepository {
  final watchTypes = <WatchType>[];
  var onboardingCompleted = 0;

  @override
  Future<void> updateWatchType({
    required String uid,
    required WatchType watchType,
  }) async =>
      watchTypes.add(watchType);

  @override
  Future<void> completeNativeDeviceOnboarding({required String uid}) async =>
      onboardingCompleted++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHealth extends HealthDataService {
  _FakeHealth({
    this.result = const HealthAuthorizationResult(granted: true),
    this.samples = const HealthRecentSamples(heartRateCount: 3, stepsCount: 2),
  });

  final HealthAuthorizationResult result;
  final HealthRecentSamples? samples;
  var authCalls = 0;

  @override
  Future<HealthAuthorizationResult> requestWatchLinkAuthorization() async {
    authCalls++;
    return result;
  }

  @override
  Future<HealthRecentSamples?> readRecentSampleCounts({
    Duration window = const Duration(hours: 24),
  }) async =>
      samples;
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeHealth health,
  required _FakeRepo repo,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final profile = UserModel.dashboardDefault(uid: 'u1');
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authStateChangesProvider
          .overrideWith((ref) => Stream<User?>.value(_FakeUser())),
      activeUserProfileProvider
          .overrideWith((ref) => Stream<UserModel>.value(profile)),
      userRepositoryProvider.overrideWithValue(repo),
      healthDataServiceProvider.overrideWithValue(health),
    ],
    child: MaterialApp(
      theme: SrcTheme.light,
      home: const DeviceConnectionScreen(),
      routes: {
        RouteNames.preliminaryEval: (_) =>
            const Scaffold(body: Text('prelim-eval')),
      },
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openGuide(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('wearable-guide-entry')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('caption names smartbands and GPS watches, not only Wear OS',
      (tester) async {
    await _pump(tester, health: _FakeHealth(), repo: _FakeRepo());
    expect(find.text(AppStrings.deviceConnectionGoogleCaption), findsOneWidget);
    expect(find.textContaining('샤오미 미밴드'), findsOneWidget);
    expect(find.textContaining('Wear OS 기기 지원'), findsNothing);
  });

  testWidgets('guide lists all six brands and filters by search',
      (tester) async {
    await _pump(tester, health: _FakeHealth(), repo: _FakeRepo());
    await _openGuide(tester);
    expect(wearableBrands, hasLength(6));
    for (final b in wearableBrands) {
      expect(find.byKey(WearableBrandGuide.brandKey(b.id)), findsOneWidget);
    }

    await tester.enterText(find.byKey(WearableBrandGuide.searchFieldKey), '가민');
    await tester.pump();
    expect(find.byKey(WearableBrandGuide.brandKey('garmin')), findsOneWidget);
    expect(find.byKey(WearableBrandGuide.brandKey('xiaomi')), findsNothing);

    // English alias, case-insensitive.
    await tester.enterText(
        find.byKey(WearableBrandGuide.searchFieldKey), 'SUUNTO');
    await tester.pump();
    expect(find.byKey(WearableBrandGuide.brandKey('coros_suunto')),
        findsOneWidget);

    await tester.enterText(
        find.byKey(WearableBrandGuide.searchFieldKey), 'zzzz');
    await tester.pump();
    expect(find.byKey(WearableBrandGuide.emptyKey), findsOneWidget);
  });

  testWidgets('selecting a brand shows its 3-step guide and a connect CTA',
      (tester) async {
    await _pump(tester, health: _FakeHealth(), repo: _FakeRepo());
    await _openGuide(tester);
    await tester.tap(find.byKey(WearableBrandGuide.brandKey('xiaomi')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mi Fitness'), findsWidgets);
    for (var i = 1; i <= 3; i++) {
      expect(find.byKey(WearableBrandGuide.stepKey(i)), findsOneWidget);
    }
    expect(find.byKey(WearableBrandGuide.stepKey(4)), findsNothing);
    expect(find.text(AppStrings.wearableGuideCtaAndroid), findsOneWidget);
  });

  test('every brand has exactly three steps', () {
    for (final b in wearableBrands) {
      expect(b.steps, hasLength(3), reason: b.id);
    }
  });

  testWidgets('guide CTA runs the Health Connect flow and saves the watch',
      (tester) async {
    final health = _FakeHealth();
    final repo = _FakeRepo();
    await _pump(tester, health: health, repo: repo);
    await _openGuide(tester);
    await tester.tap(find.byKey(WearableBrandGuide.brandKey('fitbit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(WearableBrandGuide.connectButtonKey));
    await tester.pumpAndSettle();

    expect(health.authCalls, 1);
    expect(repo.watchTypes, [WatchType.galaxyWatch]);
    expect(repo.onboardingCompleted, 1);
    expect(find.text(AppStrings.healthConnectNoSamplesTip), findsNothing);
    expect(find.text('prelim-eval'), findsOneWidget);
  });

  testWidgets('zero samples after grant shows the band-sync tip',
      (tester) async {
    final repo = _FakeRepo();
    await _pump(
      tester,
      health: _FakeHealth(
        samples: const HealthRecentSamples(heartRateCount: 0, stepsCount: 0),
      ),
      repo: repo,
    );
    await tester.tap(find.text(AppStrings.watchSyncGoogle));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.healthConnectNoSamplesTip), findsOneWidget);
    await tester.tap(find.byKey(const Key('health-connect-tip-ok')));
    await tester.pumpAndSettle();
    expect(repo.watchTypes, [WatchType.galaxyWatch]);
    expect(find.text('prelim-eval'), findsOneWidget);
  });

  testWidgets('missing Health Connect opens the install flow, saves nothing',
      (tester) async {
    final repo = _FakeRepo();
    final health = _FakeHealth(
      result:
          const HealthAuthorizationResult(granted: false, openedInstall: true),
    );
    await _pump(tester, health: health, repo: repo);
    await tester.tap(find.text(AppStrings.watchSyncGoogle));
    await tester.pumpAndSettle();

    expect(health.authCalls, 1);
    expect(repo.watchTypes, isEmpty);
    expect(find.textContaining('Health Connect 설치 화면'), findsOneWidget);
    expect(find.text('prelim-eval'), findsNothing);
  });

  testWidgets('BLE Heart Rate section scans, connects, and displays live BPM',
      (tester) async {
    final controller = StreamController<Map<String, Object?>>.broadcast();
    addTearDown(controller.close);
    final bleAdapter = _FakeBleAdapter(controller);
    final bleService = BleHeartRateService(adapter: bleAdapter);
    addTearDown(bleService.dispose);

    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profile = UserModel.dashboardDefault(uid: 'u1');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authStateChangesProvider
            .overrideWith((ref) => Stream<User?>.value(_FakeUser())),
        activeUserProfileProvider
            .overrideWith((ref) => Stream<UserModel>.value(profile)),
        userRepositoryProvider.overrideWithValue(_FakeRepo()),
        healthDataServiceProvider.overrideWithValue(_FakeHealth()),
        bleHeartRateServiceProvider.overrideWithValue(bleService),
      ],
      child: MaterialApp(
        theme: SrcTheme.light,
        home: const DeviceConnectionScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ble-hr-card')), findsOneWidget);
    expect(find.text('미연결'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ble-hr-scan-button')));
    await tester.pump();
    controller.add({
      'type': 'deviceFound',
      'id': '11:22:33:44:55:66',
      'name': 'Coospo HW807',
      'rssi': -48,
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Coospo HW807'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ble-hr-connect-11:22:33:44:55:66')));
    await tester.pump();
    controller.add({
      'type': 'measurement',
      'bytes': [0x00, 148],
    });
    await tester.pumpAndSettle();

    expect(find.text('♥ 148 BPM'), findsOneWidget);
    expect(find.byKey(const Key('ble-hr-disconnect-button')), findsOneWidget);
  });
}

class _FakeBleAdapter implements BleHeartRateAdapter {
  _FakeBleAdapter(this.controller);
  final StreamController<Map<String, Object?>> controller;

  @override
  Stream<Map<String, Object?>> get events => controller.stream;

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    controller.add({'type': 'state', 'state': 'scanning'});
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(String deviceId, {String? deviceName}) async {
    controller.add({
      'type': 'state',
      'state': 'connected',
      'deviceId': deviceId,
      'deviceName': deviceName ?? 'Coospo HW807',
    });
  }

  @override
  Future<void> disconnect() async {
    controller.add({'type': 'state', 'state': 'disconnected'});
  }
}
