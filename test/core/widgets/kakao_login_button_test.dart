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
  test('it picks the official image whose height stays closest to 46', () {
    expect(KakaoLoginButton.variantFor(100), 'small');
    expect(KakaoLoginButton.variantFor(112), 'small');
    expect(KakaoLoginButton.variantFor(200), 'medium');
    expect(KakaoLoginButton.variantFor(324), 'large');
    // 노트10처럼 넓은 폰(약 371): 448짜리를 줄이면 높이 38이라 336짜리를 늘린다.
    expect(KakaoLoginButton.variantFor(371), 'large');
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

  testWidgets(
      'on a wide phone it keeps a tall button instead of shrinking '
      'the biggest image', (tester) async {
    await _pump(tester, width: 371, onPressed: () {});
    final size = tester.getSize(find.byKey(KakaoLoginButton.imageKey));
    expect(size.width, closeTo(371, 0.01));
    expect(size.height, closeTo(46 * 371 / 336, 0.5));
    expect(size.height, greaterThan(46));
    // 공식 이미지의 가로세로 비율(336:46)은 그대로다.
    expect(size.width / size.height, closeTo(336 / 46, 0.05));
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
                    KakaoLoginButton(onPressed: () {}, maxWidth: 324),
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
    final size = tester.getSize(find.byKey(KakaoLoginButton.imageKey));
    expect(size.width, closeTo(324, 0.01));
  });
}
