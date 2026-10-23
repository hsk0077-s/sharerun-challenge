import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/screens/dia_pack_store_screen.dart';

void main() {
  testWidgets('DIA packs show bonus labels and do not sell', (tester) async {
    AppEnv.debugInAppPurchasesOverride = true;
    addTearDown(() => AppEnv.debugInAppPurchasesOverride = null);
    // 여섯 팩이 모두 그려지도록 화면을 길게 잡는다.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const DiaPackStoreScreen(),
      ),
    );

    expect(find.text('12 DIA'), findsOneWidget);
    expect(find.text('1,200원 · 보너스 없음'), findsOneWidget);
    expect(find.text('1,500 DIA'), findsOneWidget);
    expect(find.text('119,000원 · 보너스 310 DIA'), findsOneWidget);
    expect(find.textContaining('dia_pack_130'), findsOneWidget);
    expect(find.text('준비 중'), findsNWidgets(6));
    expect(find.widgetWithText(FilledButton, '준비 중'), findsNWidgets(6));
    for (final button in tester.widgetList<FilledButton>(find.byType(FilledButton))) {
      expect(button.onPressed, isNull);
    }
  });
}
