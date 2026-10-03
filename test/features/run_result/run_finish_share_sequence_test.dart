import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_image_share.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_flow.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_targets.dart';
import 'package:share_run_challenge/screens/onboarding_run_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    final pickerKey = GlobalKey();
    final bannerKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SrcTheme.light,
        home: Scaffold(
          backgroundColor: const Color(0xFFF4F6F5),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: RepaintBoundary(
                    key: pickerKey,
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
                const SizedBox(height: 12),
                RepaintBoundary(
                  key: bannerKey,
                  child: const RunFinishSequenceBanner(
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
    );
    await tester.pump();
    expect(find.text('순서대로 공유'), findsOneWidget);
    expect(find.text('다음: TikTok'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    expect(tester.takeException(), isNull);

    if (Platform.environment['SHARE_CARD_SAMPLES'] == '1') {
      final out = Directory('/opt/cursor/artifacts/share-card');
      out.createSync(recursive: true);
      await _writePng(tester, pickerKey, '${out.path}/sequential-picker.png');
      await _writePng(tester, bannerKey, '${out.path}/sequential-progress.png');
    }
  });
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

Future<void> _writePng(WidgetTester tester, GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = boundary.toImageSync(pixelRatio: 2);
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  image.dispose();
  File(path).writeAsBytesSync(
    bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
}
