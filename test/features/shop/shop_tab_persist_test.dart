import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/providers/shop_tab_provider.dart';
import 'package:share_run_challenge/features/shop/shop_inventory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addItem persists and a new notifier hydrates locker counts', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);

    first.read(shopTabProvider.notifier).addItem(ShopItemSku.cpr);
    first.read(shopTabProvider.notifier).addItem(ShopItemSku.safeGuard);

    ShopInventorySnapshot? stored;
    for (var i = 0; i < 40; i++) {
      final prefs = await SharedPreferences.getInstance();
      stored = ShopInventoryStore.hydrate(prefs);
      if (stored.cprCount == 1 && stored.safeGuardCount == 1) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(stored?.cprCount, 1);
    expect(stored?.safeGuardCount, 1);

    final second = ProviderContainer();
    addTearDown(second.dispose);
    second.read(shopTabProvider.notifier).restoreInventory(stored!);

    ShopTabState restored = second.read(shopTabProvider);
    for (var i = 0; i < 40 && !restored.hasOwnedItems; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      restored = second.read(shopTabProvider);
    }
    expect(restored.cprCount, 1);
    expect(restored.safeGuardCount, 1);
    expect(restored.hasOwnedItems, isTrue);
  });
}
