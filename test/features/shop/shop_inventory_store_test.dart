import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/shop_inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persist then hydrate restores owned shop SKUs', () async {
    final prefs = await SharedPreferences.getInstance();
    const owned = ShopInventorySnapshot(
      cprCount: 1,
      safeGuardCount: 2,
      starBoostCount: 3,
      sharePackCount: 1,
    );

    await ShopInventoryStore.persist(
      prefs: prefs,
      inventory: owned,
      uid: 'uid-1',
    );

    final restored = ShopInventoryStore.hydrate(prefs, uid: 'uid-1');
    expect(restored.cprCount, 1);
    expect(restored.safeGuardCount, 2);
    expect(restored.starBoostCount, 3);
    expect(restored.sharePackCount, 1);
    expect(restored.hasOwnedItems, isTrue);
  });

  test('hydrate mergeMax keeps the higher count per SKU', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ShopInventoryStore.prefsKey,
      ShopInventoryStore.encode(
        const ShopInventorySnapshot(cprCount: 2, safeGuardCount: 1),
      ),
    );
    await prefs.setString(
      ShopInventoryStore.prefsKeyForUid('uid-1'),
      ShopInventoryStore.encode(
        const ShopInventorySnapshot(cprCount: 1, safeGuardCount: 4),
      ),
    );

    final restored = ShopInventoryStore.hydrate(prefs, uid: 'uid-1');
    expect(restored.cprCount, 2);
    expect(restored.safeGuardCount, 4);
  });

  test('empty snapshot has no owned items', () {
    expect(const ShopInventorySnapshot().hasOwnedItems, isFalse);
    expect(ShopInventoryStore.parse(''), isA<ShopInventorySnapshot>());
    expect(ShopInventoryStore.parse('not-json').hasOwnedItems, isFalse);
  });
}
