import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/providers/server_shop_inventory_provider.dart';

void main() {
  test('catalog document ids map to account counts', () {
    final inventory = ServerShopInventory.fromQuantities(const {
      ServerShopInventory.cprId: 2,
      ServerShopInventory.safeGuardId: 1,
      ServerShopInventory.ghostPaceId: 4,
      ServerShopInventory.battlePassId: 1,
      ServerShopInventory.coachOnePointId: 1,
      ServerShopInventory.extraEntryId: 3,
      'star_boost': 9,
    });

    expect(inventory.cprCount, 2);
    expect(inventory.safeGuardCount, 1);
    expect(inventory.ghostPaceCount, 4);
    expect(inventory.battlePassCount, 1);
    expect(inventory.coachOnePointCount, 1);
    expect(inventory.extraEntryCount, 3);
    expect(inventory.countFor(ServerShopInventory.extraEntryId), 3);
    expect(inventory.countFor('star_boost'), 0);
    expect(
      ServerShopInventory.fromQuantities(const {
        ServerShopInventory.friendGhostId: 2,
        ServerShopInventory.crewCheerId: 1,
      }),
      isA<ServerShopInventory>()
          .having((row) => row.friendGhostCount, 'friend', 2)
          .having((row) => row.crewCheerCount, 'cheer', 1)
          .having((row) => row.isEmpty, 'empty', isFalse),
    );
    expect(inventory.isEmpty, isFalse);
  });

  test('missing docs are zero on every phone', () {
    const inventory = ServerShopInventory();
    expect(inventory.isEmpty, isTrue);
    expect(inventory.countFor(ServerShopInventory.cprId), 0);
  });
}
