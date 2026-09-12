import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/features/shop/providers/shop_tab_provider.dart';
import 'package:share_run_challenge/features/wallet/widgets/wallet_inventory_section.dart';

void main() {
  testWidgets('wallet inventory lists owned CPR and Safeguard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: WalletInventorySection(
            shop: const ShopTabState(cprCount: 1, safeGuardCount: 2),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('wallet-inventory-section')), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryTitle), findsOneWidget);
    expect(find.text(AppStrings.itemInventoryCprTitle), findsOneWidget);
    expect(find.text(AppStrings.itemInventorySafeGuardTitle), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryCount(1)), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryCount(2)), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryEmpty), findsNothing);
  });

  testWidgets('wallet inventory empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(
          body: WalletInventorySection(shop: ShopTabState()),
        ),
      ),
    );

    expect(find.text(AppStrings.myWalletInventoryEmpty), findsOneWidget);
    expect(find.text(AppStrings.itemInventoryCprTitle), findsNothing);
  });
}
