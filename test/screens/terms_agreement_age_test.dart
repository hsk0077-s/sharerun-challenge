import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/src_button.dart';
import 'package:share_run_challenge/core/widgets/src_checkbox.dart';
import 'package:share_run_challenge/screens/terms_agreement_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpTerms(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const TermsAgreementScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  bool continueEnabled(WidgetTester tester) =>
      tester.widget<SRCButton>(find.byType(SRCButton)).enabled;

  // Checkbox order: all-agree, service, privacy, location, age 14+, health.
  Future<void> tapBox(WidgetTester tester, int index) async {
    await tester.tap(find.byType(SRCCheckbox).at(index));
    await tester.pump();
  }

  testWidgets('shows the 14+ confirmation row', (tester) async {
    await pumpTerms(tester);

    expect(find.text('[필수] 만 14세 이상입니다'), findsOneWidget);
  });

  testWidgets('continue stays disabled until the 14+ box is checked',
      (tester) async {
    await pumpTerms(tester);

    await tapBox(tester, 1);
    await tapBox(tester, 2);
    await tapBox(tester, 3);
    expect(continueEnabled(tester), isFalse);

    await tapBox(tester, 4);
    expect(continueEnabled(tester), isTrue);
  });

  testWidgets('all-agree checks the 14+ box too', (tester) async {
    await pumpTerms(tester);

    await tapBox(tester, 0);
    expect(continueEnabled(tester), isTrue);

    await tapBox(tester, 4);
    expect(continueEnabled(tester), isFalse);
  });
}
