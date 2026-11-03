import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/core/constants/store_links.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/pedometer/walking_goal_share_card.dart';
import 'package:share_run_challenge/features/run_result/run_finish_image_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_card.dart';

import '../../support/golden_helper.dart';
import '../../support/ko_localization.dart';

const _badges = RunFinishTierBadges(
  animalImage: 'assets/images/characters/tier_wolf.png',
  animalLabel: '늑대',
  angelImage: 'assets/images/characters/chibi_guardian_wing.png',
  angelLabel: '수호천사',
);

Widget _app(Widget child) => MaterialApp(
      locale: koTestLocale,
      supportedLocales: koTestSupportedLocales,
      localizationsDelegates: koTestDelegates,
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader(RunFinishShareCard.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Black.otf'));
    await loader.load();
  });

  tearDown(() {
    WalkingChallengeShare.debugShareOverride = null;
    WalkingChallengeShare.debugKakaoInstalledOverride = null;
    WalkingChallengeShare.debugKakaoShareOverride = null;
    RunFinishImageShare.debugCaptureOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RunFinishImageShare.channel, null);
  });

  group('text', () {
    test('step counts get thousands separators and never go negative', () {
      expect(WalkingGoalShareCard.commaSteps(0), '0');
      expect(WalkingGoalShareCard.commaSteps(999), '999');
      expect(WalkingGoalShareCard.commaSteps(8421), '8,421');
      expect(WalkingGoalShareCard.commaSteps(1234567), '1,234,567');
      expect(WalkingGoalShareCard.commaSteps(-5), '0');
    });

    test('brag text keeps the sentence and ends with the store link', () {
      final text = WalkingChallengeShare.dailyGoalBragText;
      expect(text, contains('오늘의 목표 달성'));
      expect(text, contains('쉐어런'));
      expect(text, contains('SHARE'));
      expect(text.trim().split('\n').last, kPlayStoreUrl);
      expect(kPlayStoreUrl, startsWith('https://play.google.com/store/apps/'));
      expect(text, isNot(contains('SRC')));
      expect(text, isNot(contains('셰어런')));
      expect(text, isNot(contains('쉐어 런')));
    });

    test('Kakao text limit cuts the sentence, never the store link', () async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      String? sent;
      WalkingChallengeShare.debugKakaoShareOverride = (text) async {
        sent = text;
      };
      final long = '${'가' * 400}\n#쉐어런\n$kPlayStoreUrl';
      final status = await WalkingChallengeShare.shareToKakao(text: long);
      expect(status, KakaoDirectShareStatus.sent);
      expect(sent!.length, lessThanOrEqualTo(WalkingChallengeShare.kakaoTextLimit));
      expect(sent!.endsWith(kPlayStoreUrl), isTrue);
    });
  });

  group('card', () {
    testWidgets('shows steps, headline, goal and date; tier circles only when given',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(WalkingGoalShareCard(
        steps: 8421,
        goalSteps: 6000,
        date: DateTime(2026, 11, 3),
      )));
      await tester.pump();

      expect(find.byKey(WalkingGoalShareCard.stepsKey), findsOneWidget);
      expect(find.text('8,421'), findsOneWidget);
      expect(find.text('오늘의 목표 달성!'), findsOneWidget);
      expect(find.text('목표 6,000걸음'), findsOneWidget);
      expect(find.text('11월 3일 화요일'), findsOneWidget);
      expect(find.text('쉐어런'), findsOneWidget);
      expect(find.byKey(WalkingGoalShareCard.badgesKey), findsNothing);

      await tester.pumpWidget(_app(WalkingGoalShareCard(
        steps: 8421,
        goalSteps: 6000,
        date: DateTime(2026, 11, 3),
        badges: _badges,
      )));
      await tester.pump();
      expect(find.byKey(WalkingGoalShareCard.badgesKey), findsOneWidget);
      expect(find.text('늑대'), findsOneWidget);

      // A user with no animal and no angel tier gets no circles, no gap.
      await tester.pumpWidget(_app(WalkingGoalShareCard(
        steps: 8421,
        goalSteps: 6000,
        date: DateTime(2026, 11, 3),
        badges: const RunFinishTierBadges(),
      )));
      await tester.pump();
      expect(find.byKey(WalkingGoalShareCard.badgesKey), findsNothing);
    });

    goldenTest('goal share card golden (4:5)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(RepaintBoundary(
        child: WalkingGoalShareCard(
          steps: 8421,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _badges,
        ),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/walking_goal_share_card.png'),
      );
    });
  });

  group('share button', () {
    final image = File('${Directory.systemTemp.path}/share_run_goal_test.png');

    Future<void> pumpDock(
      WidgetTester tester, {
      int? steps = 8421,
    }) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(Padding(
        padding: const EdgeInsets.all(16),
        child: WalkingDailyGoalCompleteCard(
          steps: steps,
          badges: _badges,
          now: () => DateTime(2026, 11, 3),
        ),
      )));
      await tester.pump();
    }

    testWidgets('system sheet gets the card image, the sentence and the link',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
      RunFinishImageShare.debugCaptureOverride = (key) async => image;
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sent, isNotNull);
      expect(sent!.files, hasLength(1));
      expect(sent!.files!.single.mimeType, 'image/png');
      expect(sent!.files!.single.path, image.path);
      expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
      expect(sent!.text, endsWith(kPlayStoreUrl));
      expect(sent!.subject, WalkingChallengeShare.dailyGoalBragSubject);
    });

    testWidgets('capture failure still shares the text and the link',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
      RunFinishImageShare.debugCaptureOverride =
          (key) async => throw StateError('not laid out');
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sent, isNotNull);
      expect(sent!.files, isNull);
      expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
    });

    testWidgets('without a step value the old text-only share is kept',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester, steps: null);
      expect(find.byKey(WalkingDailyGoalCompleteCard.captureKey), findsNothing);
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sent!.files, isNull);
      expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
    });

    testWidgets('KakaoTalk gets the image file with the sentence and link',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      RunFinishImageShare.debugCaptureOverride = (key) async => image;
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(RunFinishImageShare.channel, (call) async {
        calls.add(call);
        return true;
      });
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(calls, hasLength(1));
      expect(calls.single.method, 'shareTarget');
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['id'], 'kakao');
      expect(args['path'], image.path);
      expect(args['text'], WalkingChallengeShare.dailyGoalBragText);
      expect(sent, isNull);
    });

    testWidgets('KakaoTalk refusing the file falls back to the system sheet',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      RunFinishImageShare.debugCaptureOverride = (key) async => image;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              RunFinishImageShare.channel, (call) async => false);
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sent!.files, hasLength(1));
      expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
    });

    testWidgets('"다른 앱" in the chooser sends the image through the sheet',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      RunFinishImageShare.debugCaptureOverride = (key) async => image;
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(WalkingChallengeShare.systemChoiceKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sent!.files, hasLength(1));
      expect(sent!.files!.single.mimeType, 'image/png');
    });
  });
}
