import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
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
        locale: const Locale('ko', 'KR'),
        supportedLocales: ShareRunLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
    expect(find.byKey(const Key('coach-plus-store')), findsNothing);
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

  testWidgets(
      'VALUE is explained by a ? on its balance, not by a card at the bottom',
      (tester) async {
    await _pump(tester);
    expect(find.text(AppStrings.storeValueDetailTitle), findsNothing);

    await tester.tap(find.byKey(const Key('store-value-info')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.storeValueDetailTitle), findsOneWidget);
    expect(find.text(AppStrings.storeValueDetailBody), findsOneWidget);
    expect(find.textContaining('외부 지갑'), findsNothing);
    expect(find.textContaining('MetaMask'), findsNothing);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.storeValueDetailTitle), findsNothing);
  });

  testWidgets(
      'the funding card is honest: preparing, no fake progress, no dead button',
      (tester) async {
    await _pump(tester);
    await tester.ensureVisible(find.text(AppStrings.storeFundingTitle));
    expect(find.byKey(const Key('store-funding-preparing')), findsOneWidget);
    expect(find.text('준비 중'), findsWidgets);
    expect(find.textContaining('% 달성'), findsNothing);
    expect(find.textContaining('기부하기'), findsNothing);
    expect(find.textContaining('서버 원장'), findsNothing);
    // 기부처는 아직 정해지지 않아서 화면에 이름을 쓰지 않는다.
    expect(find.textContaining('유니세프'), findsNothing);
  });

  testWidgets('diamond tab has no DIA packs in 1.0, only the SHARE exchange',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('store-tab-diamond')));
    await tester.pumpAndSettle();

    expect(find.text('1,200원'), findsNothing);
    expect(find.text('119,000원'), findsNothing);
    expect(find.byKey(const Key('store-pack-dia_pack_130')), findsNothing);
    expect(find.textContaining('결제해도 DIA가 지급되지 않아요'), findsNothing);
    expect(find.byKey(const Key('store-dia-exchange')), findsOneWidget);
  });

  testWidgets('recommended tab shows no DIA pack row in 1.0', (tester) async {
    await _pump(tester);
    expect(find.text('다이아 충전'), findsNothing);
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
  });

  testWidgets('DIA focus lands on the items tab', (tester) async {
    await _pump(tester, focus: StoreFocus.items);

    expect(find.text(AppStrings.storeItemCpr), findsOneWidget);
  });
}
