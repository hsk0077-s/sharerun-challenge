import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/widgets/naver_login_button.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required VoidCallback onPressed,
  bool busy = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: NaverLoginButton(onPressed: onPressed, busy: busy),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('the official image is in the app and is the official shape', () {
    final file = File('assets/images/naver/naver_login_kr.png');
    expect(file.existsSync(), isTrue);
    // PNG 머리말의 가로·세로(바이트 16~23). 공식 H48 이미지는 1472×192(= 368×48의 4배).
    final bytes = file.readAsBytesSync();
    final data = ByteData.sublistView(bytes);
    expect(data.getUint32(16), 1472);
    expect(data.getUint32(20), 192);
  });

  test('the button never grows past the official width', () {
    expect(NaverLoginButton.widthFor(324), 324);
    expect(NaverLoginButton.widthFor(368), 368);
    expect(NaverLoginButton.widthFor(700), 368);
  });

  testWidgets('it keeps the official 368:48 shape when it shrinks',
      (tester) async {
    await _pump(tester, width: 324, onPressed: () {});
    final size = tester.getSize(find.byKey(NaverLoginButton.imageKey));
    expect(size.width, closeTo(324, 0.01));
    expect(size.height, closeTo(48 * 324 / 368, 0.01));
  });

  testWidgets('at full size it is exactly the official size', (tester) async {
    await _pump(tester, width: 700, onPressed: () {});
    final size = tester.getSize(find.byKey(NaverLoginButton.imageKey));
    expect(size, const Size(368, 48));
  });

  testWidgets('tapping calls back; while busy it does not', (tester) async {
    var taps = 0;
    await _pump(tester, width: 324, onPressed: () => taps++);
    await tester.tap(find.byKey(NaverLoginButton.imageKey));
    expect(taps, 1);

    await _pump(tester, width: 324, onPressed: () => taps++, busy: true);
    await tester.tap(find.byKey(NaverLoginButton.imageKey));
    expect(taps, 1);
  });

  testWidgets('with maxWidth it works inside IntrinsicHeight (debug builds)',
      (tester) async {
    // 로그인 화면처럼 높이를 맞추는 틀 안에 둬도 디버그에서 오류가 나지 않아야 한다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 600, maxWidth: 324),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    NaverLoginButton(onPressed: () {}, maxWidth: 324),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byKey(NaverLoginButton.imageKey));
    expect(size.width, closeTo(324, 0.01));
  });
}
