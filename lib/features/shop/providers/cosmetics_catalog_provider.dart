import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../cosmetics_catalog.dart';

/// Server cosmetics catalog. A failed request keeps the code defaults.
final cosmeticsCatalogProvider = FutureProvider<CosmeticsCatalog>((ref) async {
  try {
    final catalog =
        await ref.read(securedActionApiClientProvider).fetchCosmeticsCatalog();
    if (catalog.items.isEmpty) return CosmeticsCatalog.defaults;
    return catalog;
  } catch (_) {
    return CosmeticsCatalog.defaults;
  }
});
