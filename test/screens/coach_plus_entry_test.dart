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
import '../support/ko_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('subscription screen says coaching is free and sells nothing',
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
    expect(find.textContaining('6,900'), findsNothing);
    expect(find.textContaining('결제 수단'), findsNothing);
    expect(find.byKey(const Key('coach-plus-subscription')), findsNothing);
    expect(find.byKey(const Key('coaching-free-note')), findsOneWidget);
    expect(find.textContaining('무료'), findsWidgets);
  });

  testWidgets('shop tab has no Coach+ card and hides DIA packs by default',
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
    expect(find.text('Coach+'), findsNothing);

    await tester.tap(find.byKey(const Key('store-tab-diamond')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('store-pack-dia_pack_130')), findsNothing);
    expect(find.byKey(const Key('store-dia-exchange')), findsOneWidget);
  });
}
