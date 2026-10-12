import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_dock.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _screen = Size(390, 844);

Future<void> _pump(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool seenHint = true,
}) async {
  SharedPreferences.setMockInitialValues({
    if (seenHint) MiniBotDockSettings.hintSeenKey: true,
    ...prefs,
  });
  MiniBotDockSettings.resetForTest();
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: SrcTheme.light,
      home: const Scaffold(
        body: SizedBox.expand(),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: MiniBotEntryButton(heroTag: 'dock-test'),
        ),
      ),
    ),
  );
  await tester.pump();
  // 저장된 값을 읽는 일은 실제 비동기라서 한 번 기다린다.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await tester.pump();
}

Rect _face(WidgetTester tester) =>
    tester.getRect(find.byKey(MiniBotDock.faceKey));

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  group('fold and drag math', () {
    const screen = 390.0;
    const anchor = Rect.fromLTWH(318, 700, 56, 56);

    test('a button let go at an edge folds to that edge', () {
      Rect at(double left) => Rect.fromLTWH(left, 400, 56, 56);
      expect(
        MiniBotDockMath.edgeForRelease(
          face: at(4),
          screenWidth: screen,
          velocityX: 0,
        ),
        MiniBotDockEdge.left,
      );
      expect(
        MiniBotDockMath.edgeForRelease(
          face: at(screen - 56 - 4),
          screenWidth: screen,
          velocityX: 0,
        ),
        MiniBotDockEdge.right,
      );
      expect(
        MiniBotDockMath.edgeForRelease(
          face: at(150),
          screenWidth: screen,
          velocityX: 100,
        ),
        MiniBotDockEdge.none,
      );
    });

    test('a quick push sideways folds even in the middle', () {
      const face = Rect.fromLTWH(150, 400, 56, 56);
      expect(
        MiniBotDockMath.edgeForRelease(
          face: face,
          screenWidth: screen,
          velocityX: -1500,
        ),
        MiniBotDockEdge.left,
      );
      expect(
        MiniBotDockMath.edgeForRelease(
          face: face,
          screenWidth: screen,
          velocityX: 1500,
        ),
        MiniBotDockEdge.right,
      );
    });

    test('the button stays on screen and above its home spot', () {
      final dx = MiniBotDockMath.dxRange(anchor, screen);
      expect(anchor.left + dx.$1, MiniBotDockMath.margin);
      expect(anchor.left + dx.$2 + 56, screen - MiniBotDockMath.margin);
      final dy = MiniBotDockMath.dyRange(anchor, 47);
      expect(dy.$2, 0);
      expect(anchor.top + dy.$1, 47 + 8);
    });

    test('a folded button leaves 24px on screen', () {
      final left = MiniBotDockMath.foldedDx(MiniBotDockEdge.left, anchor, screen);
      expect(anchor.left + left + 56, MiniBotDockMath.foldedVisible);
      final right =
          MiniBotDockMath.foldedDx(MiniBotDockEdge.right, anchor, screen);
      expect(screen - (anchor.left + right), MiniBotDockMath.foldedVisible);
    });

    test('saved state survives a round trip and bad data is ignored', () {
      const state = MiniBotDockState(
        dx: -12.5,
        dy: -40,
        edge: MiniBotDockEdge.left,
      );
      final back = MiniBotDockState.decode(state.encode());
      expect(back.dx, -12.5);
      expect(back.dy, -40);
      expect(back.edge, MiniBotDockEdge.left);
      expect(MiniBotDockState.decode('not json').folded, isFalse);
      expect(MiniBotDockState.decode(null).dx, 0);
    });
  });

  testWidgets('tapping the face opens the bot', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(MiniBotDock.faceKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mini-bot-sheet')), findsOneWidget);
    await _done(tester);
  });

  testWidgets('the face can be dragged and the spot is remembered',
      (tester) async {
    await _pump(tester);
    final start = _face(tester);

    await tester.drag(find.byKey(MiniBotDock.faceKey), const Offset(-120, -200));
    await tester.pumpAndSettle();

    final moved = _face(tester);
    expect(moved.center.dx, closeTo(start.center.dx - 120, 2));
    expect(moved.center.dy, closeTo(start.center.dy - 200, 2));
    expect(find.byKey(const Key('mini-bot-sheet')), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final saved = MiniBotDockState.decode(
      prefs.getString(MiniBotDockSettings.dockKey),
    );
    expect(saved.dx, closeTo(-120, 2));
    expect(saved.folded, isFalse);

    await _done(tester);
    // 다시 열어도 같은 자리.
    await _pump(
      tester,
      prefs: {MiniBotDockSettings.dockKey: saved.encode()},
    );
    expect(_face(tester).center.dx, closeTo(start.center.dx - 120, 2));
    await _done(tester);
  });

  testWidgets('a push sideways folds it, a tap on the tab unfolds it',
      (tester) async {
    await _pump(tester);
    final open = _face(tester);

    await tester.fling(
      find.byKey(MiniBotDock.faceKey),
      const Offset(200, 0),
      1800,
    );
    await tester.pumpAndSettle();

    final folded = _face(tester);
    expect(
      _screen.width - folded.left,
      closeTo(MiniBotDockMath.foldedVisible, 0.01),
    );
    expect(find.byKey(const Key('mini-bot-sheet')), findsNothing);

    // 접힌 탭을 누르면 열리지 않고 펴지기만 한다.
    await tester.tapAt(Offset(_screen.width - 10, folded.center.dy));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mini-bot-sheet')), findsNothing);
    final unfolded = _face(tester);
    expect(unfolded.right, lessThanOrEqualTo(_screen.width));
    expect(unfolded.center.dy, closeTo(open.center.dy, 2));

    // 펴진 뒤에 누르면 열린다.
    await tester.tap(find.byKey(MiniBotDock.faceKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mini-bot-sheet')), findsOneWidget);
    await _done(tester);
  });

  testWidgets('a folded button comes back folded after a restart',
      (tester) async {
    await _pump(
      tester,
      prefs: {
        MiniBotDockSettings.dockKey: const MiniBotDockState(
          dy: -60,
          edge: MiniBotDockEdge.left,
        ).encode(),
      },
    );
    final face = _face(tester);
    expect(face.right, closeTo(MiniBotDockMath.foldedVisible, 0.01));
    await _done(tester);
  });

  testWidgets('the setting can hide the button and show it again',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(MiniBotDock.faceKey), findsOneWidget);

    await MiniBotDockSettings.setVisible(false);
    await tester.pump();
    expect(find.byKey(MiniBotDock.faceKey), findsNothing);

    await MiniBotDockSettings.setVisible(true);
    await tester.pump();
    expect(find.byKey(MiniBotDock.faceKey), findsOneWidget);
    await _done(tester);
  });

  testWidgets('the hint shows once and goes away on touch', (tester) async {
    await _pump(tester, seenHint: false);
    expect(find.byKey(MiniBotDock.hintKey), findsOneWidget);

    await tester.drag(find.byKey(MiniBotDock.faceKey), const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(MiniBotDock.hintKey), findsNothing);
    // 만진 순간 "봤음"으로 저장돼서 다음에는 나오지 않는다.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(MiniBotDockSettings.hintSeenKey), isTrue);
    await _done(tester);
  });
}
