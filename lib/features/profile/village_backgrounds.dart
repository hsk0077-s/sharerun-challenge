/// 월드 빌리지 v2용 세로 배경 그림(1080x1920, WebP) 경로.
///
/// 아직 어느 화면에서도 쓰지 않는다. 화면은 빌리지 v2 작업에서 만든다.
/// 기존 마이 탭 마을(`village_scene.dart`)과는 별개이며, 그쪽이 자동으로 읽는
/// `assets/images/villages/` 와 섞이지 않도록 `assets/village/` 에 따로 둔다.
class VillageBackgrounds {
  const VillageBackgrounds._();

  static const dir = 'assets/village/';

  static const garden = '${dir}village_garden.webp';
  static const namsan = '${dir}village_namsan.webp';
  static const centralpark = '${dir}village_centralpark.webp';
  static const fuji = '${dir}village_fuji.webp';
  static const eiffel = '${dir}village_eiffel.webp';
  static const bali = '${dir}village_bali.webp';

  static const all = [garden, namsan, centralpark, fuji, eiffel, bali];

  /// World Tour village backgrounds (1080x1920) by landmark id. They are the
  /// `*_village.webp` pictures of the World Tour shop set, so they live in
  /// `assets/images/world_tour/shop/`. Still not shown on any screen.
  static const worldTour = {
    'eiffel_tower': 'assets/images/world_tour/shop/eiffel_tower_village.webp',
    'taj_mahal': 'assets/images/world_tour/shop/taj_mahal_village.webp',
    'mount_fuji': 'assets/images/world_tour/shop/mount_fuji_village.webp',
    'statue_of_liberty':
        'assets/images/world_tour/shop/statue_of_liberty_village.webp',
    'big_ben': 'assets/images/world_tour/shop/big_ben_village.webp',
  };
}
