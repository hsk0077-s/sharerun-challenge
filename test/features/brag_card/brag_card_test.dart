import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/brag_card/brag_card_frame.dart';
import 'package:share_run_challenge/features/brag_card/brag_card_links.dart';
import 'package:share_run_challenge/features/brag_card/share_funnel_events.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/profile/widgets/my_page_invite_code_card.dart';
import 'package:share_run_challenge/features/run_result/run_finish_image_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_card.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_flow.dart';
import 'package:share_run_challenge/features/world_tour/screens/world_tour_arrival_screen.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_landmarks.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_run_end.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';
import 'package:share_run_challenge/screens/onboarding_run_result_screen.dart';

import '../world_tour/world_tour_support.dart';

/// One recording fake for the funnel. Each call is one line.
class _RecordingEvents implements ShareFunnelEvents {
  final calls = <String>[];

  @override
  void cardShown(BragSurface surface) =>
      calls.add('shown:${surface.wireName}');

  @override
  void shareTapped(BragSurface surface, String target) =>
      calls.add('tapped:${surface.wireName}:$target');

  @override
  void shareResult(
          BragSurface surface, String target, BragShareStatus status) =>
      calls.add('result:${surface.wireName}:$target:${status.wireName}');

  @override
  void qrIncluded(BragSurface surface, {required bool included}) =>
      calls.add('qr:${surface.wireName}:$included');
}

/// Words a brag card must never carry: other people, rankings, prizes, DIA
/// and invite rewards. Korean and English.
const _bannedWords = <String>[
  '친구', '크루', '순위', '랭킹', '추첨', '뽑기', '당첨', '상품', 'DIA', '초대',
  'friend', 'crew', 'rank', 'leaderboard', 'prize', 'lottery', 'invite',
  'reward',
];

final _boundaryKey = GlobalKey();

