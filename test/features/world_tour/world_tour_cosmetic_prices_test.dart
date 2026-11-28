import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/shop_item_model.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_cosmetic_prices.dart';

void main() {
  test('world tour prices match the server and the set is cheaper', () {
    expect(WorldTourCosmeticPrices.costume, 120);
    expect(WorldTourCosmeticPrices.accessory, 60);
    expect(WorldTourCosmeticPrices.background, 90);
    expect(WorldTourCosmeticPrices.passportCover, 70);
    expect(WorldTourCosmeticPrices.countrySet, 270);
    expect(WorldTourCosmeticPrices.separateTotal, 340);
    expect(
      WorldTourCosmeticPrices.countrySet,
      lessThan(WorldTourCosmeticPrices.separateTotal),
    );
    for (final item in WorldTourCosmeticPrices.catalog) {
      final shop = ShopItemModel.catalog.firstWhere((row) => row.id == item.id);
      expect(shop.diamondCost, item.dia);
    }
  });
}
