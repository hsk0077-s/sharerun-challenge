import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/shop_item_model.dart';

/// Server shop prices. Falls back to [ShopItemModel] when the catalog
/// request cannot run (logged out, offline).
final shopCatalogProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    final items =
        await ref.read(securedActionApiClientProvider).fetchShopCatalog();
    if (items.isEmpty) return _localCatalog();
    return {for (final item in items) item.id: item.diamondCost};
  } catch (_) {
    return _localCatalog();
  }
});

Map<String, int> _localCatalog() {
  return {for (final item in ShopItemModel.catalog) item.id: item.diamondCost};
}
