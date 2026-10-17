import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/shop/providers/shop_tab_provider.dart';
import 'package:share_run_challenge/screens/store_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, {StoreFocus? focus}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: SrcTheme.night,
        home: StoreScreen(initialFocus: focus),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('store opens on the recommended tab with four pill tabs',
      (tester) async {
    await _pump(tester);

    for (final key in [
      'recommended',
      'diamond',
      'items',
      'cosmetics',
    ]) {
      expect(find.byKey(Key('store-tab-$key')), findsOneWidget);
    }
    expect(find.byKey(const Key('coach-plus-store')), findsOneWidget);
  });

  testWidgets('cosmetics tab no longer sells shoe skins or result-card frames',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('store-tab-cosmetics')));
    await tester.pumpAndSettle();

    expect(find.textContaining('러닝화 스킨'), findsNothing);
    expect(find.textContaining('결과 카드 프레임'), findsNothing);
    expect(find.textContaining('결과 프레임'), findsNothing);
    expect(find.textContaining('골드 러닝화'), findsNothing);
  });

  testWidgets('VALUE detail has no external wallet transfer', (tester) async {
    await _pump(tester);
    await tester.ensureVisible(find.text(AppStrings.storeValueDetailTitle));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.storeValueDetailTitle), findsOneWidget);
    expect(find.textContaining('외부 지갑'), findsNothing);
    expect(find.textContaining('MetaMask'), findsNothing);
  });

  testWidgets('diamond tab lists the DIA packs as not yet on sale',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('store-tab-diamond')));
    await tester.pumpAndSettle();

    expect(find.text('준비 중'), findsWidgets);
    expect(find.text('1,200원'), findsOneWidget);
    expect(find.text('119,000원'), findsOneWidget);
    expect(find.byKey(const Key('store-dia-exchange')), findsOneWidget);
  });

  testWidgets('items tab keeps every buy card', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('store-tab-items')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.storeItemCpr), findsOneWidget);
    expect(find.text(AppStrings.storeItemSafeGuard), findsOneWidget);
    expect(find.text(AppStrings.storeItemExtraEntry), findsOneWidget);
    expect(find.text(AppStrings.storeItemDonationMatch), findsOneWidget);
    expect(find.text(AppStrings.storeItemStepIncubator), findsOneWidget);
  });

  testWidgets('VALUE focus scrolls to the funding block on the recommended tab',
      (tester) async {
    await _pump(tester, focus: StoreFocus.donate);

    expect(find.text(AppStrings.storeFundingTitle), findsOneWidget);
    expect(find.text(AppStrings.storeValueDetailTitle), findsOneWidget);
  });

  testWidgets('DIA focus lands on the items tab', (tester) async {
    await _pump(tester, focus: StoreFocus.items);

    expect(find.text(AppStrings.storeItemCpr), findsOneWidget);
  });
}
