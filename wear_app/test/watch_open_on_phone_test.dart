import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/run_session.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/core/watch_run_link.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

class _FakeOpener implements WatchPhoneOpener {
  _FakeOpener({this.ok = true, this.throwing = false});

  final bool ok;
  final bool throwing;
  final uris = <String>[];

  @override
  Future<bool> open(String uri) async {
    uris.add(uri);
    if (throwing) throw Exception('no phone');
    return ok;
  }
}

RunSession _finishedSession() {
  final session = RunSession(clock: () => DateTime.utc(2026, 11, 10, 6, 20));
  session.start();
  session.addDistance(3.1);
  session.finish();
  return session;
}

Future<void> _pump(WidgetTester tester, Widget face) async {
  const size = Size(396, 396);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(debugShowCheckedModeBanner: false, home: face),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.localeTestValue =
      const Locale('ko');

  test('buildWatchRunUri keeps the id URL-safe', () {
    expect(buildWatchRunUri('watch_abc'), 'sharerun://run/watch_abc');
    expect(buildWatchRunUri(''), 'sharerun://run');
    expect(buildWatchRunUri(null), 'sharerun://run');
    expect(buildWatchRunUri(' watch_abc '), 'sharerun://run/watch_abc');
  });

  testWidgets('tapping the phone hint opens that run on the phone', (tester) async {
    final opener = _FakeOpener();
    await _pump(
      tester,
      SummaryFace(
        session: _finishedSession(),
        onDone: () {},
        activityId: 'watch_abc',
        phoneOpener: opener,
      ),
    );
    expect(find.text('자세한 건 폰에서 보기'), findsOneWidget);
    await tester.tap(find.byKey(SummaryFace.phoneHintKey));
    await tester.pump();
    await tester.pump();
    expect(opener.uris, ['sharerun://run/watch_abc']);
    expect(find.text('폰에서 열었어요'), findsOneWidget);
    expect(find.byKey(SummaryFace.phoneMessageKey), findsOneWidget);
  });

  testWidgets('a failed open shows a short message and does not crash',
      (tester) async {
    final opener = _FakeOpener(ok: false);
    await _pump(
      tester,
      SummaryFace(
        session: _finishedSession(),
        onDone: () {},
        activityId: 'watch_abc',
        phoneOpener: opener,
      ),
    );
    await tester.tap(find.byKey(SummaryFace.phoneHintKey));
    await tester.pump();
    await tester.pump();
    expect(opener.uris, ['sharerun://run/watch_abc']);
    expect(find.text('폰을 열 수 없어요'), findsOneWidget);
  });

  testWidgets('a thrown open is treated as failure', (tester) async {
    final opener = _FakeOpener(throwing: true);
    await _pump(
      tester,
      SummaryFace(
        session: _finishedSession(),
        onDone: () {},
        activityId: 'watch_abc',
        phoneOpener: opener,
      ),
    );
    await tester.tap(find.byKey(SummaryFace.phoneHintKey));
    await tester.pump();
    await tester.pump();
    expect(find.text('폰을 열 수 없어요'), findsOneWidget);
  });
}
