/// Paths of the World Tour decoration pictures: passport stamps, the passport
/// page, and the per-landmark shop pictures (accessory, village background,
/// passport cover) and character costumes.
///
/// These are only paths. Nothing here sells anything: the shop products
/// (price, currency, server catalog) are a separate decision.
class WorldTourShopArt {
  const WorldTourShopArt._();

  static const _dir = 'assets/images/world_tour';

  /// Landmarks that have a stamp picture. The other landmarks keep the plain
  /// check-mark icon until their stamp is drawn.
  static const stampIds = {
    'eiffel_tower',
    'taj_mahal',
    'mount_fuji',
    'statue_of_liberty',
    'big_ben',
  };

  /// Landmarks that have the three shop pictures.
  static const shopIds = stampIds;

  static const passportPage = '$_dir/passport/passport_page.webp';
  static const stampEmpty = '$_dir/passport/stamp_empty.webp';

  /// The stamp picture of [landmarkId], or null when it has none yet.
  static String? stamp(String landmarkId) => stampIds.contains(landmarkId)
      ? '$_dir/passport/stamp_$landmarkId.webp'
      : null;

  /// Round accessory picture (1024x1024, transparent).
  static String? accessory(String landmarkId) => _shop(landmarkId, 'accessory');

  /// Village background (1080x1920).
  static String? village(String landmarkId) => _shop(landmarkId, 'village');

  /// Passport cover (900x1200).
  static String? passportCover(String landmarkId) =>
      _shop(landmarkId, 'passport_cover');

  static String? _shop(String landmarkId, String kind) =>
      shopIds.contains(landmarkId)
          ? '$_dir/shop/${landmarkId}_$kind.webp'
          : null;

  /// Costume file stem per landmark: `wt-<stem>-<gender>.webp`.
  static const costumeStems = {
    'eiffel_tower': 'france',
    'taj_mahal': 'india',
    'mount_fuji': 'japan',
    'statue_of_liberty': 'usa',
    'big_ben': 'uk',
  };

  /// Character costume picture. [gender] is 'male' or 'female'.
  static String? costume(String landmarkId, String gender) {
    final stem = costumeStems[landmarkId];
    if (stem == null || (gender != 'male' && gender != 'female')) return null;
    return 'assets/images/characters/costume/wt-$stem-$gender.webp';
  }

  /// Every picture path this file can name, for tests.
  static List<String> get allPaths => [
        passportPage,
        stampEmpty,
        for (final id in stampIds) stamp(id)!,
        for (final id in shopIds) ...[
          accessory(id)!,
          village(id)!,
          passportCover(id)!,
        ],
        for (final id in costumeStems.keys) ...[
          costume(id, 'male')!,
          costume(id, 'female')!,
        ],
      ];
}
