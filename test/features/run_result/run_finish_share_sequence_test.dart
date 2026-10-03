import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_image_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_card.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_flow.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_targets.dart';
import 'package:share_run_challenge/screens/onboarding_run_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final family in ['Pretendard', RunFinishShareCard.fontFamily]) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
        ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'))
        ..addFont(rootBundle.load('assets/fonts/Pretendard-Black.otf'));
      await loader.load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RunFinishImageShare.debugInstalledTargets = null;
    RunFinishImageShare.debugShareTarget = null;
    RunFinishImageShare.debugSystemShare = null;
    RunFinishImageShare.debugCaptureOverride = null;
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
    OnboardingRunResultScreen.debugPickPhoto = null;
  });

  test('saved order stays in front of the other installed apps', () {
    final targets = orderedShareTargets(
      installedIds: const ['tiktok', 'story', 'line'],
      savedOrder: const ['line', 'story', 'missing'],
    );
    expect(
      targets.map((target) => target.id).toList(),
      ['line', 'story', 'tiktok', 'more'],
    );
    expect(
      moveShareItem(targets, 0, 2).map((target) => target.id).toList(),
      ['story', 'line', 'tiktok', 'more'],
    );
  });

  testWidgets('last share mode is pre-selected', (tester) async {
    SharedPreferences.setMockInitialValues({
      RunFinishSharePrefs.modeKey: RunFinishShareMode.sequence.name,
    });
    RunFinishImageShare.debugInstalledTargets = () async => const [];
    await _pumpFinish(tester);

    await tester.tap(find.byKey(runFinishCardShareKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.descendant(
        of: find.byKey(runFinishModeManyKey),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(runFinishModeOneKey),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
  });

  testWidgets('sequence opens the first app, then the next after resume',
      (tester) async {
    final opened = <String>[];
    RunFinishImageShare.debugInstalledTargets = () async => const [
          'story',
          'tiktok',
          'facebook',
        ];
    RunFinishImageShare.debugShareTarget = (id, path) async {
      opened.add(id);
      return true;
    };
    RunFinishImageShare.debugCaptureOverride = (_) async {
      final file = File('${Directory.systemTemp.path}/share_run_seq.png');
      file.writeAsBytesSync(const [1, 2, 3]);
      return file;
    };
    await _pumpFinish(tester);

    await tester.tap(find.byKey(runFinishCardShareKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(runFinishModeManyKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('story')));
    await tester.tap(find.byKey(const ValueKey('tiktok')));
    await tester.tap(find.byKey(const ValueKey('facebook')));
    await tester.pump();
    await tester.tap(find.byKey(runFinishSequenceGoKey));
    await tester.pump();
    await tester.pump();

    expect(opened, ['story']);
    expect(find.text('다음: TikTok'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('다음: TikTok'), findsOneWidget);

    await tester.tap(find.byKey(runFinishSkipKey));
    await tester.pump();
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('다음: Facebook'), findsOneWidget);
    expect(opened, ['story']);

    await tester.tap(find.byKey(runFinishNextKey));
    await tester.pump();
    expect(opened, ['story', 'facebook']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('다음: Facebook'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getString(RunFinishSharePrefs.orderKey), 'story,tiktok,facebook');
    expect(prefs.getString(RunFinishSharePrefs.modeKey), 'sequence');
  });

  testWidgets('stop ends the sequence', (tester) async {
    RunFinishImageShare.debugInstalledTargets =
        () async => const ['story', 'tiktok'];
    RunFinishImageShare.debugShareTarget = (id, path) async => true;
    RunFinishImageShare.debugCaptureOverride = (_) async {
      final file = File('${Directory.systemTemp.path}/share_run_stop.png');
      file.writeAsBytesSync(const [1]);
      return file;
    };
    await _pumpFinish(tester);
    await tester.tap(find.byKey(runFinishCardShareKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(runFinishModeManyKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('story')));
    await tester.tap(find.byKey(const ValueKey('tiktok')));
    await tester.pump();
    await tester.tap(find.byKey(runFinishSequenceGoKey));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('다음: TikTok'), findsOneWidget);
    await tester.tap(find.byKey(runFinishStopKey));
    await tester.pump();
    expect(find.text('다음: TikTok'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sample picker and progress', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _sampleApp(home: const Scaffold(body: SizedBox.expand())),
    );
    final modeContext = tester.element(find.byType(Scaffold));
    final modeSheet = showRunFinishShareMode(
      modeContext,
      RunFinishShareMode.sequence,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(runFinishModeOneLabel), findsOneWidget);
    expect(find.text(runFinishModeManyLabel), findsOneWidget);
    expect(tester.takeException(), isNull);

    final pickerKey = GlobalKey();
    final bannerKey = GlobalKey();
    if (Platform.environment['SHARE_CARD_SAMPLES'] == '1') {
      final out = Directory('/opt/cursor/artifacts/share-card');
      out.createSync(recursive: true);
      await _writeOverlayPng(tester, '${out.path}/sequential-mode.png');
    }

    await tester.pumpWidget(
      _sampleApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF4F6F5),
          body: RepaintBoundary(
            key: pickerKey,
            child: Material(
              color: const Color(0xFFF4F6F5),
              child: RunFinishSequencePicker(
                targets: RunFinishShareTarget.catalog,
                initiallyChecked: const {
                  'story',
                  'tiktok',
                  'facebook',
                  'kakao',
                  'line',
                },
                onShare: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(runFinishSequenceGoLabel), findsOneWidget);
    if (Platform.environment['SHARE_CARD_SAMPLES'] == '1') {
      await _writePng(
        tester,
        pickerKey,
        '/opt/cursor/artifacts/share-card/sequential-picker.png',
      );
    }

    await tester.pumpWidget(
      _sampleApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF4F6F5),
          body: RepaintBoundary(
            key: bannerKey,
            child: const ColoredBox(
              color: Color(0xFFF4F6F5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: RunFinishSequenceBanner(
                      label: 'TikTok',
                      progress: '2/5',
                      onNext: _noop,
                      onSkip: _noop,
                      onStop: _noop,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('다음: TikTok'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    expect(tester.takeException(), isNull);

    if (Platform.environment['SHARE_CARD_SAMPLES'] == '1') {
      await _writePng(
        tester,
        bannerKey,
        '/opt/cursor/artifacts/share-card/sequential-progress.png',
      );
    }
    modeSheet.ignore();
  });
}

Widget _sampleApp({required Widget home}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: SrcTheme.light,
    home: home,
  );
}

void _noop() {}

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

Future<void> _writeOverlayPng(WidgetTester tester, String path) async {
  RenderObject? node = tester.renderObject(find.text('어떻게 올릴까요?'));
  RenderRepaintBoundary? boundary;
  while (node != null) {
    if (node is RenderRepaintBoundary &&
        node.size.width >= 300 &&
        node.size.height >= 180 &&
        node.size.height <= 520) {
      boundary = node;
      break;
    }
    node = node.parent;
  }
  node = tester.renderObject(find.text('어떻게 올릴까요?'));
  if (boundary == null) {
    while (node != null) {
      if (node is RenderRepaintBoundary && node.size.width >= 300) {
        boundary = node;
      }
      node = node.parent;
    }
  }
  expect(boundary, isNotNull);
  await _writeBoundary(tester, boundary!, path, cropSheet: true);
}

Future<void> _writePng(WidgetTester tester, GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await _writeBoundary(tester, boundary, path);
}

Future<void> _writeBoundary(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  String path, {
  bool cropSheet = false,
}) async {
  var image = boundary.toImageSync(pixelRatio: 2);
  if (cropSheet && image.height > 1000) {
    image = await _cropBottomSheet(tester, image);
  }
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  image.dispose();
  File(path).writeAsBytesSync(
    bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
}

/// Drops the dimmed page above a modal sheet. Picker and progress captures
/// stay full height.
Future<ui.Image> _cropBottomSheet(WidgetTester tester, ui.Image image) async {
  final raw = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final bytes = raw!.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
  final width = image.width;
  final height = image.height;
  var top = 0;
  for (var y = 0; y < height; y++) {
    var light = 0;
    var samples = 0;
    for (var x = 0; x < width; x += 4) {
      final i = (y * width + x) * 4;
      samples++;
      if (bytes[i] + bytes[i + 1] + bytes[i + 2] > 500) light++;
    }
    if (light > samples * 0.45) {
      top = y > 12 ? y - 12 : 0;
      break;
    }
  }
  if (top <= 0) return image;
  final cropHeight = height - top;
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(0, top.toDouble(), width.toDouble(), cropHeight.toDouble()),
    Rect.fromLTWH(0, 0, width.toDouble(), cropHeight.toDouble()),
    Paint(),
  );
  final picture = recorder.endRecording();
  final cropped = picture.toImageSync(width, cropHeight);
  picture.dispose();
  image.dispose();
  return cropped;
}
