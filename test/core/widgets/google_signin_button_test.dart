import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/widgets/google_signin_button.dart';
import '../../support/ko_localization.dart';

void main() {
  test('the official G logo paths read cleanly inside the 48x48 sheet', () {
    expect(GoogleGLogoPainter.paths, hasLength(4));
    Rect all = Rect.zero;
    for (final (_, data) in GoogleGLogoPainter.paths) {
      final bounds = parseSvgPath(data).getBounds();
      expect(bounds.left, greaterThanOrEqualTo(-0.01));
      expect(bounds.top, greaterThanOrEqualTo(-0.01));
      expect(bounds.right, lessThanOrEqualTo(48.01));
      expect(bounds.bottom, lessThanOrEqualTo(48.01));
      all = all == Rect.zero ? bounds : all.expandToInclude(bounds);
    }
    // 네 조각이 합쳐서 판을 거의 채운다(공식 G는 가로 0~46.98, 세로 0~48).
    expect(all.width, closeTo(46.98, 0.1));
    expect(all.height, closeTo(48, 0.5));
  });

  test('the path reader handles relative, absolute and smooth curves', () {
    final box = parseSvgPath('M10 10h20v20H10z').getBounds();
    expect(box, const Rect.fromLTRB(10, 10, 30, 30));
    final curve = parseSvgPath('M0 0c0 10 10 10 10 0s10-10 10 0').getBounds();
    expect(curve.left, 0);
    expect(curve.right, closeTo(20, 0.01));
    expect(() => parseSvgPath('10 10'), throwsFormatException);
  });

  testWidgets('it follows the official size, border and text color',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: koTestLocale,
        supportedLocales: koTestSupportedLocales,
        localizationsDelegates: koTestDelegates,
        home: Scaffold(
          body: SizedBox(
            width: 324,
            child: GoogleSignInButton(onPressed: () => taps++),
          ),
        ),
      ),
    );

    final button =
        tester.widget<Material>(find.byKey(GoogleSignInButton.buttonKey));
    expect(button.color, Colors.white);
    final shape = button.shape! as StadiumBorder;
    expect(shape.side.color, const Color(0xFF747775));
    expect(shape.side.width, 1);
    expect(tester.getSize(find.byKey(GoogleSignInButton.buttonKey)).height,
        greaterThanOrEqualTo(40));
    expect(tester.getSize(find.byKey(GoogleSignInButton.logoKey)),
        const Size(20, 20));

    final text = tester.widget<Text>(find.text('Google 계정으로 로그인'));
    expect(text.style!.color, const Color(0xFF1F1F1F));
    expect(text.style!.fontSize, 14);
    expect(text.style!.fontWeight, FontWeight.w500);

    await tester.tap(find.byKey(GoogleSignInButton.buttonKey));
    expect(taps, 1);
  });

  testWidgets('full width fills the space up to 400 and is 44 tall',
      (tester) async {
    Future<Size> sizeAt(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: GoogleSignInButton(onPressed: () {}, fullWidth: true),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byKey(GoogleSignInButton.buttonKey));
    }

    expect(await sizeAt(324), const Size(324, 44));
    expect(await sizeAt(700), const Size(400, 44));
  });
}
