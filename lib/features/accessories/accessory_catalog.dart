import '../onboarding/src_onboarding_controller.dart';

/// 캐릭터에 입힐 수 있는 액세서리 12종.
enum Accessory {
  cape('망토', AccessorySlot.back, 'back-cape'),
  medal('금메달', AccessorySlot.top, 'top-gold-medal'),
  shoes('형광 운동화', AccessorySlot.feet, 'feet-neon-shoes'),
  trophy('트로피', AccessorySlot.hand, 'hand-trophy'),
  torch('횃불', AccessorySlot.hand, 'hand-torch'),
  baton('바통', AccessorySlot.hand, 'hand-baton'),
  wristband('손목밴드', AccessorySlot.wrist, 'hand-wristband'),
  aviator('선글라스', AccessorySlot.eyes, 'eyes-aviator-sunglasses'),
  roundGlasses('동그란 안경', AccessorySlot.eyes, 'eyes-round-glasses'),
  cap('빨간 모자', AccessorySlot.head, 'head-cap'),
  headband('머리띠', AccessorySlot.head, 'head-headband'),
  starHairpin('별 핀', AccessorySlot.head, 'head-star-hairpin');

  const Accessory(this.nameKo, this.slot, this.file);

  final String nameKo;
  final AccessorySlot slot;

  /// 그림 파일 이름(확장자 제외).
  final String file;

  /// 모든 동물이 같은 그림을 쓰는 소품인지. 운동화·손목밴드는 동물마다 따로 칠했다.
  bool get perAnimal =>
      slot == AccessorySlot.feet || slot == AccessorySlot.wrist;

  String assetPath(TierAnimal animal) {
    const base = 'assets/images/accessories';
    return switch (slot) {
      AccessorySlot.feet => '$base/feet/$file-${animal.code}.png',
      AccessorySlot.wrist => '$base/wrist/$file-${animal.code}.png',
      _ => '$base/items/$file.png',
    };
  }
}

/// 몸의 어느 자리에 입는지. 같은 자리에는 한 가지만 입는다.
enum AccessorySlot { back, top, feet, hand, wrist, eyes, head }

/// 위치 값 한 개. 계산 방법은 accessory_anchors.dart 맨 위에 적혀 있다.
class AccessoryAnchor {
  const AccessoryAnchor({
    required this.scale,
    required this.rotateDeg,
    required this.x,
    required this.y,
  });

  final double scale;
  final double rotateDeg;
  final double x;
  final double y;
}

/// 아래에서 위로 겹치는 순서. 망토만 몸 뒤에 깔린다.
const accessoryDrawOrder = <AccessorySlot>[
  AccessorySlot.top,
  AccessorySlot.feet,
  AccessorySlot.hand,
  AccessorySlot.wrist,
  AccessorySlot.eyes,
  AccessorySlot.head,
];

/// 입힐 수 있는 동물. 달팽이(등급 없음)는 액세서리 그림이 없어서 제외한다.
bool canDress(TierAnimal animal) => animal != TierAnimal.snail;

/// [pick]을 입히면 같은 칸에 있던 것은 빠진다. 이미 입은 것이면 벗는다.
Set<Accessory> toggleAccessory(Set<Accessory> worn, Accessory pick) {
  if (worn.contains(pick)) return {...worn}..remove(pick);
  return {...worn.where((a) => a.slot != pick.slot), pick};
}
