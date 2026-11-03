import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/core/constants/store_links.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/src_logo_header.dart';
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
    WalkingChallengeShare.debugUidOverride = null;
    WalkingChallengeShare.debugUploadOverride = null;
    WalkingChallengeShare.debugKakaoFeedOverride = null;
    RunFinishImageShare.debugCaptureOverride = null;
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
      expect(sent!.length,
          lessThanOrEqualTo(WalkingChallengeShare.kakaoTextLimit));
      expect(sent!.endsWith(kPlayStoreUrl), isTrue);
    });
  });

  group('card', () {
    testWidgets(
        'shows steps, headline, goal and date; tier circles only when given',
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
      await tester.runAsync(() async {
        final context = tester.element(find.byType(WalkingGoalShareCard));
        for (final path in [
          _badges.animalImage!,
          _badges.angelImage!,
          SRCLogoHeader.assetPath,
        ]) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/walking_goal_share_card.png'),
      );
    });
  });

  group('rules', () {
    test('storage.rules: owner-only write, public read, PNG up to 5 MB', () {
      final rules = File('storage.rules').readAsStringSync();
      expect(rules, contains('match /share_cards/{uid}/{file}'));
      expect(rules, contains('allow read: if true;'));
      expect(rules, contains('request.auth.uid == uid'));
      expect(rules, contains('request.resource.size <= 5 * 1024 * 1024'));
      expect(rules, contains("request.resource.contentType == 'image/png'"));
      expect(rules, contains('allow read, write: if false;'));
      final firebaseJson = File('firebase.json').readAsStringSync();
      expect(firebaseJson, contains('"storage"'));
      expect(firebaseJson, contains('storage.rules'));
    });

    test('card path is one file per user per day', () {
      expect(WalkingChallengeShare.goalCardDay(DateTime(2026, 11, 3)),
          '2026-11-03');
      expect(WalkingChallengeShare.goalCardDay(DateTime(2026, 1, 9)),
          '2026-01-09');
    });
  });

  group('square card', () {
    goldenTest('goal share card golden (1:1)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(RepaintBoundary(
        child: WalkingGoalShareCard(
          steps: 12345,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _badges,
          square: true,
        ),
      )));
      await tester.pump();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(WalkingGoalShareCard));
        for (final path in [
          _badges.animalImage!,
          _badges.angelImage!,
          SRCLogoHeader.assetPath,
        ]) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/walking_goal_share_card_square.png'),
      );
    });

    testWidgets('square card keeps everything on screen without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(WalkingGoalShareCard(
        steps: 123456,
        goalSteps: 6000,
        date: DateTime(2026, 11, 3),
        badges: _badges,
        square: true,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('123,456'), findsOneWidget);
      expect(tester.getSize(find.byType(WalkingGoalShareCard)).height,
          WalkingGoalShareCard.squareHeight);
    });
  });

  group('share button', () {
    final portrait = File('${Directory.systemTemp.path}/goal_4x5_test.png');
    final square = File('${Directory.systemTemp.path}/goal_1x1_test.png');
    final captured = <String>[];

    setUp(() {
      captured.clear();
      WalkingChallengeShare.debugUidOverride = () => 'uid-1';
      RunFinishImageShare.debugCaptureOverride = (key) async {
        // The dock hands over its own boundary keys: 4:5 first, 1:1 second.
        final isSquare = key.currentContext?.size?.height ==
            WalkingGoalShareCard.squareHeight;
        captured.add(isSquare ? 'square' : 'portrait');
        return isSquare ? square : portrait;
      };
    });

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

    Future<void> tapBrag(WidgetTester tester) async {
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> chooseKakao(WidgetTester tester) async {
      await tapBrag(tester);
      await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('no KakaoTalk: 4:5 PNG, sentence and link via the sheet',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await tapBrag(tester);

      expect(captured, ['portrait']);
      expect(sent!.files, hasLength(1));
      expect(sent!.files!.single.mimeType, 'image/png');
      expect(sent!.files!.single.path, portrait.path);
      expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
      expect(sent!.text, endsWith(kPlayStoreUrl));
      expect(sent!.subject, WalkingChallengeShare.dailyGoalBragSubject);
    });

    testWidgets('"다른 앱" sends the 4:5 PNG through the sheet, not Kakao',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      var feeds = 0;
      WalkingChallengeShare.debugKakaoFeedOverride = (url, steps) async {
        feeds++;
      };
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await tapBrag(tester);
      await tester.tap(find.byKey(WalkingChallengeShare.systemChoiceKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(feeds, 0);
      expect(captured, ['portrait']);
      expect(sent!.files, hasLength(1));
      expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
    });

    testWidgets('capture failure on the sheet still shares text and link',
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
      await tapBrag(tester);

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
      await tapBrag(tester);

      expect(captured, isEmpty);
      expect(sent!.files, isNull);
      expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
    });

    testWidgets('KakaoTalk: square card is uploaded and sent as a feed card',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      File? uploaded;
      String? uploadUid;
      DateTime? uploadDate;
      WalkingChallengeShare.debugUploadOverride = (file, uid, date) async {
        uploaded = file;
        uploadUid = uid;
        uploadDate = date;
        return Uri.parse('https://firebasestorage.example/card.png');
      };
      Uri? feedUrl;
      int? feedSteps;
      WalkingChallengeShare.debugKakaoFeedOverride = (url, steps) async {
        feedUrl = url;
        feedSteps = steps;
      };
      var textSends = 0;
      WalkingChallengeShare.debugKakaoShareOverride = (text) async {
        textSends++;
      };
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester);
      await chooseKakao(tester);

      expect(captured, ['square']);
      expect(uploaded!.path, square.path);
      expect(uploadUid, 'uid-1');
      expect(uploadDate, DateTime(2026, 11, 3));
      expect(feedUrl, Uri.parse('https://firebasestorage.example/card.png'));
      expect(feedSteps, 8421);
      expect(textSends, 0);
      expect(sent, isNull);
    });

    testWidgets('feed title, description and one store button', (tester) async {
      expect(WalkingChallengeShare.goalFeedTitle(8421), '오늘의 목표 달성! 8,421걸음');
      expect(WalkingChallengeShare.goalFeedDescription, '걷고 SHARE 모으는 쉐어런');
      expect(WalkingChallengeShare.goalFeedButton, '쉐어런 시작하기');
    });

    testWidgets('upload failure falls back to the Kakao text template',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      WalkingChallengeShare.debugUploadOverride =
          (file, uid, date) async => throw StateError('offline');
      var feeds = 0;
      WalkingChallengeShare.debugKakaoFeedOverride = (url, steps) async {
        feeds++;
      };
      String? kakaoText;
      WalkingChallengeShare.debugKakaoShareOverride = (text) async {
        kakaoText = text;
      };

      await pumpDock(tester);
      await chooseKakao(tester);

      expect(feeds, 0);
      expect(kakaoText, isNotNull);
      expect(kakaoText!.endsWith(kPlayStoreUrl), isTrue);
      expect(kakaoText!.length,
          lessThanOrEqualTo(WalkingChallengeShare.kakaoTextLimit));
    });

    testWidgets('not signed in falls back to the Kakao text template',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      WalkingChallengeShare.debugUidOverride = () => null;
      var uploads = 0;
      WalkingChallengeShare.debugUploadOverride = (file, uid, date) async {
        uploads++;
        return Uri.parse('https://example.com/x.png');
      };
      String? kakaoText;
      WalkingChallengeShare.debugKakaoShareOverride = (text) async {
        kakaoText = text;
      };

      await pumpDock(tester);
      await chooseKakao(tester);

      expect(uploads, 0);
      expect(kakaoText, isNotNull);
    });

    testWidgets('Kakao feed failure falls back to the Kakao text template',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      WalkingChallengeShare.debugUploadOverride =
          (file, uid, date) async => Uri.parse('https://example.com/x.png');
      WalkingChallengeShare.debugKakaoFeedOverride =
          (url, steps) async => throw StateError('kakao refused');
      String? kakaoText;
      WalkingChallengeShare.debugKakaoShareOverride = (text) async {
        kakaoText = text;
      };

      await pumpDock(tester);
      await chooseKakao(tester);

      expect(kakaoText, isNotNull);
    });
  });
}
