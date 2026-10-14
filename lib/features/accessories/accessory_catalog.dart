import '../onboarding/src_onboarding_controller.dart';

/// 캐릭터를 꾸미는 소품·스킨 46종. 디자인팀 납품 세트(2026-10-14)를 옮긴 것이다.
/// 그림은 모두 1024 판 전체 크기라서 위치 계산 없이 순서대로 겹치기만 하면 된다.
///
/// 가격·재화·희귀도는 납품 카탈로그 값이다. 실제 구매 가격의 기준은 서버이고,
/// [provisional]이 true인 항목은 카탈로그에 값이 없거나 확인이 필요해서 임시로 넣었다.
enum AccessorySlot {
  back('등'),
  bottom('하의'),
  top('상의'),
  feet('발'),
  hand('손'),
  eyes('눈'),
  head('머리'),
  skin('스킨');

  const AccessorySlot(this.labelKo);

  final String labelKo;

  /// 그림이 들어 있는 폴더. 상의·하의·발은 한 폴더(body)에 있다.
  String get folder => switch (this) {
        AccessorySlot.top ||
        AccessorySlot.bottom ||
        AccessorySlot.feet =>
          'body',
        _ => name,
      };
}

enum AccessoryCurrency { share, dia, none }

enum AccessoryRarity {
  basic('기본'),
  common('일반'),
  rare('희귀'),
  hero('영웅'),
  legend('전설'),
  tierReward('티어 보상');

  const AccessoryRarity(this.labelKo);

  final String labelKo;
}

class Accessory {
  const Accessory({
    required this.id,
    required this.nameKo,
    required this.slot,
    required this.file,
    required this.rarity,
    required this.currency,
    this.price,
    this.tierLock,
    this.frontFile,
    this.ready = true,
    this.provisional = false,
  });

  final String id;
  final String nameKo;
  final AccessorySlot slot;

  /// 동물 이름을 뺀 그림 파일 이름(확장자 제외).
  final String file;
  final AccessoryRarity rarity;
  final AccessoryCurrency currency;
  final int? price;

  /// 이 티어에 도달해야 살 수 있다. 없으면 누구나.
  final TierAnimal? tierLock;

  /// 몸 앞에 한 번 더 겹치는 그림(백팩 끈). 상의 위에 그린다.
  final String? frontFile;

  /// false면 그림에 문제가 있어서 화면에 내지 않는다(천사 날개: 왼쪽 끝이 잘려 있음).
  final bool ready;

  /// 납품 카탈로그에 값이 없거나 확인이 필요해서 임시로 넣은 항목.
  final bool provisional;

  String assetPath(TierAnimal animal) => _path(slot.folder, file, animal);

  String? frontAssetPath(TierAnimal animal) =>
      frontFile == null ? null : _path('body', frontFile!, animal);

  static String _path(String folder, String file, TierAnimal animal) =>
      'assets/images/accessories/$folder/$file-${animal.code}.webp';

  /// 화면에 보여 줄 값 문구. 가격이 없으면 비운다.
  String get priceLabel {
    if (rarity == AccessoryRarity.tierReward) return '티어 보상';
    final p = price;
    if (p == null) return '';
    return switch (currency) {
      AccessoryCurrency.share => '$p SHARE',
      AccessoryCurrency.dia => '$p DIA',
      AccessoryCurrency.none => '',
    };
  }

