import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/shop/cosmetics_catalog.dart';
import 'package:share_run_challenge/features/shop/providers/server_shop_inventory_provider.dart';
import 'package:share_run_challenge/features/shop/widgets/cosmetics_shop_section.dart';

void main() {
  test('defaults stay in the DIA bands and a server row replaces them', () {
    final defaults = CosmeticsCatalog.defaults;
    expect(defaults.season, 'season_1');
    expect(
      defaults.items.where((item) => !cosmeticCategories.contains(item.category)),
      isEmpty,
    );
    expect(
      defaults.items.where((item) => item.category == shoeSkin),
      hasLength(4),
    );
    expect(
      defaults.items.where((item) => item.category == shareFrame),
      hasLength(4),
    );
    for (final item in defaults.items) {
      final ceiling = item.limited ? 300 : 200;
      expect(item.price, inInclusiveRange(30, ceiling));
      expect(item.name, isNotEmpty);
    }

    final parsed = CosmeticsCatalog.fromJson({
      'season': 'season_1',
      'items': [
        {
          'id': 'shoe_mint',
          'name': '느린 러닝화',
          'category': shoeSkin,
          'price': 45,
          'limited': false,
          'season': '',
          'asset': '',
          'accent': '#1E6A58',
        },
      ],
    });
    expect(parsed.items.single.name, '느린 러닝화');
    expect(parsed.items.single.price, 45);
    expect(parsed.onSale(parsed.items.single), isTrue);
    expect(CosmeticsCatalog.fromJson(const {}).items, hasLength(8));
  });

  test('inventory docs own a cosmetic and keep the equipped slot', () {
    final inventory = ServerShopInventory.fromDocMaps({
      'shoe_mint': {
        'quantity': 1,
        'category': shoeSkin,
      },
      'record_cpr_ticket': {'quantity': 2},
      cosmeticLoadoutDocId: {
        'quantity': 0,
        'slots': {
          shoeSkin: {
            'id': 'shoe_mint',
            'name': '민트 러닝화',
            'asset': '',
            'accent': '#1E6A58',
          },
          shareFrame: {
            'id': 'frame_blue',
            'name': '블루 결과 프레임',
            'asset': '',
            'accent': 'blue',
          },
        },
      },
    });

    expect(inventory.cprCount, 2);
    expect(inventory.ownedCosmeticIds, {'shoe_mint'});
    expect(inventory.loadout.shoe.id, 'shoe_mint');
    expect(inventory.loadout.frame.accent, 'blue');
    expect(cosmeticAccentColor('blue'), const Color(0xFF1A56C4));
    expect(cosmeticAccentColor('#FFC857'), const Color(0xFFFFC857));
    expect(cosmeticAccentColor(''), isNull);
  });

  testWidgets('shop section buys a direct item and equips an owned one',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CosmeticItem? bought;
    String? equipped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              CosmeticsShopSection(
                catalog: CosmeticsCatalog.defaults,
                diamondBalance: 100,
                ownedIds: const {'frame_blue'},
                loadout: const CosmeticLoadout(),
                busyId: '',
                onPurchase: (item) async => bought = item,
                onEquip: (item, equip) async {
                  equipped = '${item.id}:$equip';
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining(AppStrings.storeCosmeticLimited), findsWidgets);
    expect(find.textContaining('랜덤'), findsNothing);
    expect(find.text(AppStrings.storeCosmeticsNote), findsOneWidget);
    // 동물 캐릭터는 상점에서 팔지 않는다. 티어로만 정해진다.
    for (final name in ['달팽이 러너', '토끼 러너', '치타 러너', '시즌 1 늑대 러너']) {
      expect(find.text(name), findsNothing);
    }
    expect(find.text(cosmeticCategoryLabel('runner_avatar')), findsNothing);
    expect(find.byKey(const Key('cosmetic-buy-shoe_mint')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('cosmetic-equip-frame_blue')),
      200,
    );
    await tester.tap(find.byKey(const Key('cosmetic-equip-frame_blue')));
    await tester.pump();
    expect(equipped, 'frame_blue:true');
    expect(bought, isNull);
  });
}
