import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/core/constants/store_links.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/src_logo_header.dart';
import 'package:share_run_challenge/features/invite/invite_link.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/pedometer/walking_goal_share_card.dart';
import 'package:share_run_challenge/features/run_result/run_finish_image_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_card.dart';

import '../../support/golden_helper.dart';
import '../../support/ko_localization.dart';

const _snail = RunFinishTierBadges(
  animalImage: 'assets/images/characters/chibi_snail_smiling.png',
  animalLabel: '달팽이',
);

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
    WalkingChallengeShare.debugKakaoFeedLinkSink = null;
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

    test('brag text with steps and an invite code: code line, then the link',
        () {
      final text = WalkingChallengeShare.dailyGoalBragTextFor(
        steps: 8421,
        inviteCode: 'abcd2345',
      );
      expect(text, contains('오늘 8,421걸음을 채웠어요'));
      expect(text, contains('#쉐어런 #워킹챌린지 #오늘의목표달성'));
      expect(text, contains('초대 코드 ABCD2345'));
      final lines = text.split('\n');
      expect(lines.last, '$kPlayStoreUrl&referrer=invite%3DABCD2345');
      expect(lines[lines.length - 2], '초대 코드 ABCD2345');
    });

    test('no invite code (or a bad one): the plain store link only', () {
      for (final code in [null, '', '  ', 'bad code!', 'a' * 40]) {
        final text = WalkingChallengeShare.dailyGoalBragTextFor(
          steps: 100,
          inviteCode: code,
        );
        expect(text.split('\n').last, kPlayStoreUrl, reason: '$code');
        expect(text, isNot(contains('초대 코드')), reason: '$code');
        expect(text, isNot(contains('referrer')), reason: '$code');
      }
    });

    test('every language has the owner copy; only Korean says 쉐어런', () {
      final table = jsonDecode(
        File('docs/l10n/remaining-ko-strings.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final entries = {
        for (final e in table['strings'] as List<dynamic>)
          (e as Map<String, dynamic>)['key'] as String: e,
      };
      const prefix = 'pedometer.walking_goal_share_card.';
      const langs = [
        'en',
        'ja',
        'zh-TW',
        'es',
        'pt-BR',
        'de',
        'fr',
        'vi',
        'th',
        'id'
      ];
      for (final key in [
        'brag_steps',
        'feed_title',
        'feed_button',
        'headline',
        'goal',
        'tagline',
        'streak'
      ]) {
        final entry = entries['$prefix$key'] as Map<String, dynamic>;
        for (final lang in langs) {
          final text = entry[lang] as String;
          expect(text.trim(), isNotEmpty, reason: '$key $lang');
          expect(text, isNot(contains('쉐어런')), reason: '$key $lang');
          expect(text, isNot(contains('SRC')), reason: '$key $lang');
          expect(RegExp(r'[가-힣]').hasMatch(text), isFalse,
              reason: '$key $lang');
        }
      }
      for (final lang in langs) {
        final brag = (entries['${prefix}brag_steps']
            as Map<String, dynamic>)[lang] as String;
        expect(brag, contains(r'${steps}'), reason: lang);
        expect(brag, contains('ShareRun'), reason: lang);
        expect(brag, contains('SHARE'), reason: lang);
        expect(brag, contains('#ShareRun'), reason: lang);
        final feed = (entries['${prefix}feed_title']
            as Map<String, dynamic>)[lang] as String;
        expect(feed, contains(r'${steps}'), reason: lang);
        final goal =
            (entries['${prefix}goal'] as Map<String, dynamic>)[lang] as String;
        expect(goal, contains(r'${goal}'), reason: lang);
      }
      final ko = entries['${prefix}brag_steps'] as Map<String, dynamic>;
      expect(ko['ko'], contains('쉐어런'));
      expect(ko['ko'], contains(r'${steps}걸음'));
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

  Future<void> precache(WidgetTester tester) async {
    await tester.runAsync(() async {
      final context = tester.element(find.byType(WalkingGoalShareCard));
      for (final path in [
        _badges.animalImage!,
        _badges.angelImage!,
        _snail.animalImage!,
        SRCLogoHeader.assetPath,
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> goldenCard(
    WidgetTester tester, {
    required String file,
    required WalkingGoalShareCard card,
  }) async {
    final height = card.square
        ? WalkingGoalShareCard.squareHeight
        : WalkingGoalShareCard.canvasHeight;
    tester.view.physicalSize = Size(WalkingGoalShareCard.canvasWidth, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(RepaintBoundary(child: card)));
    await tester.pump();
    await precache(tester);
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/$file'),
    );
  }

  group('card', () {
    testWidgets('shows steps, ribbon, goal, date, tagline and the animal',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(WalkingGoalShareCard(
        steps: 8421,
        goalSteps: 6000,
        date: DateTime(2026, 11, 3),
        badges: _badges,
      )));
      await tester.pump();

      expect(find.byKey(WalkingGoalShareCard.stepsKey), findsOneWidget);
      expect(find.text('8,421'), findsOneWidget);
      expect(find.text('오늘의 목표 달성!'), findsOneWidget);
      expect(find.text('목표 6,000걸음'), findsOneWidget);
      expect(find.text('11월 3일 화요일'), findsOneWidget);
      expect(find.text('쉐어런'), findsOneWidget);
      expect(find.text('나도 걸으면 리워드와 기부가 쌓여요'), findsOneWidget);
      expect(find.byKey(WalkingGoalShareCard.animalKey), findsOneWidget);
      expect(find.text('늑대'), findsOneWidget);
      expect(find.byKey(WalkingGoalShareCard.badgesKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'SHARE and streak lines appear only when there is something to brag about',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> pumpCard({int? share, int? streak}) async {
        await tester.pumpWidget(_app(WalkingGoalShareCard(
          steps: 8421,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _badges,
          shareToday: share,
          streakDays: streak,
        )));
        await tester.pump();
      }

      // Not confirmed by the server (null) or nothing mined (0): no SHARE line.
      await pumpCard();
      expect(find.byKey(WalkingGoalShareCard.shareKey), findsNothing);
      expect(find.byKey(WalkingGoalShareCard.streakKey), findsNothing);
      await pumpCard(share: 0, streak: 0);
      expect(find.byKey(WalkingGoalShareCard.shareKey), findsNothing);
      // One day is not a streak.
      await pumpCard(share: 320, streak: 1);
      expect(find.text('+320 SHARE'), findsOneWidget);
      expect(find.byKey(WalkingGoalShareCard.streakKey), findsNothing);
      await pumpCard(share: 320, streak: 7);
      expect(find.text('+320 SHARE'), findsOneWidget);
      expect(find.text('7일 연속'), findsOneWidget);
    });

    testWidgets('no animal given: no hero and no gap, the tagline stays',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(WalkingGoalShareCard(
        steps: 100,
        goalSteps: 6000,
        date: DateTime(2026, 11, 3),
      )));
      await tester.pump();
      expect(find.byKey(WalkingGoalShareCard.animalKey), findsNothing);
      expect(find.byKey(WalkingGoalShareCard.taglineKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a user with no tier yet gets the default snail, never donation wording that claims a payment',
        (tester) async {
      // walkingGoalBadges hands the snail asset to the card (see the helper).
      expect(_snail.hasAnimal, isTrue);
      expect(WalkingGoalShareCard.tagline, isNot(contains('기부 완료')));
      expect(WalkingGoalShareCard.tagline, contains('기부가 쌓여요'));
    });

    // Representative cards. Combinations: SHARE yes/no, streak 1/7 days,
    // tier yes/no (a snail user still gets the default character).
    goldenTest('golden 4:5 A - SHARE, 7-day streak, wolf and angel',
        (tester) async {
      await goldenCard(
        tester,
        file: 'walking_goal_card_a_share_streak7_tier.png',
        card: WalkingGoalShareCard(
          steps: 8421,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _badges,
          shareToday: 600,
          streakDays: 7,
        ),
      );
    });

    goldenTest('golden 4:5 B - no SHARE, 1-day streak, default snail',
        (tester) async {
      await goldenCard(
        tester,
        file: 'walking_goal_card_b_noshare_streak1_snail.png',
        card: WalkingGoalShareCard(
          steps: 6120,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _snail,
          streakDays: 1,
        ),
      );
    });

    goldenTest('golden 4:5 C - SHARE, 1-day streak, wolf', (tester) async {
      await goldenCard(
        tester,
        file: 'walking_goal_card_c_share_streak1_tier.png',
        card: WalkingGoalShareCard(
          steps: 10432,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: const RunFinishTierBadges(
            animalImage: 'assets/images/characters/tier_wolf.png',
            animalLabel: '늑대',
          ),
          shareToday: 600,
          streakDays: 1,
        ),
      );
    });

    goldenTest('golden 4:5 D - no SHARE, 7-day streak, wolf and angel',
        (tester) async {
      await goldenCard(
        tester,
        file: 'walking_goal_card_d_noshare_streak7_tier.png',
        card: WalkingGoalShareCard(
          steps: 12345,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _badges,
          streakDays: 7,
        ),
      );
    });

    goldenTest('golden 1:1 E - SHARE, 7-day streak, wolf and angel',
        (tester) async {
      await goldenCard(
        tester,
        file: 'walking_goal_card_e_square_share_streak7_tier.png',
        card: WalkingGoalShareCard(
          steps: 8421,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _badges,
          shareToday: 600,
          streakDays: 7,
          square: true,
        ),
      );
    });

    goldenTest('golden 1:1 F - nothing extra, default snail', (tester) async {
      await goldenCard(
        tester,
        file: 'walking_goal_card_f_square_plain_snail.png',
        card: WalkingGoalShareCard(
          steps: 6120,
          goalSteps: 6000,
          date: DateTime(2026, 11, 3),
          badges: _snail,
          square: true,
        ),
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
      expect(rules, contains(r"file.matches('[0-9]{8}\\.png')"));
      final firebaseJson = File('firebase.json').readAsStringSync();
      expect(firebaseJson, contains('"storage"'));
      expect(firebaseJson, contains('storage.rules'));
    });

    test('card path is one file per user per day', () {
      expect(
          WalkingChallengeShare.goalCardDay(DateTime(2026, 11, 3)), '20261103');
      expect(
          WalkingChallengeShare.goalCardDay(DateTime(2026, 1, 9)), '20260109');
    });
  });

  group('square card', () {
    testWidgets('keeps everything on screen without overflow, even at 6 digits',
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
        shareToday: 600,
        streakDays: 30,
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
      Future<String?> Function()? loadInviteCode,
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
          shareToday: 320,
          streakDays: 7,
          loadInviteCode: loadInviteCode,
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
      expect(
          sent!.text, WalkingChallengeShare.dailyGoalBragTextFor(steps: 8421));
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
      expect(
          sent!.text, WalkingChallengeShare.dailyGoalBragTextFor(steps: 8421));
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
      expect(
          sent!.text, WalkingChallengeShare.dailyGoalBragTextFor(steps: 8421));
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
      expect(WalkingChallengeShare.goalFeedButton, '나도 시작하기');
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

    testWidgets(
        'invite code: sheet text has the code line and the referrer link',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
      ShareParams? sent;
      WalkingChallengeShare.debugShareOverride = (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester, loadInviteCode: () async => 'abcd2345');
      await tapBrag(tester);

      expect(sent!.files, hasLength(1));
      expect(sent!.text, contains('초대 코드 ABCD2345'));
      expect(sent!.text, endsWith('$kPlayStoreUrl&referrer=invite%3DABCD2345'));
    });

    testWidgets('invite code lookup failing or hanging never blocks the share',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
      final sends = <ShareParams>[];
      WalkingChallengeShare.debugShareOverride = (params) async {
        sends.add(params);
        return const ShareResult('', ShareResultStatus.success);
      };

      await pumpDock(tester,
          loadInviteCode: () async => throw StateError('offline'));
      await tapBrag(tester);
      expect(sends.single.text, endsWith(kPlayStoreUrl));
      expect(sends.single.text, isNot(contains('referrer')));

      sends.clear();
      await pumpDock(
        tester,
        loadInviteCode: () => Completer<String?>().future, // never answers
      );
      await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
      await tester.pump();
      await tester.pump(
          WalkingChallengeShare.inviteCodeTimeout + const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 50));
      expect(sends.single.text, endsWith(kPlayStoreUrl));
    });

    testWidgets('Kakao feed button and card link carry the invite code',
        (tester) async {
      WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
      WalkingChallengeShare.debugUploadOverride =
          (file, uid, date) async => Uri.parse('https://example.com/c.png');
      Uri? link;
      WalkingChallengeShare.debugKakaoFeedLinkSink = (value) => link = value;
      // Let the real feed builder run up to the SDK call, which we stub by
      // throwing; the link is recorded before that.
      var fellBack = false;
      WalkingChallengeShare.debugKakaoShareOverride = (text) async {
        fellBack = true;
      };

      await pumpDock(tester, loadInviteCode: () async => 'ABCD2345');
      await chooseKakao(tester);

      expect(link.toString(), '$kPlayStoreUrl&referrer=invite%3DABCD2345');
      expect(fellBack, isTrue); // no Kakao SDK in tests: the text template ran
    });
  });
}