const _args = WorldTourArrivalArgs(
  missionId: 'wt-eiffel',
  landmarkId: 'eiffel_tower',
  distanceKm: 3.02,
  durationSeconds: 1450,
  stampId: 'stamp-france_eiffel',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final family in ['Pretendard', BragCardSpec.fontFamily]) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
        ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'))
        ..addFont(rootBundle.load('assets/fonts/Pretendard-Black.otf'));
      await loader.load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RunFinishImageShare.debugInstalledTargets = () async => const [];
    RunFinishImageShare.debugShareTarget = null;
    RunFinishImageShare.debugSystemShare = null;
    RunFinishImageShare.debugCaptureOverride = null;
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
  });

  tearDown(() {
    RemainingSurface.currentLocale = const Locale('ko', 'KR');
    RunFinishImageShare.debugInstalledTargets = null;
    RunFinishImageShare.debugSystemShare = null;
    RunFinishImageShare.debugCaptureOverride = null;
  });

  group('install address', () {
    test('is the Play listing plus a fixed campaign label, nothing personal',
        () {
      final uri = Uri.parse(bragCardInstallUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, 'play.google.com');
      expect(uri.path, '/store/apps/details');
      expect(uri.queryParameters.keys.toSet(), {'id', 'referrer'});
      expect(uri.queryParameters['id'], 'com.sharerun.share_run_challenge');
      expect(
        uri.queryParameters['referrer'],
        'utm_source=sharerun_card&utm_medium=qr&utm_campaign=brag_card_v1',
      );
      expect(
        bragCardInstallUrl,
        'https://play.google.com/store/apps/details'
        '?id=com.sharerun.share_run_challenge'
        '&referrer=utm_source%3Dsharerun_card%26utm_medium%3Dqr'
        '%26utm_campaign%3Dbrag_card_v1',
      );
    });

    test('uses the same package id as the My Page invite address', () {
      expect(myPageInvitePlayStoreUrl, sharerunPlayStoreUrl);
      expect(bragCardInstallUrl, startsWith(myPageInvitePlayStoreUrl));
    });
  });

  group('run finish card', () {
    testWidgets('carries the QR with exactly the install address',
        (tester) async {
      await _pumpRunCard(tester, _runCard());

      expect(find.byKey(BragCardSpec.qrKey), findsOneWidget);
      await _expectQrPixelsEncode(tester, bragCardInstallUrl);
      expect(find.text(BragCardSpec.scanLine), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('QR off removes the QR and keeps a plain line',
        (tester) async {
      await _pumpRunCard(tester, _runCard(showQr: false));

      expect(find.byKey(BragCardSpec.qrKey), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text(BragCardSpec.scanLine), findsNothing);
      expect(find.text(BragCardSpec.plainLine), findsOneWidget);
      // The rest of the card is untouched.
      expect(find.byKey(RunFinishShareCard.distanceKey), findsOneWidget);
      expect(find.byKey(RunFinishShareCard.logoKey), findsOneWidget);
      expect(find.byKey(RunFinishShareCard.appNameKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('has no friend, crew, ranking, prize, DIA or invite text',
        (tester) async {
      await _pumpRunCard(tester, _runCard());
      _expectNoBannedWords(tester);
      expect(find.byKey(BragCardSpec.qrKey), findsOneWidget);
    });

    testWidgets('name, QR and record stay inside the 280px safe bands',
        (tester) async {
      await _pumpRunCard(tester, _runCard());
      _expectInsideSafeBands(tester, [
        RunFinishShareCard.appNameKey,
        RunFinishShareCard.logoKey,
        BragCardSpec.qrKey,
        BragCardSpec.footerLineKey,
        RunFinishShareCard.distanceKey,
        RunFinishShareCard.donationKey,
      ]);
    });

    for (final code in const [
      'en', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'vi', 'th', 'id',
    ]) {
      testWidgets('lays out without overflow in $code with every part on',
          (tester) async {
        RemainingSurface.currentLocale = Locale(code);
        await _pumpRunCard(tester, _runCard());
        expect(tester.takeException(), isNull);
        _expectInsideSafeBands(tester, [
          RunFinishShareCard.appNameKey,
          BragCardSpec.qrKey,
          BragCardSpec.footerLineKey,
          RunFinishShareCard.distanceKey,
        ]);
        // The footer line must fit in its box, not run past three lines.
        final line = tester.getSize(find.byKey(BragCardSpec.footerLineKey));
        expect(line.height, lessThanOrEqualTo(38 * 1.3 * 3 + 1));
      });
    }
  });

  group('world tour card', () {
    testWidgets('always carries the QR with the install address',
        (tester) async {
      await _pumpPoster(tester);

      expect(find.byKey(BragCardSpec.qrKey), findsOneWidget);
      await _expectQrPixelsEncode(tester, bragCardInstallUrl);
      expect(find.text('에펠탑 도착!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('has no friend, crew, ranking, prize, DIA or invite text',
        (tester) async {
      await _pumpPoster(tester);
      _expectNoBannedWords(tester);
    });

    testWidgets('name, QR and arrival text stay inside the safe bands',
        (tester) async {
      await _pumpPoster(tester);
      _expectInsideSafeBands(tester, [
        BragCardSpec.appNameKey,
        BragCardSpec.qrKey,
        BragCardSpec.footerLineKey,
      ]);
      final poster = tester.getRect(find.byType(WorldTourArrivalPoster));
      expect(poster.size, const Size(1080, 1920));
    });

    for (final code in const ['en', 'de', 'th', 'vi']) {
      testWidgets('lays out without overflow in $code', (tester) async {
        RemainingSurface.currentLocale = Locale(code);
        await _pumpPoster(tester, locale: Locale(code));
        expect(tester.takeException(), isNull);
        _expectInsideSafeBands(tester, [
          BragCardSpec.appNameKey,
          BragCardSpec.qrKey,
          BragCardSpec.footerLineKey,
        ]);
      });
    }
  });

  group('funnel events', () {
    testWidgets('run finish: shown, qr, tapped, result in that order',
        (tester) async {
      final events = _RecordingEvents();
      _stubShare(
        onSystemShare: (_) async =>
            const ShareResult('ok', ShareResultStatus.success),
      );
      await _pumpFinish(tester, events);
      expect(events.calls, ['shown:run_finish']);

      await _shareToMore(tester);

      expect(events.calls, [
        'shown:run_finish',
        'qr:run_finish:true',
        'tapped:run_finish:more',
        'result:run_finish:more:success',
      ]);
    });

    testWidgets('QR switch off is reported as included false and survives',
        (tester) async {
      final events = _RecordingEvents();
      _stubShare(
        onSystemShare: (_) async =>
            const ShareResult('', ShareResultStatus.dismissed),
      );
      await _pumpFinish(tester, events);

      expect(find.byKey(OnboardingRunResultScreen.qrSwitchKey), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(OnboardingRunResultScreen.qrSwitchKey))
            .value,
        isTrue,
        reason: 'QR is on by default',
      );
      await tester.ensureVisible(find.byKey(OnboardingRunResultScreen.qrSwitchKey));
      await tester.tap(find.byKey(OnboardingRunResultScreen.qrSwitchKey));
      await tester.pump();

      await _shareToMore(tester);

      expect(events.calls, [
        'shown:run_finish',
        'qr:run_finish:false',
        'tapped:run_finish:more',
        'result:run_finish:more:dismissed',
      ]);
      // The preview card (and the hidden export card) have no QR now.
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('a share sheet that throws is reported as failed',
        (tester) async {
      final events = _RecordingEvents();
      _stubShare(onSystemShare: (_) async => throw StateError('boom'));
      await _pumpFinish(tester, events);

      await _shareToMore(tester);

      expect(events.calls.last, 'result:run_finish:more:failed');
    });

    testWidgets('world tour: shown, qr, tapped, result in that order',
        (tester) async {
      final events = _RecordingEvents();
      _stubShare(
        onSystemShare: (_) async =>
            const ShareResult('ok', ShareResultStatus.unavailable),
      );
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        tourApp(
          home: const WorldTourArrivalScreen(args: _args),
          api: FakeWorldTourApi(me: meJson(done: {'wt-eiffel'})),
          overrides: [shareFunnelEventsProvider.overrideWithValue(events)],
        ),
      );
      await tester.pumpAndSettle();
      expect(events.calls, ['shown:world_tour']);

      await tester.tap(find.byKey(WorldTourArrivalScreen.shareKey));
      await tester.pumpAndSettle();

      expect(events.calls, [
        'shown:world_tour',
        'qr:world_tour:true',
        'tapped:world_tour:system_sheet',
        'result:world_tour:system_sheet:unavailable',
      ]);
    });

    test('the default sender sends nothing and keeps nothing', () {
      const events = NoopShareFunnelEvents();
      // Must not throw and has no state to inspect.
      events.cardShown(BragSurface.runFinish);
      events.qrIncluded(BragSurface.worldTour, included: false);
      events.shareTapped(BragSurface.runFinish, 'more');
      events.shareResult(
          BragSurface.runFinish, 'more', BragShareStatus.success);
    });

    test('share_plus statuses map to the four wire names', () {
      expect(
        {
          for (final s in ShareResultStatus.values)
            BragShareStatus.fromShareResult(s).wireName,
        },
        {'success', 'dismissed', 'unavailable'},
      );
      expect(BragShareStatus.failed.wireName, 'failed');
    });
  });
}

// --- helpers ---------------------------------------------------------------

RunFinishShareCard _runCard({bool showQr = true}) {
  return RunFinishShareCard(
    style: RunFinishCardTheme.dark,
    distanceKm: '12.34',
    time: '1:05:30',
    pace: '5:18 /km',
    date: DateTime(2026, 10, 3),
    donationWon: 3200,
    splitPaces: const [320, 315, 310, 305, 300, 312, 318, 322],
    averageHeartRate: 152,
    route: const [Offset(0.2, 0.3), Offset(0.5, 0.2), Offset(0.8, 0.4)],
    badges: const RunFinishTierBadges(
      animalImage: 'assets/images/tier/none.png',
      animalLabel: 'Cheetah',
      angelImage: 'assets/images/tier/none.png',
      angelLabel: 'Angel',
    ),
    showQr: showQr,
  );
}

Future<void> _pumpRunCard(WidgetTester tester, RunFinishShareCard card) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: Center(child: RepaintBoundary(key: _boundaryKey, child: card)),
    ),
  );
  await tester.pump();
}

Future<void> _pumpPoster(WidgetTester tester,
    {Locale locale = const Locale('ko', 'KR')}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    tourApp(
      locale: locale,
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: WorldTourArrivalPoster(
              landmark: WorldTourLandmark.of('eiffel_tower'),
              args: _args,
              avatar: const SizedBox(width: 240, height: 240),
            ),
          ),
        ),
      ),
      api: FakeWorldTourApi(me: meJson(done: {'wt-eiffel'})),
    ),
  );
  await tester.pump();
}

Future<void> _pumpFinish(WidgetTester tester, ShareFunnelEvents events) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [shareFunnelEventsProvider.overrideWithValue(events)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SrcTheme.light,
        home: const OnboardingRunResultScreen(serverConfirmed: true),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _stubShare({required Future<ShareResult> Function(ShareParams) onSystemShare}) {
  RunFinishImageShare.debugCaptureOverride = (_) async {
    final file = File('${Directory.systemTemp.path}/share_run_brag_test.png');
    file.writeAsBytesSync(const [1, 2, 3]);
    return file;
  };
  RunFinishImageShare.debugSystemShare = onSystemShare;
}

/// Card share → "one app" → "more" (the system sheet).
Future<void> _shareToMore(WidgetTester tester) async {
  await tester.tap(find.byKey(runFinishCardShareKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(runFinishModeOneKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('run-finish-target-more')));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _expectNoBannedWords(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase())
      .where((t) => t.isNotEmpty)
      .toList();
  expect(texts, isNotEmpty);
  for (final text in texts) {
    for (final word in _bannedWords) {
      expect(text.contains(word.toLowerCase()), isFalse,
          reason: '"$text" contains banned word "$word"');
    }
  }
}

void _expectInsideSafeBands(WidgetTester tester, List<Key> keys) {
  const top = BragCardSpec.storySafeInset;
  const bottom = BragCardSpec.canvasHeight - BragCardSpec.storySafeInset;
  final canvas = tester.getRect(find.byWidgetPredicate(
    (w) => w is SizedBox && w.width == 1080 && w.height == 1920,
  ).first);
  for (final key in keys) {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: '$key');
    final rect = tester.getRect(finder).shift(-canvas.topLeft);
    expect(rect.top, greaterThanOrEqualTo(top - 0.5), reason: '$key top');
    expect(rect.bottom, lessThanOrEqualTo(bottom + 0.5),
        reason: '$key bottom');
    expect(rect.left, greaterThanOrEqualTo(0), reason: '$key left');
    expect(rect.right, lessThanOrEqualTo(1080), reason: '$key right');
  }
}

/// Reads the painted pixels of the QR and checks every module against the
/// QR that [expected] must produce. If this passes, a scanner reads [expected].
Future<void> _expectQrPixelsEncode(WidgetTester tester, String expected) async {
  final qr = QrValidator.validate(
    data: expected,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.L,
  ).qrCode!;
  final image = QrImage(qr);
  final modules = qr.moduleCount;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundaryKey));
  final origin = boundary.localToGlobal(Offset.zero);
  final local = tester.getRect(find.byType(QrImageView)).shift(-origin);
  final shot = await tester.runAsync(() async {
    final image = boundary.toImageSync(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (width, bytes!);
  });
  final (width, bytes) = shot!;
  final cell = local.width / modules;
  var wrong = 0;
  for (var row = 0; row < modules; row++) {
    for (var col = 0; col < modules; col++) {
      final x = (local.left + (col + 0.5) * cell).floor();
      final y = (local.top + (row + 0.5) * cell).floor();
      final dark = bytes.getUint8((y * width + x) * 4) < 128;
      if (dark != image.isDark(row, col)) wrong++;
    }
  }
  expect(wrong, 0, reason: '$wrong of ${modules * modules} modules differ');
}