  @override
  bool operator ==(Object other) => other is Accessory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 전체 소품 목록. 화면에는 [accessoriesIn]으로 칸마다 꺼내 쓴다.
const accessoryCatalog = <Accessory>[
  Accessory(
    id: 'P001',
    nameKo: '기본 러닝캡',
    slot: AccessorySlot.head,
    file: 'cap',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 400,
  ),
  Accessory(
    id: 'P002',
    nameKo: '땀 헤어밴드',
    slot: AccessorySlot.head,
    file: 'headband',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 300,
  ),
  Accessory(
    id: 'P003',
    nameKo: '별 머리핀',
    slot: AccessorySlot.head,
    file: 'starpin',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 300,
  ),
  Accessory(
    id: 'P004',
    nameKo: '러닝 바이저',
    slot: AccessorySlot.head,
    file: 'visor',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 40,
  ),
  Accessory(
    id: 'P005',
    nameKo: '버킷햇',
    slot: AccessorySlot.head,
    file: 'buckethat',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 40,
  ),
  Accessory(
    id: 'P006',
    nameKo: '고양이귀 머리띠',
    slot: AccessorySlot.head,
    file: 'catears',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
  ),
  Accessory(
    id: 'P009',
    nameKo: '벚꽃 화관',
    slot: AccessorySlot.head,
    file: 'blossomcrown',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
  ),
  Accessory(
    id: 'P018',
    nameKo: '무선 헤드폰',
    slot: AccessorySlot.head,
    file: 'headphones',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 50,
    provisional: true,
  ),
  Accessory(
    id: 'GAT',
    nameKo: '갓',
    slot: AccessorySlot.head,
    file: 'gat',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 40,
    provisional: true,
  ),
  Accessory(
    id: 'P015',
    nameKo: '월계관',
    slot: AccessorySlot.head,
    file: 'laurel',
    rarity: AccessoryRarity.tierReward,
    currency: AccessoryCurrency.none,
  ),
  Accessory(
    id: 'P020',
    nameKo: '스포츠 선글라스',
    slot: AccessorySlot.eyes,
    file: 'sportglasses',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 400,
  ),
  Accessory(
    id: 'P021',
    nameKo: '동그란 안경',
    slot: AccessorySlot.eyes,
    file: 'roundglasses',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 30,
  ),
  Accessory(
    id: 'P022',
    nameKo: '에비에이터',
    slot: AccessorySlot.eyes,
    file: 'aviator',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 40,
  ),
  Accessory(
    id: 'P023',
    nameKo: '미러 고글',
    slot: AccessorySlot.eyes,
    file: 'goggles',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
  ),
  Accessory(
    id: 'P024',
    nameKo: '하트 선글라스',
    slot: AccessorySlot.eyes,
    file: 'heartglasses',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 50,
  ),
  Accessory(
    id: 'P030',
    nameKo: '바통',
    slot: AccessorySlot.hand,
    file: 'hand-baton-held',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 300,
  ),
  Accessory(
    id: 'P031',
    nameKo: '물병',
    slot: AccessorySlot.hand,
    file: 'hand-water-bottle-held',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 300,
  ),
  Accessory(
    id: 'P032',
    nameKo: '손목밴드',
    slot: AccessorySlot.hand,
    file: 'hand-wristband-held',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 200,
  ),
  Accessory(
    id: 'P033',
    nameKo: '성화',
    slot: AccessorySlot.hand,
    file: 'hand-torch-held',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 80,
  ),
  Accessory(
    id: 'P034',
    nameKo: '트로피 들기',
    slot: AccessorySlot.hand,
    file: 'hand-trophy-held',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 100,
  ),
  Accessory(
    id: 'P035',
    nameKo: '응원 깃발',
    slot: AccessorySlot.hand,
    file: 'hand-flag-held',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 40,
  ),
  Accessory(
    id: 'P036',
    nameKo: '하트 풍선',
    slot: AccessorySlot.hand,
    file: 'hand-heartballoon-held',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 40,
  ),
  Accessory(
    id: 'P037',
    nameKo: '응원봉',
    slot: AccessorySlot.hand,
    file: 'hand-lightstick-held',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 50,
  ),
  Accessory(
    id: 'P038',
    nameKo: '기부 저금통',
    slot: AccessorySlot.hand,
    file: 'hand-piggybank-held',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
  ),
  Accessory(
    id: 'STOPWATCH',
    nameKo: '스톱워치',
    slot: AccessorySlot.hand,
    file: 'hand-stopwatch-held',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 300,
    provisional: true,
  ),
  Accessory(
    id: 'P045',
    nameKo: '러닝 백팩',
    slot: AccessorySlot.back,
    file: 'backpack',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 500,
    frontFile: 'backpack-strap',
  ),
  Accessory(
    id: 'P046',
    nameKo: '망토',
    slot: AccessorySlot.back,
    file: 'cape',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
  ),
  Accessory(
    id: 'P047',
    nameKo: '천사 날개',
    slot: AccessorySlot.back,
    file: 'wings',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 100,
    ready: false,
  ),
  Accessory(
    id: 'P058',
    nameKo: '반팔 러닝티',
    slot: AccessorySlot.top,
    file: 'P058-tee-white-mesh',
    rarity: AccessoryRarity.basic,
    currency: AccessoryCurrency.share,
    price: 500,
  ),
  Accessory(
    id: 'P059',
    nameKo: '레이싱 싱글렛',
    slot: AccessorySlot.top,
    file: 'P059-singlet-lime',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 40,
  ),
  Accessory(
    id: 'P060',
    nameKo: '하프집 조끼',
    slot: AccessorySlot.top,
    file: 'P060-vest-sky',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 50,
  ),
  Accessory(
    id: 'P061',
    nameKo: '나눔 하트 티',
    slot: AccessorySlot.top,
    file: 'P061-tee-heart-pink',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 50,
  ),
  Accessory(
    id: 'P067',
    nameKo: '레이싱 쇼츠',
    slot: AccessorySlot.bottom,
    file: 'P067-shorts-racing-pink',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 40,
  ),
  Accessory(
    id: 'P069',
    nameKo: '러닝스커트',
    slot: AccessorySlot.bottom,
    file: 'P069-skirt-mint',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 50,
  ),
  Accessory(
    id: 'P074',
    nameKo: '네온 러닝화',
    slot: AccessorySlot.feet,
    file: 'P074-shoes-neon',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
  ),
  Accessory(
    id: 'P075',
    nameKo: '카본 레이싱화',
    slot: AccessorySlot.feet,
    file: 'P075-shoes-carbon',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 90,
  ),
  Accessory(
    id: 'P076',
    nameKo: '쿠션화',
    slot: AccessorySlot.feet,
    file: 'P076-shoes-cushion',
    rarity: AccessoryRarity.common,
    currency: AccessoryCurrency.dia,
    price: 50,
  ),
  Accessory(
    id: 'S001',
    nameKo: '거북 마스터',
    slot: AccessorySlot.skin,
    file: 'S001-turtle-master',
    rarity: AccessoryRarity.legend,
    currency: AccessoryCurrency.dia,
    price: 200,
    tierLock: TierAnimal.turtle,
  ),
  Accessory(
    id: 'S002',
    nameKo: '몰티즈 마스터',
    slot: AccessorySlot.skin,
    file: 'S002-maltese-master',
    rarity: AccessoryRarity.legend,
    currency: AccessoryCurrency.dia,
    price: 220,
    tierLock: TierAnimal.maltese,
  ),
  Accessory(
    id: 'S003',
    nameKo: '늑대 마스터',
    slot: AccessorySlot.skin,
    file: 'S003-wolf-master',
    rarity: AccessoryRarity.legend,
    currency: AccessoryCurrency.dia,
    price: 250,
    tierLock: TierAnimal.wolf,
  ),
  Accessory(
    id: 'S004',
    nameKo: '치타 금빛 챔피언',
    slot: AccessorySlot.skin,
    file: 'S004-cheetah-champion',
    rarity: AccessoryRarity.legend,
    currency: AccessoryCurrency.dia,
    price: 280,
    tierLock: TierAnimal.cheetah,
  ),
  Accessory(
    id: 'S005',
    nameKo: '단풍 트레일러',
    slot: AccessorySlot.skin,
    file: 'S005-maple-trailer',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 180,
  ),
  Accessory(
    id: 'S006',
    nameKo: '야간 러너',
    slot: AccessorySlot.skin,
    file: 'S006-night-runner',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 200,
  ),
  Accessory(
    id: 'S007',
    nameKo: '마라톤 완주자',
    slot: AccessorySlot.skin,
    file: 'S007-marathon-finisher',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 180,
  ),
  Accessory(
    id: 'S008',
    nameKo: '한복',
    slot: AccessorySlot.skin,
    file: 'S008-hanbok',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 180,
  ),
  Accessory(
    id: 'S009',
    nameKo: '말 마스터',
    slot: AccessorySlot.skin,
    file: 'S009-horse-master',
    rarity: AccessoryRarity.legend,
    currency: AccessoryCurrency.dia,
    price: 250,
    tierLock: TierAnimal.horse,
    provisional: true,
  ),
];

/// 한 칸의 소품 중 화면에 낼 수 있는 것만.
List<Accessory> accessoriesIn(AccessorySlot slot) => [
      for (final a in accessoryCatalog)
        if (a.slot == slot && a.ready) a,
    ];

/// 아래에서 위로 겹치는 순서(등 → 동물 → 하의 → 상의 → 신발 → 손 → 눈 → 머리).
/// 스킨은 동물을 통째로 바꾸므로 따로 그린다.
const accessoryDrawOrder = <AccessorySlot>[
  AccessorySlot.back,
  AccessorySlot.bottom,
  AccessorySlot.top,
  AccessorySlot.feet,
  AccessorySlot.hand,
  AccessorySlot.eyes,
  AccessorySlot.head,
];

/// 입힐 수 있는 동물. 달팽이(등급 없음)는 소품 그림이 없어서 제외한다.
bool canDress(TierAnimal animal) => animal != TierAnimal.snail;

/// [pick]을 입히면 같은 칸에 있던 것은 빠진다. 이미 입은 것이면 벗는다.
/// 스킨은 동물 전체를 바꾸므로 입으면 나머지가 모두 빠지고, 다른 소품을 입으면 스킨이 벗겨진다.
Set<Accessory> toggleAccessory(Set<Accessory> worn, Accessory pick) {
  if (worn.contains(pick)) return {...worn}..remove(pick);
  if (pick.slot == AccessorySlot.skin) return {pick};
  return {
    ...worn.where((a) => a.slot != pick.slot && a.slot != AccessorySlot.skin),
    pick,
  };
}
