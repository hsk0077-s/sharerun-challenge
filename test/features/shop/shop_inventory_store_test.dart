import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/shop_inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('purchase persist survives hydrate after navigation', () async {
    final prefs = await SharedPreferences.getInstance();
    const bought = ShopInventorySnapshot(cprCount: 1, safeGuardCount: 1);
    await ShopInventoryStore.persist(
      prefs: prefs,
      inventory: bought,
      uid: 'uid-1',
    );

    final next = await SharedPreferences.getInstance();
    final snap = ShopInventoryStore.hydrate(next, uid: 'uid-1');
    expect(snap.cprCount, 1);
    expect(snap.safeGuardCount, 1);
    expect(snap.hasOwnedItems, isTrue);
  });

  test('mergeMax keeps the higher owned counts', () {
    const a = ShopInventorySnapshot(cprCount: 2, safeGuardCount: 0);
    const b = ShopInventorySnapshot(cprCount: 1, safeGuardCount: 3);
    final merged = ShopInventorySnapshot.mergeMax(a, b);
    expect(merged.cprCount, 2);
    expect(merged.safeGuardCount, 3);
  });
}
