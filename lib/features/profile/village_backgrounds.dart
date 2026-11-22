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
}
