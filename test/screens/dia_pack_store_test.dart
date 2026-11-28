import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/repositories/purchase_repository.dart';
import 'package:share_run_challenge/data/repositories/wallet_repository.dart';
import 'package:share_run_challenge/features/iap/providers/iap_providers.dart';
import 'package:share_run_challenge/features/iap/services/iap_purchase_controller.dart';
import 'package:share_run_challenge/screens/dia_pack_store_screen.dart';
import '../support/ko_localization.dart';

class _QuietIap implements InAppPurchase {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #purchaseStream) {
      return const Stream<List<PurchaseDetails>>.empty();
    }
    if (invocation.memberName == #isAvailable) return Future<bool>.value(false);
    return super.noSuchMethod(invocation);
  }
}

class _Repo implements PurchaseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet implements WalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
      ProviderScope(
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const DiaPackStoreScreen(),
        ),
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

  testWidgets('both switches on enables a buy button for every pack', (tester) async {
    AppEnv.debugInAppPurchasesOverride = true;
    AppEnv.debugDiaPacksOverride = true;
    addTearDown(() {
      AppEnv.debugInAppPurchasesOverride = null;
      AppEnv.debugDiaPacksOverride = null;
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = IapPurchaseController(
      purchaseRepository: _Repo(),
      walletRepository: _Wallet(),
      readUid: () => 'u1',
      iap: _QuietIap(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapPurchaseControllerProvider.overrideWithValue(controller),
          diaPackPriceLabelsProvider.overrideWith((ref) async => const {}),
        ],
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const DiaPackStoreScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('구매'), findsNWidgets(6));
    expect(find.text('준비 중'), findsNothing);
    for (final button in tester.widgetList<FilledButton>(find.byType(FilledButton))) {
      expect(button.onPressed, isNotNull);
    }
  });
}
