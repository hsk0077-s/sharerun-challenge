/// World Tour decoration prices in DIA. Art already exists per landmark.
/// These rows are the prices the shop reads. Buying a landmark set is not
/// wired yet, so the rows do not charge.
class WorldTourCosmeticPrice {
  const WorldTourCosmeticPrice({
    required this.id,
    required this.dia,
  });

  final String id;
  final int dia;
}

abstract final class WorldTourCosmeticPrices {
  static const costumeId = 'world_tour_costume';
  static const accessoryId = 'world_tour_accessory';
  static const backgroundId = 'world_tour_background';
  static const passportCoverId = 'world_tour_passport_cover';
  static const countrySetId = 'world_tour_country_set';

  static const costume = 120;
  static const accessory = 60;
  static const background = 90;
  static const passportCover = 70;
  static const countrySet = 270;

  /// costume + accessory + background + passport cover, bought one by one.
  static const separateTotal = costume + accessory + background + passportCover;

  static const catalog = <WorldTourCosmeticPrice>[
    WorldTourCosmeticPrice(id: costumeId, dia: costume),
    WorldTourCosmeticPrice(id: accessoryId, dia: accessory),
    WorldTourCosmeticPrice(id: backgroundId, dia: background),
    WorldTourCosmeticPrice(id: passportCoverId, dia: passportCover),
    WorldTourCosmeticPrice(id: countrySetId, dia: countrySet),
  ];

  static int? diaFor(String id) {
    for (final item in catalog) {
      if (item.id == id) return item.dia;
    }
    return null;
  }
}
