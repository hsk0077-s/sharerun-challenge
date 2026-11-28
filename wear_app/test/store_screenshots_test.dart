import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/run_session.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/l10n/watch_copy.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

/// Play Wear OS 스크린샷. 실제 화면 위젯을 384×384로 그려 24-bit PNG로 저장한다.
const _shot = 384;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('NotoSansKR');
    for (final weight in [400, 500, 600, 700, 800, 900]) {
      final bytes = File('test/fonts/NotoSansKR-$weight.ttf').readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future<ByteData>.value(
          ByteData.sublistView(File('test/fonts/MaterialIcons-subset.otf').readAsBytesSync()),
        ),
      );
    await icons.load();
  });

  test('매니페스트에 둥근 아이콘과 단독 실행이 연결되어 있다', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    expect(manifest, contains('com.google.android.wearable.standalone'));
    expect(manifest, contains('android:value="true"'));
    expect(
      File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml').existsSync(),
      isTrue,
    );
    expect(
      File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml').existsSync(),
      isTrue,
    );
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final dir = 'android/app/src/main/res/mipmap-$density';
      expect(File('$dir/ic_launcher.png').existsSync(), isTrue, reason: density);
      expect(File('$dir/ic_launcher_foreground.png').existsSync(), isTrue, reason: density);
      expect(File('$dir/ic_launcher_round.png').existsSync(), isTrue, reason: density);
    }
  });

  test('스토어 문장은 기부 예정만 말하고 기부처 이름을 넣지 않는다', () {
    final listing = File('docs/store/listing.md').readAsStringSync();
    expect(listing, contains('기부 예정'));
    expect(listing, contains('To be donated.'));
    expect(listing, isNot(contains('스폰서')));
    expect(listing.toLowerCase(), isNot(contains('sponsor')));
    expect(listing.toLowerCase(), isNot(contains('nike')));
    expect(listing, contains('https://developer.android.com/docs/quality-guidelines/wear-app-quality'));
    expect(listing, contains('https://developer.android.com/training/wearables/packaging'));
    expect(listing, contains('https://developer.android.com/training/wearables/apps/standalone-apps'));
    expect(
      listing,
      contains('https://support.google.com/googleplay/android-developer/answer/9866151'),
    );
  });

  testWidgets('384 정사각 스크린샷을 실제 화면으로 그린다', (tester) async {
    tester.view.physicalSize = const Size(384, 384);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() async {
      for (final name in ['icon_tier_cheetah', 'icon_gps', 'icon_share']) {
        await precacheImage(AssetImage('assets/images/watch/$name.png'), context);
      }
    });

    for (final language in ['ko', 'en']) {
      final locale = Locale(language);
      tester.platformDispatcher.localeTestValue = locale;
      Directory('docs/store/screenshots/$language').createSync(recursive: true);
      final session = _sampleRun();
      final shots = _shots(locale, session);
      expect(shots, hasLength(5));
      for (final shot in shots) {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'NotoSansKR',
              brightness: Brightness.dark,
              scaffoldBackgroundColor: watchBg,
            ),
            home: RepaintBoundary(key: const Key('store-shot'), child: shot.face),
          ),
        );
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump();
        for (final text in shot.texts) {
          expect(find.text(text), findsOneWidget, reason: '$language ${shot.name} $text');
        }
        if (shot.name == '01_start') {
          expect(
            find.text(language == 'ko' ? 'Cheetah Gold' : '치타 골드'),
            findsNothing,
          );
        }
        if (shot.name == '04_route') {
          expect(find.byKey(RouteFace.paintKey), findsOneWidget);
        }
        // 다시 그릴 때: flutter test --update-goldens test/store_screenshots_test.dart
        // 골든 파일은 알파가 있으므로, 저장 뒤 24-bit RGB(알파 없음)로 덮어쓴다.
        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byKey(const Key('store-shot')),
            matchesGoldenFile('../docs/store/screenshots/$language/${shot.name}.png'),
          );
        } else {
          _expectPlayPng(File('docs/store/screenshots/$language/${shot.name}.png'));
        }
      }
    }
  });
}

class _Shot {
  const _Shot(this.name, this.face, this.texts);

  final String name;
  final Widget face;
  final List<String> texts;
}

List<_Shot> _shots(Locale locale, RunSession session) {
  final ko = locale.languageCode == 'ko';
  // 이름을 직접 넣지 않는다. 화면이 티어 코드를 그 언어로 바꿔야 한다.
  const tierCode = 'cheetah_gold';
  final tier = watchTierLabel(locale, tierCode)!;
  final running = RunningFace(
    session: session,
    now: DateTime(2026, 6, 1, 8, 17),
    tierCode: tierCode,
  );
  return [
    _Shot('01_start', StartFace(onStart: () {}, tierCode: tierCode), [
      'START',
      tier,
    ]),
    _Shot('02_countdown', CountdownFace(count: 3, onCancel: () {}), [
      '3',
      ko ? '눌러서 취소' : 'Tap to cancel',
    ]),
    _Shot('03_running', running, const ['08:17', '6.40', '36:48', '5:45']),
    _Shot('04_route', RouteFace(session: session), const []),
    _Shot('05_summary', SummaryFace(session: session, onDone: () {}), [
      ko ? '러닝 종료' : 'Run ended',
      '6.40',
      '36:48',
      '5:45',
      ko ? '자세한 건 폰에서 보기' : 'See details on phone',
      ko ? '확인' : 'OK',
    ]),
  ];
}

/// 샘플 한 건. 6.40km, 36분 48초 → 페이스 5:45. 경로는 만든 좌표다.
RunSession _sampleRun() {
  var now = DateTime.utc(2026, 6, 1, 7, 40);
  final session = RunSession(clock: () => now);
  session.start();
  now = now.add(const Duration(minutes: 36, seconds: 48));
  session.addDistance(6.4);
  session.replaceRoute(_sampleRoute());
  return session;
}

List<GpsFix> _sampleRoute() {
  const steps = 72;
  const lat0 = 37.521;
  const lon0 = 126.941;
  return [
    for (var i = 0; i <= steps; i++)
      GpsFix(
        latitude: lat0 +
            0.0036 * math.sin(2 * math.pi * i / steps) +
            0.00035 * math.sin(4 * math.pi * i / steps),
        longitude: lon0 +
            0.0048 * math.cos(2 * math.pi * i / steps) * (i == steps ? 0.72 : 1),
        recordedAt: DateTime.utc(2026, 6, 1, 7, 40, i).toIso8601String(),
      ),
  ];
}

void _expectPlayPng(File file) {
  final bytes = file.readAsBytesSync();
  expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  final width = _u32(bytes, 16);
  final height = _u32(bytes, 20);
  expect(width, _shot, reason: file.path);
  expect(height, _shot, reason: file.path);
  expect(bytes[24], 8, reason: 'bit depth');
  expect(bytes[25], 2, reason: 'RGB, no alpha');
}

int _u32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
