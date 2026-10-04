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
      defaults.items.where((item) => item.category == runnerAvatar),
      hasLength(4),
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
          'id': 'avatar_snail',
          'name': '느린 달팽이',
          'category': runnerAvatar,
          'price': 45,
          'limited': false,
          'season': '',
          'asset': 'assets/images/characters/chibi_snail_smiling.png',
          'accent': '',
        },
      ],
    });
    expect(parsed.items.single.name, '느린 달팽이');
    expect(parsed.items.single.price, 45);
    expect(parsed.onSale(parsed.items.single), isTrue);
    expect(CosmeticsCatalog.fromJson(const {}).items, hasLength(12));
  });

  test('inventory docs own a cosmetic and keep the equipped slot', () {
    final inventory = ServerShopInventory.fromDocMaps({
      'avatar_snail': {
        'quantity': 1,
        'category': runnerAvatar,
      },
      'record_cpr_ticket': {'quantity': 2},
      cosmeticLoadoutDocId: {
        'quantity': 0,
        'slots': {
          runnerAvatar: {
            'id': 'avatar_snail',
            'name': '달팽이 러너',
            'asset': 'assets/images/characters/chibi_snail_smiling.png',
            'accent': '',
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
    expect(inventory.ownedCosmeticIds, {'avatar_snail'});
    expect(inventory.loadout.avatar.asset, contains('chibi_snail'));
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

    expect(find.text('달팽이 러너'), findsOneWidget);
    expect(find.textContaining(AppStrings.storeCosmeticLimited), findsWidgets);
    expect(find.textContaining('랜덤'), findsNothing);
    expect(find.text(AppStrings.storeCosmeticsNote), findsOneWidget);
    final wolf = tester.widget<TextButton>(
      find.byKey(const Key('cosmetic-buy-avatar_season_wolf')),
    );
    expect(wolf.onPressed, isNull);

    await tester.tap(find.byKey(const Key('cosmetic-buy-avatar_snail')));
    await tester.pump();
    expect(bought?.id, 'avatar_snail');

    await tester.scrollUntilVisible(
      find.byKey(const Key('cosmetic-equip-frame_blue')),
      200,
    );
    await tester.tap(find.byKey(const Key('cosmetic-equip-frame_blue')));
    await tester.pump();
    expect(equipped, 'frame_blue:true');
  });
}
