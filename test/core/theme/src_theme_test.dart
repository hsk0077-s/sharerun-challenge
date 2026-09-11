import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/src_token_showcase.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/src_button.dart';

void main() {
  testWidgets('SrcTheme builds a token showcase with primary CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(body: SrcTokenShowcase()),
      ),
    );

    expect(find.text('SRC tokens'), findsOneWidget);
    expect(find.text('Primary CTA'), findsOneWidget);
    expect(find.text('Surface card'), findsOneWidget);
    expect(find.byType(SrcSurfaceCard), findsOneWidget);
    expect(find.byType(SRCButton), findsOneWidget);

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(SRCButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.primaryMint);

    final BuildContext context = tester.element(find.byType(SrcTokenShowcase));
    expect(context.srcTokens.colors.accent, AppColors.tealAccent);
    expect(Theme.of(context).colorScheme.secondary, AppColors.tealAccent);
  });

  testWidgets('token showcase golden', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(390, 540);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SrcTheme.light,
        home: const Scaffold(body: SrcTokenShowcase()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SrcTokenShowcase),
      matchesGoldenFile('goldens/src_token_showcase.png'),
    );
  });
}
