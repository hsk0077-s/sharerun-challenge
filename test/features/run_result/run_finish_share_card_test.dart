import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/widgets/src_logo_header.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_image_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_card.dart';
import 'package:share_run_challenge/features/run_result/run_finish_theme_store.dart';
import 'package:share_run_challenge/screens/onboarding_run_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader(RunFinishShareCard.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Black.otf'));
    await loader.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RunFinishImageShare.debugInstagramInstalled = null;
    RunFinishImageShare.debugTikTokInstalled = null;
    RunFinishImageShare.debugInstagramShare = null;
    RunFinishImageShare.debugTikTokShare = null;
    RunFinishImageShare.debugSystemShare = null;
    RunFinishImageShare.debugCaptureOverride = null;
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
    WalkingChallengeShare.debugShareOverride = null;
  });

  tearDown(() {
    RunFinishImageShare.debugInstagramInstalled = null;
    RunFinishImageShare.debugTikTokInstalled = null;
    RunFinishImageShare.debugInstagramShare = null;
    RunFinishImageShare.debugTikTokShare = null;
    RunFinishImageShare.debugSystemShare = null;
    RunFinishImageShare.debugCaptureOverride = null;
  });

  test('donation line is omitted when this run has no won amount', () {
    expect(runFinishDonationLine(null), isNull);
    expect(runFinishDonationLine(0), isNull);
    expect(
      runFinishDonationLine(3200),
      '이 달리기로 3,200원 기부에 함께했어요',
    );
  });

  testWidgets('poster shows the run, date, and logo — not an invite code',
      (tester) async {
    await _pumpCard(
      tester,
      RunFinishShareCard(
        style: RunFinishCardTheme.dark,
        distanceKm: '8.35',
        time: '52:14',
        pace: '6:15 /KM',
        date: DateTime(2026, 10, 3),
      ),
    );

    expect(find.text('8.35'), findsOneWidget);
    expect(find.text('52:14'), findsOneWidget);
    expect(find.text('6:15'), findsOneWidget);
    expect(find.text('10월 3일 토요일'), findsOneWidget);
    expect(find.text(RunFinishShareCard.headline), findsOneWidget);
    expect(find.text('km'), findsOneWidget);
    expect(find.text(RunFinishShareCard.appName), findsOneWidget);
    expect(find.byKey(RunFinishShareCard.logoKey), findsOneWidget);
    expect(find.byKey(RunFinishShareCard.donationKey), findsNothing);
    expect(find.textContaining('초대'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('donation line appears only when a won amount is passed',
      (tester) async {
    await _pumpCard(
      tester,
      RunFinishShareCard(
        style: RunFinishCardTheme.pink,
        distanceKm: '8.35',
        time: '52:14',
        pace: '6:15 /KM',
        date: DateTime(2026, 10, 3),
        donationWon: 3200,
        route: _exampleRoute,
      ),
    );

    expect(find.text('이 달리기로 3,200원 기부에 함께했어요'), findsOneWidget);
    expect(find.textContaining('초대'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('yellow theme lays out without overflow', (tester) async {
    await _pumpCard(
      tester,
      RunFinishShareCard(
        style: RunFinishCardTheme.yellow,
        distanceKm: '8.35',
        time: '52:14',
        pace: '6:15 /KM',
        date: DateTime(2026, 10, 3),
        donationWon: 3200,
        route: _exampleRoute,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('finish screen hides store buttons until the app is installed',
      (tester) async {
    RunFinishImageShare.debugInstagramInstalled = () async => false;
    RunFinishImageShare.debugTikTokInstalled = () async => false;
    await _pumpFinish(tester);

    expect(find.text(AppStrings.runResultShare), findsOneWidget);
    expect(find.text(RunFinishImageShare.moreLabel), findsOneWidget);
    expect(find.text(RunFinishImageShare.instagramLabel), findsNothing);
    expect(find.text(RunFinishImageShare.tiktokLabel), findsNothing);
    expect(find.textContaining('초대'), findsNothing);
  });

  testWidgets('finish screen shows Instagram and TikTok when installed',
      (tester) async {
    RunFinishImageShare.debugInstagramInstalled = () async => true;
    RunFinishImageShare.debugTikTokInstalled = () async => true;
    await _pumpFinish(tester);
    await tester.pump();

    expect(find.text(RunFinishImageShare.instagramLabel), findsOneWidget);
    expect(find.text(RunFinishImageShare.tiktokLabel), findsOneWidget);
    expect(find.text(RunFinishImageShare.moreLabel), findsOneWidget);
  });

  testWidgets('swipe selects the next poster style', (tester) async {
    await _pumpFinish(tester);
    await tester.pump();
    expect(find.text('다크'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('run-finish-theme-pink')));
    await tester.tap(find.byKey(const Key('run-finish-theme-pink')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('핑크'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RunFinishThemeStore.prefsKey), 'pink');
  });

  testWidgets('opens on the theme saved on the phone', (tester) async {
    SharedPreferences.setMockInitialValues({
      RunFinishThemeStore.prefsKey: 'yellow',
    });
    await _pumpFinish(tester);
    await tester.pump();

    expect(find.text('옐로'), findsOneWidget);
    expect(find.text('다크'), findsNothing);
  });

  testWidgets('더보기 shares the png and no invite text', (tester) async {
    ShareParams? sent;
    RunFinishImageShare.debugSystemShare = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    RunFinishImageShare.debugCaptureOverride = (_) async {
      final file = File(
        '${Directory.systemTemp.path}/share_run_finish_test.png',
      );
      file.writeAsBytesSync(const [137, 80, 78, 71]);
      return file;
    };
    await _pumpFinish(tester);

    await tester.tap(find.byKey(RunFinishImageShare.moreButtonKey));
    await tester.pump();
    await tester.pump();

    expect(sent, isNotNull);
    expect(sent!.text, isNull);
    expect(sent!.files, isNotNull);
    expect(sent!.files!.single.path, endsWith('.png'));
    expect(sent!.subject, RunFinishImageShare.subject);
    final joined = '${sent!.text ?? ''} ${sent!.subject ?? ''}';
    expect(joined.contains('초대'), isFalse);
  });

  testWidgets('TikTok falls back to the image sheet when it cannot be targeted',
      (tester) async {
    ShareParams? sent;
    String? tiktokPath;
    RunFinishImageShare.debugInstagramInstalled = () async => false;
    RunFinishImageShare.debugTikTokInstalled = () async => true;
    RunFinishImageShare.debugTikTokShare = (path) async {
      tiktokPath = path;
      return false;
    };
    RunFinishImageShare.debugSystemShare = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    RunFinishImageShare.debugCaptureOverride = (_) async {
      final file = File('${Directory.systemTemp.path}/share_run_tt.png');
      file.writeAsBytesSync(const [1, 2, 3]);
      return file;
    };
    await _pumpFinish(tester);
    await tester.pump();

    await tester.tap(find.byKey(RunFinishImageShare.tiktokButtonKey));
    await tester.pump();
    await tester.pump();

    expect(tiktokPath, endsWith('.png'));
    expect(sent, isNotNull);
    expect(sent!.text, isNull);
    expect(sent!.files, isNotNull);
  });

  testWidgets('Instagram story receives the png path', (tester) async {
    String? instagramPath;
    ShareParams? sent;
    RunFinishImageShare.debugInstagramInstalled = () async => true;
    RunFinishImageShare.debugTikTokInstalled = () async => false;
    RunFinishImageShare.debugInstagramShare = (path) async {
      instagramPath = path;
      return true;
    };
    RunFinishImageShare.debugSystemShare = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    RunFinishImageShare.debugCaptureOverride = (_) async {
      final file = File('${Directory.systemTemp.path}/share_run_ig.png');
      file.writeAsBytesSync(const [1, 2, 3]);
      return file;
    };
    await _pumpFinish(tester);
    await tester.pump();

    await tester.tap(find.byKey(RunFinishImageShare.instagramButtonKey));
    await tester.pump();
    await tester.pump();

    expect(instagramPath, endsWith('.png'));
    expect(sent, isNull);
  });

  testWidgets('offscreen poster is story size and can be captured', (tester) async {
    await _pumpFinish(tester);
    final posters = tester
        .renderObjectList<RenderRepaintBoundary>(find.byType(RepaintBoundary))
        .where((boundary) => boundary.size == const Size(1080, 1920));
    expect(posters, isNotEmpty);
    final image = posters.first.toImageSync();
    expect(image.width, 1080);
    expect(image.height, 1920);
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    image.dispose();
    expect(bytes, isNotNull);
    expect(bytes!.lengthInBytes, greaterThan(8));
  });

  testWidgets('Hangul renders as an outline, not a box', (tester) async {
    final ratio = await _inkFillRatio(
      tester,
      const Text(
        '런',
        style: TextStyle(
          fontFamily: RunFinishShareCard.fontFamily,
          fontSize: 140,
          fontWeight: FontWeight.w900,
          color: Color(0xFF111111),
        ),
      ),
    );
    expect(ratio, greaterThan(0.04));
    expect(ratio, lessThan(0.72), reason: 'glyph looks like a solid box');
  });

  testWidgets('logo asset paints into the poster', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Image.asset(SRCLogoHeader.assetPath, width: 96, height: 96),
      ),
    );
    await tester.pump();
    final context = tester.element(find.byType(Image));
    await tester.runAsync(
      () => precacheImage(const AssetImage(SRCLogoHeader.assetPath), context),
    );
    await tester.pump();
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = boundary.toImageSync();
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final width = image.width;
    final height = image.height;
    image.dispose();
    expect(bytes, isNotNull);
    var green = 0;
    final data = bytes!;
    for (var i = 0; i < width * height; i++) {
      final r = data.getUint8(i * 4);
      final g = data.getUint8(i * 4 + 1);
      final b = data.getUint8(i * 4 + 2);
      if (g > 90 && g > r + 25 && g > b + 10) green++;
    }
    expect(green, greaterThan(40));
  });

  testWidgets('example poster lays out with the donation badge', (tester) async {
    await _pumpCard(tester, _exampleCard(RunFinishCardTheme.mint));
    expect(find.text('5.24'), findsOneWidget);
    expect(find.text('28:15'), findsOneWidget);
    expect(find.text("5'23\""), findsOneWidget);
    expect(find.text('/km'), findsOneWidget);
    expect(find.text('이 달리기로 3,200원 기부에 함께했어요'), findsOneWidget);
    expect(find.text(RunFinishShareCard.headline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captured poster is 1080x1920 png', (tester) async {
    final file = await _renderPoster(tester, _exampleCard(RunFinishCardTheme.dark));
    _expectPngSize(file, 1080, 1920);

    if (Platform.environment['SHARE_CARD_SAMPLES'] == '1') {
      final out = Directory('/opt/cursor/artifacts/share-card');
      out.createSync(recursive: true);
      for (final theme in RunFinishCardTheme.values) {
        final rendered = await _renderPoster(tester, _exampleCard(theme));
        _expectPngSize(rendered, 1080, 1920);
        rendered.copySync('${out.path}/theme-${theme.name}.png');
      }
    }
  });
}

RunFinishShareCard _exampleCard(RunFinishCardTheme theme) {
  return RunFinishShareCard(
    style: theme,
    distanceKm: '5.24',
    time: '28:15',
    pace: "5'23\"/km",
    date: _sampleDate,
    donationWon: 3200,
  );
}

final _sampleDate = DateTime(2026, 10, 3);

const _exampleRoute = <Offset>[
  Offset(0.16, 0.22),
  Offset(0.24, 0.16),
  Offset(0.36, 0.14),
  Offset(0.50, 0.18),
  Offset(0.64, 0.13),
  Offset(0.76, 0.20),
  Offset(0.82, 0.30),
  Offset(0.74, 0.36),
  Offset(0.58, 0.34),
  Offset(0.42, 0.40),
  Offset(0.28, 0.34),
  Offset(0.18, 0.28),
];

Future<void> _pumpCard(WidgetTester tester, RunFinishShareCard card) async {
  tester.view.physicalSize = const Size(
    RunFinishShareCard.canvasWidth,
    RunFinishShareCard.canvasHeight,
  );
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: Center(child: card),
    ),
  );
  await tester.pump();
}

Future<void> _pumpFinish(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SrcTheme.light,
        home: const OnboardingRunResultScreen(),
      ),
    ),
  );
  await tester.pump();
}

Future<File> _renderPoster(WidgetTester tester, RunFinishShareCard card) async {
  final key = GlobalKey();
  tester.view.physicalSize = const Size(
    RunFinishShareCard.canvasWidth,
    RunFinishShareCard.canvasHeight,
  );
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(key: key, child: card),
    ),
  );
  await tester.pump();
  final context = tester.element(find.byType(RunFinishShareCard));
  await tester.runAsync(
    () => precacheImage(const AssetImage(SRCLogoHeader.assetPath), context),
  );
  await tester.pump();
  // toImageSync deadlocks inside runAsync (it waits on the raster thread
  // while the test binding holds the UI isolate). Rasterize here, encode there.
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = boundary.toImageSync();
  final raw = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  final width = image.width;
  final height = image.height;
  image.dispose();
  expect(bytes, isNotNull);
  expect(raw, isNotNull);
  final file = File(
    '${Directory.systemTemp.path}/share_run_finish_${card.style.name}.png',
  );
  file.writeAsBytesSync(
    bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
  _expectNoOverflowStripe(raw!, width, height);
  return file;
}

Future<double> _inkFillRatio(WidgetTester tester, Widget child) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: SizedBox(width: 240, height: 240, child: Center(child: child)),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = boundary.toImageSync();
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final width = image.width;
  final height = image.height;
  image.dispose();
  final data = bytes!;
  var minX = width;
  var minY = height;
  var maxX = 0;
  var maxY = 0;
  var ink = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      if (r < 245 || g < 245 || b < 245) {
        ink++;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (ink == 0) return 0;
  final area = (maxX - minX + 1) * (maxY - minY + 1);
  return ink / area;
}

void _expectNoOverflowStripe(ByteData data, int width, int height) {
  var worst = 0;
  var worstY = -1;
  for (var y = 0; y < height; y++) {
    var yellow = 0;
    for (var x = 0; x < width; x += 4) {
      final i = (y * width + x) * 4;
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      if (r > 250 && g > 250 && b < 16) yellow++;
    }
    if (yellow > worst) {
      worst = yellow;
      worstY = y;
    }
  }
  expect(worst, lessThan(12), reason: 'overflow stripe at y=$worstY');
}

void _expectPngSize(File file, int width, int height) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(bytes.length, greaterThan(24));
  expect(data.getUint32(16), width);
  expect(data.getUint32(20), height);
}
