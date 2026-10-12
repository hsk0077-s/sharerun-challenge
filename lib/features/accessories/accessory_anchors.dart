// 액세서리 v6 위치 값. 아트 제공 파일(anchors-v6.json)에서 옮긴 것이다.
// 1024×1024 캐릭터 판 기준. 512 소품을 scale만큼 줄이고 rotateDeg(반시계)만큼 돌린 뒤,
// 돌려서 커진 네모의 왼쪽 위 모서리를 (x, y)에 둔다.

import '../onboarding/src_onboarding_controller.dart';
import 'accessory_catalog.dart';

const Map<TierAnimal, Map<Accessory, AccessoryAnchor>> accessoryAnchors = {
  TierAnimal.turtle: {
    Accessory.cape:
        AccessoryAnchor(scale: 1.2000, rotateDeg: 0.0, x: -16.3, y: 314.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.7552, rotateDeg: 0.0, x: 410.0, y: -61.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.6729, rotateDeg: 0.0, x: 405.0, y: -13.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 583.0, y: 68.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7915, rotateDeg: 0.0, x: 379.0, y: 66.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8558, rotateDeg: 0.0, x: 360.0, y: 38.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.4200, rotateDeg: 0.0, x: 601.5, y: 409.5),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5000, rotateDeg: 0.0, x: 581.0, y: 375.7),
    Accessory.baton:
        AccessoryAnchor(scale: 0.4600, rotateDeg: -20.0, x: 558.1, y: 409.1),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 508.0, y: 459.0),
  },
  TierAnimal.maltese: {
    Accessory.cape:
        AccessoryAnchor(scale: 1.2000, rotateDeg: 0.0, x: -36.3, y: 344.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.8149, rotateDeg: 0.0, x: 352.0, y: -66.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.7260, rotateDeg: 0.0, x: 345.0, y: 38.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 553.0, y: 93.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7463, rotateDeg: 0.0, x: 346.0, y: 122.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8069, rotateDeg: 0.0, x: 328.0, y: 96.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.4200, rotateDeg: 0.0, x: 562.5, y: 433.5),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5000, rotateDeg: 0.0, x: 542.0, y: 399.7),
    Accessory.baton:
        AccessoryAnchor(scale: 0.4600, rotateDeg: -20.0, x: 519.1, y: 433.1),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 468.0, y: 479.0),
  },
  TierAnimal.wolf: {
    Accessory.cape:
        AccessoryAnchor(scale: 1.2000, rotateDeg: 0.0, x: -36.3, y: 374.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.8149, rotateDeg: 0.0, x: 352.0, y: -66.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.7260, rotateDeg: 0.0, x: 345.0, y: 88.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 553.0, y: 128.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.6716, rotateDeg: 0.0, x: 382.0, y: 181.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.7262, rotateDeg: 0.0, x: 365.0, y: 157.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.4200, rotateDeg: 0.0, x: 569.5, y: 458.5),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5000, rotateDeg: 0.0, x: 549.0, y: 424.7),
    Accessory.baton:
        AccessoryAnchor(scale: 0.4600, rotateDeg: -20.0, x: 526.1, y: 458.1),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 468.0, y: 524.0),
  },
  TierAnimal.horse: {
    Accessory.cape:
        AccessoryAnchor(scale: 1.2000, rotateDeg: 0.0, x: -36.3, y: 364.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.7155, rotateDeg: 0.0, x: 389.0, y: -41.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.6375, rotateDeg: 0.0, x: 385.0, y: 103.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 543.0, y: 93.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7463, rotateDeg: 0.0, x: 361.0, y: 162.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8069, rotateDeg: 0.0, x: 343.0, y: 136.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.4200, rotateDeg: 0.0, x: 565.5, y: 439.5),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5000, rotateDeg: 0.0, x: 545.0, y: 405.7),
    Accessory.baton:
        AccessoryAnchor(scale: 0.4600, rotateDeg: -20.0, x: 522.1, y: 439.1),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 458.0, y: 509.0),
  },
  TierAnimal.cheetah: {
    Accessory.cape:
        AccessoryAnchor(scale: 1.2000, rotateDeg: 0.0, x: -36.3, y: 334.0),
    Accessory.cap:
        AccessoryAnchor(scale: 0.795, rotateDeg: 0.0, x: 361.0, y: -64.0),
    Accessory.headband:
        AccessoryAnchor(scale: 0.7083, rotateDeg: 0.0, x: 355.0, y: 33.0),
    Accessory.starHairpin:
        AccessoryAnchor(scale: 0.36, rotateDeg: -15.0, x: 553.0, y: 73.0),
    Accessory.aviator:
        AccessoryAnchor(scale: 0.7711, rotateDeg: 0.0, x: 371.0, y: 109.0),
    Accessory.roundGlasses:
        AccessoryAnchor(scale: 0.8338, rotateDeg: 0.0, x: 352.0, y: 81.0),
    Accessory.trophy:
        AccessoryAnchor(scale: 0.4200, rotateDeg: 0.0, x: 588.5, y: 430.5),
    Accessory.torch:
        AccessoryAnchor(scale: 0.5000, rotateDeg: 0.0, x: 568.0, y: 396.7),
    Accessory.baton:
        AccessoryAnchor(scale: 0.4600, rotateDeg: -20.0, x: 545.1, y: 430.1),
    Accessory.medal:
        AccessoryAnchor(scale: 0.36, rotateDeg: 0.0, x: 468.0, y: 479.0),
  },
};
