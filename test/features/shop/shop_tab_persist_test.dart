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
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(
      ShopInventoryStore.hydrate(prefs).cprCount,
      1,
    );
    expect(
      ShopInventoryStore.hydrate(prefs).safeGuardCount,
      1,
    );

    final second = ProviderContainer();
    addTearDown(second.dispose);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final restored = second.read(shopTabProvider);
    expect(restored.cprCount, 1);
    expect(restored.safeGuardCount, 1);
    expect(restored.hasOwnedItems, isTrue);
  });
}
