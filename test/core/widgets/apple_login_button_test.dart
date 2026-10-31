import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/widgets/apple_login_button.dart';
import '../../support/ko_localization.dart';

void main() {
  testWidgets('it is a black button with a white logo and text',
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
            child: AppleLoginButton(onPressed: () => taps++),
          ),
        ),
      ),
    );

    final material =
        tester.widget<Material>(find.byKey(AppleLoginButton.buttonKey));
    expect(material.color, Colors.black);
    expect(
      material.borderRadius,
      BorderRadius.circular(AppleLoginButton.radius),
    );
    final size = tester.getSize(find.byKey(AppleLoginButton.buttonKey));
    expect(size, const Size(324, 44));

    final icon = tester.widget<Icon>(find.byIcon(Icons.apple));
    expect(icon.color, Colors.white);
    final text = tester.widget<Text>(find.text('Apple로 계속하기'));
    expect(text.style!.color, Colors.white);

    await tester.tap(find.byKey(AppleLoginButton.buttonKey));
    expect(taps, 1);
  });
}
