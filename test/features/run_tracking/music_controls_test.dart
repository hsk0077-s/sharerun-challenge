import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/run_tracking/music_controls.dart';

class _FakeBridge implements MusicBridge {
  _FakeBridge({this.supported = true, this.sendOk = true, this.openOk = true});

  @override
  final bool supported;
  final bool sendOk;
  final bool openOk;
  final sent = <MusicKey>[];
  var opened = 0;

  @override
  Future<bool> send(MusicKey key) async {
    sent.add(key);
    return sendOk;
  }

  @override
  Future<bool> openApp() async {
    opened += 1;
    return openOk;
  }
}

Future<void> _pump(WidgetTester tester, MusicBridge bridge) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [musicBridgeProvider.overrideWithValue(bridge)],
      child: const MaterialApp(home: Scaffold(body: MusicControls())),
    ),
  );
}

void main() {
  testWidgets('each button sends its own key and the last one opens the music app',
      (tester) async {
    final bridge = _FakeBridge();
    await _pump(tester, bridge);

    await tester.tap(find.byKey(MusicControls.previousKey));
    await tester.tap(find.byKey(MusicControls.playPauseKey));
    await tester.tap(find.byKey(MusicControls.nextKey));
    await tester.tap(find.byKey(MusicControls.openKey));
    await tester.pump();

    expect(bridge.sent, [MusicKey.previous, MusicKey.playPause, MusicKey.next]);
    expect(bridge.opened, 1);
  });

  testWidgets('nothing is drawn where the phone cannot be controlled', (tester) async {
    await _pump(tester, _FakeBridge(supported: false));
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('a failed key tells the runner instead of staying silent', (tester) async {
    await _pump(tester, _FakeBridge(sendOk: false, openOk: false));
    await tester.tap(find.byKey(MusicControls.playPauseKey));
    await tester.pump();
    expect(find.text('음악을 조절하지 못했어요.'), findsOneWidget);

    await tester.tap(find.byKey(MusicControls.openKey));
    await tester.pump();
    expect(find.textContaining('음악 앱을 찾지 못했어요'), findsOneWidget);
  });
}
