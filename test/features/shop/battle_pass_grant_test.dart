import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/data/models/shop_item_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/shop/battle_pass_grant.dart';
import 'package:share_run_challenge/features/shop/providers/server_shop_inventory_provider.dart';
import 'package:share_run_challenge/features/shop/providers/shop_catalog_provider.dart';
import 'package:share_run_challenge/features/shop/shop_request_ids.dart';
import 'package:share_run_challenge/features/shop/streak_item_message.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/battle_pass_screen.dart';

void main() {
  test('a legacy quantity is a pass and rewards stay server ids', () {
    expect(battlePassGrantFromDoc(null).ownsPass, isFalse);
    final legacy = battlePassGrantFromDoc(const {'quantity': 1});
    expect(legacy.tier, 'pass');
    expect(legacy.rewardIds, isEmpty);
    expect(legacy.owned('season1_frame'), isFalse);

    final plus = battlePassGrantFromDoc(const {
      'tier': 'plus',
      'seasonId': 'season_1',
      'rewards': [
        {'id': 'season1_frame', 'kind': 'frame'},
        {'id': 'season1_skin', 'kind': 'skin'},
        {'id': ''},
        'nope',
      ],
    });
    expect(plus.ownsPlus, isTrue);
    expect(plus.rewardIds, ['season1_frame', 'season1_skin']);
  });

  test('pass prices and request ids match the server catalog', () {
    final costs = {
      for (final item in ShopItemModel.catalog) item.id: item.diamondCost,
    };
    expect(costs[battlePassItemId], 120);
    expect(costs[battlePassPlusItemId], 200);
    expect(requestPricedShopItemIds, contains(battlePassItemId));
    expect(requestPricedShopItemIds, contains(battlePassPlusItemId));
  });

  test('paid DIA and season errors stay in Korean', () {
    expect(
      streakItemMessage(
        const ApiException(
          statusCode: 400,
          detail: 'Insufficient paid Diamond balance.',
        ),
        fallback: 'fallback',
      ),
      '유료 DIA가 부족합니다. 무료 DIA로는 배틀런 패스를 살 수 없습니다.',
    );
    expect(
      streakItemMessage(
        const ApiException(
          statusCode: 400,
          detail: 'Battle pass already owned for this season.',
        ),
        fallback: 'fallback',
      ),
      '이번 시즌 배틀런 패스는 이미 구매했습니다.',
    );
  });

  testWidgets('unowned pass shows both prices and locked cosmetics',
      (tester) async {
    await tester.pumpWidget(_screen(const ServerShopInventory()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.battlePassNone), findsOneWidget);
    expect(find.text('배틀런 패스 · 120 DIA'), findsOneWidget);
    expect(find.text('패스+ · 200 DIA'), findsOneWidget);
    expect(find.text(AppStrings.battlePassCosmeticNote), findsOneWidget);
    expect(find.text('100 SHARE'), findsNothing);
    expect(find.text('3 다이아몬드'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(5));
  });

  testWidgets('a pass offers the 80 DIA upgrade and checks server rewards', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(
        const ServerShopInventory(
          battlePassCount: 1,
          battlePassTier: 'pass',
          battlePassRewardIds: ['season1_frame', 'season1_badge'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.battlePassOwned), findsOneWidget);
    expect(find.byKey(const Key('battle-pass-buy-pass')), findsNothing);
    expect(find.text('패스+ 업그레이드 · 80 DIA'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('battle-pass-reward-season1_frame')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('battle-pass-reward-season1_skin')),
        matching: find.byIcon(Icons.lock_outline_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('pass+ hides purchase and unlocks the extra cosmetics',
      (tester) async {
    await tester.pumpWidget(
      _screen(
        const ServerShopInventory(
          battlePassCount: 1,
          battlePassTier: 'plus',
          battlePassRewardIds: [
            'season1_frame',
            'season1_badge',
            'season1_plus_frame',
            'season1_skin',
            'season1_plus_badge',
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.battlePassPlusOwned), findsOneWidget);
    expect(find.byKey(const Key('battle-pass-buy-pass')), findsNothing);
    expect(find.byKey(const Key('battle-pass-buy-plus')), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));
  });
}

const _wallet = WalletModel(
  shareBalance: 0,
  diamondBalance: 30,
  valueTokenBalance: 0,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

Widget _screen(ServerShopInventory inventory) {
  return ProviderScope(
    overrides: [
      hasPendingJenaAppealProvider.overrideWith((ref) => false),
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      serverShopInventoryProvider
          .overrideWith((ref) => Stream.value(inventory)),
      shopCatalogProvider.overrideWith(
        (ref) async => const {
          battlePassItemId: 120,
          battlePassPlusItemId: 200,
        },
      ),
    ],
    child: MaterialApp(
      theme: SrcTheme.light,
      home: const BattlePassScreen(),
    ),
  );
}
