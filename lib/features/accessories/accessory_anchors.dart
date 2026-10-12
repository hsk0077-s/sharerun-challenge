// 액세서리 v6 위치 값. 아트 제공 파일(anchors-v6.json)에서 옮긴 것이다.
// 1024×1024 캐릭터 판 기준. 512 소품을 scale만큼 줄이고 rotateDeg(반시계)만큼 돌린 뒤,
// 돌려서 커진 네모의 왼쪽 위 모서리를 (x, y)에 둔다.

import '../onboarding/src_onboarding_controller.dart';
import 'accessory_catalog.dart';

const Map<TierAnimal, Map<Accessory, AccessoryAnchor>> accessoryAnchors = {
  TierAnimal.turtle: {
    Accessory.cape:
        AccessoryAnchor(scale: 0.78, rotateDeg: 0.0, x: 188.0, y: 326.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.7552, rotateDeg: 0.0, x: 410.0, y: -61.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.7314, rotateDeg: 0.0, x: 393.0, y: -39.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 583.0, y: 68.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7915, rotateDeg: 0.0, x: 379.0, y: 66.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8558, rotateDeg: 0.0, x: 360.0, y: 38.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.42, rotateDeg: 0.0, x: 605.0, y: 415.0),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5, rotateDeg: 0.0, x: 584.0, y: 380.0),
    Accessory.baton:
        AccessoryAnchor(scale: 0.46, rotateDeg: 0.0, x: 594.0, y: 442.0),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 508.0, y: 459.0),
  },
  TierAnimal.maltese: {
    Accessory.cape:
        AccessoryAnchor(scale: 0.78, rotateDeg: 0.0, x: 168.0, y: 356.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.8149, rotateDeg: 0.0, x: 352.0, y: -66.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.7891, rotateDeg: 0.0, x: 333.0, y: 12.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 553.0, y: 93.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7463, rotateDeg: 0.0, x: 346.0, y: 122.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8069, rotateDeg: 0.0, x: 328.0, y: 96.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.42, rotateDeg: 0.0, x: 575.0, y: 445.0),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5, rotateDeg: 0.0, x: 554.0, y: 410.0),
    Accessory.baton:
        AccessoryAnchor(scale: 0.46, rotateDeg: 0.0, x: 564.0, y: 472.0),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 468.0, y: 479.0),
  },
  TierAnimal.wolf: {
    Accessory.cape:
        AccessoryAnchor(scale: 0.78, rotateDeg: 0.0, x: 168.0, y: 386.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.8149, rotateDeg: 0.0, x: 352.0, y: -66.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.7891, rotateDeg: 0.0, x: 333.0, y: 62.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 553.0, y: 128.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.6716, rotateDeg: 0.0, x: 382.0, y: 181.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.7262, rotateDeg: 0.0, x: 365.0, y: 157.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.42, rotateDeg: 0.0, x: 583.0, y: 467.0),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5, rotateDeg: 0.0, x: 562.0, y: 432.0),
    Accessory.baton:
        AccessoryAnchor(scale: 0.46, rotateDeg: 0.0, x: 572.0, y: 494.0),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 468.0, y: 524.0),
  },
  TierAnimal.horse: {
    Accessory.cape:
        AccessoryAnchor(scale: 0.78, rotateDeg: 0.0, x: 168.0, y: 376.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.7155, rotateDeg: 0.0, x: 389.0, y: -41.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.6929, rotateDeg: 0.0, x: 373.0, y: 77.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 543.0, y: 93.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7463, rotateDeg: 0.0, x: 361.0, y: 162.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8069, rotateDeg: 0.0, x: 343.0, y: 136.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.42, rotateDeg: 0.0, x: 581.0, y: 463.0),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5, rotateDeg: 0.0, x: 560.0, y: 428.0),
    Accessory.baton:
        AccessoryAnchor(scale: 0.46, rotateDeg: 0.0, x: 570.0, y: 490.0),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 458.0, y: 509.0),
  },
  TierAnimal.cheetah: {
    Accessory.cape:
        AccessoryAnchor(scale: 0.78, rotateDeg: 0.0, x: 168.0, y: 346.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.795, rotateDeg: 0.0, x: 361.0, y: -64.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.7699, rotateDeg: 0.0, x: 343.0, y: 7.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 553.0, y: 73.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7711, rotateDeg: 0.0, x: 371.0, y: 109.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8338, rotateDeg: 0.0, x: 352.0, y: 81.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.42, rotateDeg: 0.0, x: 605.0, y: 433.0),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5, rotateDeg: 0.0, x: 584.0, y: 398.0),
    Accessory.baton:
        AccessoryAnchor(scale: 0.46, rotateDeg: 0.0, x: 594.0, y: 460.0),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 468.0, y: 479.0),
  },
};
