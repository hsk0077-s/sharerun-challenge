import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/launch/intro_screen.dart';
import 'package:share_run_challenge/features/launch/intro_store.dart';
import 'package:share_run_challenge/features/launch/launch_splash.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _intro({required VoidCallback onFinished, bool replay = false}) {
  return MaterialApp(
    home: IntroScreen(onFinished: onFinished, replay: replay),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WalkingChallengeNotificationService.launchedFromNotification.value = false;
  });

  test('intro is unseen on a fresh install and stays seen once marked',
      () async {
    const store = IntroStore();
    expect(await store.seen(), isFalse);
    await store.markSeen();
    expect(await store.seen(), isTrue);
  });

  testWidgets('skip on the first page marks the intro seen and finishes',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(_intro(onFinished: () => finished++));

    expect(find.text('걸으면 SHARE가 쌓여요'), findsWidgets);
    await tester.tap(find.byKey(IntroScreen.skipKey));
    await tester.pumpAndSettle();

    expect(finished, 1);
    expect(await const IntroStore().seen(), isTrue);
  });

  testWidgets('next goes through three pages, the last has start and login',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(_intro(onFinished: () => finished++));

    await tester.tap(find.byKey(IntroScreen.nextKey));
    await tester.pumpAndSettle();
    expect(find.text('한 걸음이 나눔이 된다'), findsWidgets);
    expect(find.text('회사 이름으로 기부돼요 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인'),
        findsOneWidget);

    await tester.tap(find.byKey(IntroScreen.nextKey));
    await tester.pumpAndSettle();
    expect(find.byKey(IntroScreen.skipKey), findsNothing);
    expect(find.byKey(IntroScreen.startKey), findsOneWidget);
    expect(find.byKey(IntroScreen.loginKey), findsOneWidget);

    await tester.tap(find.byKey(IntroScreen.startKey));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(await const IntroStore().seen(), isTrue);
  });

  testWidgets('replay has a close button and no start or login',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(_intro(onFinished: () => finished++, replay: true));
    await tester.tap(find.byKey(IntroScreen.nextKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(IntroScreen.nextKey));
    await tester.pumpAndSettle();

    expect(find.byKey(IntroScreen.startKey), findsNothing);
    expect(find.byKey(IntroScreen.loginKey), findsNothing);
    await tester.tap(find.byKey(IntroScreen.closeKey));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });

  testWidgets('intro never names a beneficiary or says the user pays',
      (tester) async {
    await tester.pumpWidget(_intro(onFinished: () {}));
    final seen = <String>[];
    for (var i = 0; i < 3; i++) {
      seen.addAll(
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? ''),
      );
      if (i < 2) {
        await tester.tap(find.byKey(IntroScreen.nextKey));
        await tester.pumpAndSettle();
      }
    }
    final all = seen.join('\n');
    for (final banned in ['UNICEF', '유니세프', '영수증', '세금', '완벽', '내 이름으로', '5회']) {
      expect(all.contains(banned), isFalse, reason: banned);
    }
  });

  testWidgets('intro and splash fit a small phone with the largest text size',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget big(Widget child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2.0),
          ),
          child: child,
        );

    await tester.pumpWidget(big(_intro(onFinished: () {})));
    for (var i = 0; i < 3; i++) {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'intro page $i');
      if (i < 2) await tester.tap(find.byKey(IntroScreen.nextKey));
    }

    await tester.pumpWidget(big(const MaterialApp(home: LaunchSplashView())));
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'splash');
  });

  test('splash photo and logo are real images, not placeholders', () async {
    for (final asset in [LaunchSplashView.photoAsset, LaunchSplashView.logoAsset]) {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThanOrEqualTo(64), reason: asset);
      expect(frame.image.height, greaterThanOrEqualTo(64), reason: asset);
    }
  });

  group('launch splash', () {
    Widget app(StreamController<UserModel> profile, {Duration? maxWait}) {
      return ProviderScope(
        overrides: [
          activeUserProfileProvider.overrideWith((ref) => profile.stream),
        ],
        child: MaterialApp(
          home: LaunchSplashGate(
            maxWait: maxWait ?? const Duration(seconds: 30),
            child: const Text('home'),
          ),
        ),
      );
    }

    testWidgets('shows until the profile is ready, then goes with no extra wait',
        (tester) async {
      final profile = StreamController<UserModel>();
      addTearDown(profile.close);
      await tester.pumpWidget(app(profile));
      await tester.pump();
      expect(find.byKey(LaunchSplashGate.splashKey), findsOneWidget);
      expect(find.text(LaunchSplashView.slogan), findsOneWidget);

      profile.add(UserModel.dashboardDefault(uid: 'u1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(LaunchSplashGate.splashKey), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('gives up after maxWait so a slow server cannot trap the user',
        (tester) async {
      final profile = StreamController<UserModel>();
      addTearDown(profile.close);
      await tester.pumpWidget(
        app(profile, maxWait: const Duration(milliseconds: 100)),
      );
      expect(find.byKey(LaunchSplashGate.splashKey), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(LaunchSplashGate.splashKey), findsNothing);
    });

    testWidgets('is skipped when a notification opened the app',
        (tester) async {
      WalkingChallengeNotificationService.launchedFromNotification.value = true;
      final profile = StreamController<UserModel>();
      addTearDown(profile.close);
      await tester.pumpWidget(app(profile));
      await tester.pump();

      expect(find.byKey(LaunchSplashGate.splashKey), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  testWidgets('first run shows the photo splash, then the intro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FirstRunSplash(
          duration: const Duration(milliseconds: 300),
          child: IntroScreen(onFinished: () {}),
        ),
      ),
    );
    expect(find.byKey(FirstRunSplash.splashKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(FirstRunSplash.splashKey), findsNothing);
    expect(find.byKey(IntroScreen.nextKey), findsOneWidget);
  });
}
