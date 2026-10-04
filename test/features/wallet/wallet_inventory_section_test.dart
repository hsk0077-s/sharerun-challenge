import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/features/shop/providers/server_shop_inventory_provider.dart';
import 'package:share_run_challenge/features/wallet/widgets/wallet_inventory_section.dart';

Widget _section(ServerShopInventory inventory) {
  return ProviderScope(
    overrides: [
      serverShopInventoryProvider.overrideWith(
        (ref) => Stream.value(inventory),
      ),
    ],
    child: MaterialApp(
      theme: SrcTheme.light,
      home: const Scaffold(
        body: WalletInventorySection(),
      ),
    ),
  );
}

void main() {
  testWidgets('wallet inventory lists server CPR and Safeguard', (tester) async {
    await tester.pumpWidget(
      _section(
        const ServerShopInventory(cprCount: 1, safeGuardCount: 2),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('wallet-inventory-section')), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryTitle), findsOneWidget);
    expect(find.text(AppStrings.itemInventoryCprTitle), findsOneWidget);
    expect(find.text(AppStrings.itemInventorySafeGuardTitle), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryCount(1)), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryCount(2)), findsOneWidget);
    expect(find.text(AppStrings.myWalletItemDuringRun), findsOneWidget);
    expect(find.text(AppStrings.myWalletItemDuringTournament), findsOneWidget);
    expect(find.text(AppStrings.itemInventoryUse), findsNothing);
    expect(find.text(AppStrings.myWalletInventoryEmpty), findsNothing);
    expect(find.text(AppStrings.myWalletInventoryOpen), findsOneWidget);
  });

  testWidgets('wallet inventory lists server catalog items only', (tester) async {
    await tester.pumpWidget(
      _section(
        const ServerShopInventory(ghostPaceCount: 3, battlePassCount: 1),
      ),
    );
    await tester.pump();

    expect(find.text('고스트 페이스 매칭'), findsOneWidget);
    expect(find.text('배틀런 챌린지 패스'), findsOneWidget);
    expect(find.text(AppStrings.storeItemStarBoost), findsNothing);
    expect(find.text(AppStrings.storeItemSharePack), findsNothing);
    expect(find.text(AppStrings.myWalletInventoryCount(3)), findsOneWidget);
    expect(find.text(AppStrings.myWalletInventoryCount(1)), findsOneWidget);
    expect(find.text(AppStrings.myWalletItemDuringRun), findsOneWidget);
    expect(find.text(AppStrings.battlePassInventoryNote), findsOneWidget);
  });

  testWidgets('wallet inventory empty state', (tester) async {
    await tester.pumpWidget(_section(const ServerShopInventory()));
    await tester.pump();

    expect(find.text(AppStrings.myWalletInventoryEmpty), findsOneWidget);
    expect(find.text(AppStrings.itemInventoryCprTitle), findsNothing);
  });
}
