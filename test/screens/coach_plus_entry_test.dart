import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/screens/store_screen.dart';
import 'package:share_run_challenge/screens/subscription_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('premium is a notice and only Coach+ opens payment', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const SubscriptionManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.subscriptionPremiumTitle), findsOneWidget);
    expect(find.text(AppStrings.subscriptionPremiumBenefit1), findsOneWidget);
    expect(find.text(AppStrings.subscriptionPremiumBenefit2), findsOneWidget);
    expect(find.text(AppStrings.subscriptionPremiumNotice), findsOneWidget);
    expect(find.textContaining('4,900'), findsNothing);
    expect(find.textContaining('첫 달'), findsNothing);
    expect(find.textContaining('결제 수단'), findsNothing);
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    final premiumColumn = find
        .ancestor(
          of: find.byKey(const Key('premium-notice')),
          matching: find.byType(Column),
        )
        .first;
    expect(
      find.descendant(
        of: premiumColumn,
        matching: find.byType(CupertinoSwitch),
      ),
      findsNothing,
    );

    final coach = tester.widget<InkWell>(
      find.byKey(const Key('coach-plus-subscription')),
    );
    expect(coach.onTap, isNotNull);
  });

  testWidgets('shop tab opens Coach+ and the diamond charge station', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const StoreScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.storeTitle), findsOneWidget);
    expect(find.text(AppStrings.storeChargeCta), findsOneWidget);
    expect(find.byKey(const Key('coach-plus-store')), findsOneWidget);

    final coach = tester.widget<InkWell>(
      find.byKey(const Key('coach-plus-store')),
    );
    expect(coach.onTap, isNotNull);
    expect(find.text(AppStrings.storeChargeCta), findsOneWidget);

    await tester.tap(find.text(AppStrings.storeChargeCta));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.iapBillingTitle), findsOneWidget);
  });
}
