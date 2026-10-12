import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/widgets/kakao_login_button.dart';

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
            child: KakaoLoginButton(onPressed: onPressed, busy: busy),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('it picks the smallest official image that is wide enough', () {
    expect(KakaoLoginButton.variantFor(100), 'small');
    expect(KakaoLoginButton.variantFor(112), 'small');
    expect(KakaoLoginButton.variantFor(200), 'medium');
    expect(KakaoLoginButton.variantFor(324), 'large');
    expect(KakaoLoginButton.variantFor(400), 'xlarge');
    expect(KakaoLoginButton.variantFor(900), 'xlarge');
  });

  test('every official image file is in the app', () {
    for (final name in ['small', 'medium', 'large', 'xlarge']) {
      for (final dir in ['', '2.0x/', '3.0x/', '4.0x/']) {
        expect(
          File('assets/images/kakao/${dir}kakao_login_kr_$name.png')
              .existsSync(),
          isTrue,
          reason: '$dir$name',
        );
      }
    }
  });

  testWidgets('it shows the official image keeping the 46:336 shape',
      (tester) async {
    await _pump(tester, width: 324, onPressed: () {});
    final size = tester.getSize(find.byKey(KakaoLoginButton.imageKey));
    expect(size.width, closeTo(324, 0.01));
    expect(size.height, closeTo(46 * 324 / 336, 0.5));
  });

  testWidgets('it never grows past the biggest official size', (tester) async {
    await _pump(tester, width: 700, onPressed: () {});
    final size = tester.getSize(find.byKey(KakaoLoginButton.imageKey));
    expect(size.width, closeTo(448, 0.01));
    expect(size.height, closeTo(46, 0.5));
  });

  testWidgets('tapping calls back; while busy it does not', (tester) async {
    var taps = 0;
    await _pump(tester, width: 324, onPressed: () => taps++);
    await tester.tap(find.byKey(KakaoLoginButton.imageKey));
    expect(taps, 1);

    await _pump(tester, width: 324, onPressed: () => taps++, busy: true);
    await tester.tap(find.byKey(KakaoLoginButton.imageKey));
    expect(taps, 1);
  });
}
