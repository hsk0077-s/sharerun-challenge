import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/screens/store_screen.dart';
import 'package:share_run_challenge/screens/subscription_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_run_challenge/data/repositories/purchase_repository.dart';
import 'package:share_run_challenge/data/repositories/wallet_repository.dart';
import 'package:share_run_challenge/features/iap/providers/iap_providers.dart';
import 'package:share_run_challenge/features/iap/services/iap_purchase_controller.dart';
import '../support/ko_localization.dart';

class _FakeIap implements InAppPurchase {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #purchaseStream) {
      return const Stream<List<PurchaseDetails>>.empty();
    }
    if (invocation.memberName == #isAvailable) return Future<bool>.value(false);
    return super.noSuchMethod(invocation);
  }
}

class _PurchaseRepo implements PurchaseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WalletRepo implements WalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('only Coach+ opens payment and no donation toggle is shown',
      (tester) async {
    AppEnv.debugInAppPurchasesOverride = true;
    addTearDown(() => AppEnv.debugInAppPurchasesOverride = null);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const SubscriptionManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(find.textContaining('정기 후원'), findsNothing);
    expect(find.textContaining('4,900'), findsNothing);
    expect(find.textContaining('결제 수단'), findsNothing);

    final coach = tester.widget<InkWell>(
      find.byKey(const Key('coach-plus-subscription')),
    );
    expect(coach.onTap, isNotNull);
  });

  testWidgets('Coach+ sheet shows auto-renew, cancel path and health notice', (
    tester,
  ) async {
    AppEnv.debugInAppPurchasesOverride = true;
    addTearDown(() => AppEnv.debugInAppPurchasesOverride = null);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = IapPurchaseController(
      purchaseRepository: _PurchaseRepo(),
      walletRepository: _WalletRepo(),
      readUid: () => 'u1',
      iap: _FakeIap(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapPurchaseControllerProvider.overrideWithValue(controller)
        ],
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const SubscriptionManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('coach-plus-subscription')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coach-plus-terms')), findsOneWidget);
    expect(find.textContaining('자동 갱신'), findsOneWidget);
    expect(find.textContaining('구독에서 언제든 해지'), findsOneWidget);
    expect(
      find.byKey(const Key('coach-plus-health-disclaimer')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shop tab opens Coach+ and the diamond charge station',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const StoreScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.storeTitle), findsWidgets);
    expect(find.byKey(const Key('coach-plus-store')), findsNothing);

    await tester.tap(find.byKey(const Key('store-tab-diamond')));
    await tester.pumpAndSettle();
    // 1.0은 DIA 팩을 팔지 않는다. 교환만 보인다.
    expect(find.byKey(const Key('store-pack-dia_pack_130')), findsNothing);
    expect(find.byKey(const Key('store-dia-exchange')), findsOneWidget);
  });
}
