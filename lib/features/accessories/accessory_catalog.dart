import 'package:flutter/widgets.dart';

import '../../l10n/remaining_surface.dart';
import '../onboarding/src_onboarding_controller.dart';
import '../../l10n/accessory_names.dart' as shop_names;
import 'accessory_names.dart';

/// 캐릭터를 꾸미는 소품·스킨 46종. 디자인팀 납품 세트(2026-10-14)를 옮긴 것이다.
/// 그림은 모두 1024 판 전체 크기라서 위치 계산 없이 순서대로 겹치기만 하면 된다.
///
/// 가격·재화·희귀도는 납품 카탈로그 값이다. 실제 구매 가격의 기준은 서버이다.
/// 임시였던 4개(헤드폰·갓·스톱워치·말 마스터)는 소유자가 그대로 확정했다(2026-10-17).
enum AccessorySlot {
  back('등'),
  bottom('하의'),
  top('상의'),
  feet('발'),
  hand('손'),
  eyes('눈'),
  head('머리'),
  skin('스킨'),

  /// 동물이 입는 운동복 세트. 상의·하의·신발·머리 그림 여러 장을 한 상품이 함께 낸다.
  outfit('outfit'),

  /// 남녀 캐릭터(홈 아바타)의 의상. 상반신 그림을 통째로 바꿔 끼운다.
  costume('costume');

  const AccessorySlot(this.labelKo);

  final String labelKo;

  /// 화면 언어로 된 이름. 한국어는 [labelKo] 그대로다.
  ///
  /// 운동복·캐릭터 의상은 번역 키 번호가 등급 이름(body.9~)과 겹치므로 자기 키를 쓴다.
  String label([BuildContext? context]) {
    if (this == AccessorySlot.outfit) {
      return RemainingSurface.tr(
        context,
        'accessories.accessory_catalog.slot_outfit',
        '운동복',
      );
    }
    if (this == AccessorySlot.costume) {
      return RemainingSurface.tr(
        context,
        'accessories.accessory_catalog.slot_costume',
        '캐릭터 의상',
      );
    }
    return RemainingSurface.tr(
      context,
      'accessories.accessory_catalog.body${index == 0 ? '' : '.${index + 1}'}',
      labelKo,
    );
  }

  /// 그림이 들어 있는 폴더. 상의·하의·발은 한 폴더(body)에 있다.
  String get folder => switch (this) {
        AccessorySlot.top ||
        AccessorySlot.bottom ||
        AccessorySlot.feet =>
          'body',
        _ => name,
      };
}

/// 누가 입는가. 동물(티어 마스코트), 캐릭터(홈 아바타), 둘 다(세트 상품).
enum AccessoryTarget { animal, character, both }

/// 남녀 버전. 운동복처럼 하나로 남녀 그림을 모두 쓰는 상품은 [unisex].
enum AccessoryGender { unisex, male, female }

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

  /// 화면 언어로 된 이름. 한국어는 [labelKo] 그대로다.
  String label([BuildContext? context]) => RemainingSurface.tr(
        context,
        'accessories.accessory_catalog.body.${index + 9}',
        labelKo,
      );
}

class Accessory {
  const Accessory({
    required this.id,
    String nameKo = '',
    required this.slot,
    required this.file,
    required this.rarity,
    required this.currency,
    this.price,
    this.tierLock,
    this.frontFile,
    this.ready = true,
    this.provisional = false,
    this.target = AccessoryTarget.animal,
    this.gender = AccessoryGender.unisex,
    this.bundle = const [],
    this.parts = const [],
  }) : _nameKo = nameKo;

  final String id;
  final String _nameKo;

  /// 한국어 이름. 의상 스킨처럼 목록에 한국어를 적지 않은 상품은 이름표(ko 칸)에서 읽는다.
  String get nameKo => _nameKo.isNotEmpty
      ? _nameKo
      : shop_names.accessoryName(id, id, const Locale('ko'));
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

  /// 입는 대상. 세트 상품([bundle])은 구매용이라 직접 입지 않는다.
  final AccessoryTarget target;

  /// 남녀 버전. 캐릭터 의상은 이 값이 현재 성별과 맞아야 입을 수 있다.
  final AccessoryGender gender;

  /// 세트 상품이 함께 열어 주는 상품 id들. 비어 있으면 단품.
  final List<String> bundle;

  /// 동물 운동복이 내는 그림 칸(상의·하의·신발·머리 중).
  final List<AccessorySlot> parts;

  bool get isBundle => bundle.isNotEmpty;

  /// 동물 몸에 겹치는 상품인가(운동복·소품·동물 스킨).
  bool get wornOnAnimal => !isBundle && target == AccessoryTarget.animal;

  /// 홈 아바타에 입히는 의상인가.
  bool get wornOnCharacter => !isBundle && target == AccessoryTarget.character;

  /// 운동복 한 칸의 그림.
  String partAssetPath(AccessorySlot part, TierAnimal animal) =>
      'assets/images/accessories/outfit/$file-${part.name}-${animal.code}.webp';

  /// 캐릭터 의상 그림. [gender]는 'male' 또는 'female'.
  String characterAssetPath(String gender) =>
      'assets/images/characters/costume/$file-$gender.webp';

  /// 이 상품의 캐릭터 그림을 [userGender]('male'|'female')로 쓸 수 있는가.
  bool fitsGender(String userGender) {
    if (!wornOnCharacter) return false;
    return switch (gender) {
      AccessoryGender.unisex => true,
      AccessoryGender.male => userGender != 'female',
      AccessoryGender.female => userGender == 'female',
    };
  }

  String assetPath(TierAnimal animal) => slot == AccessorySlot.outfit && parts.isNotEmpty
      ? partAssetPath(parts.first, animal)
      : _path(slot.folder, file, animal);

  String? frontAssetPath(TierAnimal animal) =>
      frontFile == null ? null : _path('body', frontFile!, animal);

  static String _path(String folder, String file, TierAnimal animal) =>
      'assets/images/accessories/$folder/$file-${animal.code}.webp';

  /// Locale name. Korean stays [nameKo] so older callers keep working.
  String displayName(Locale locale) {
    if (locale.languageCode == 'ko') return nameKo;
    return accessoryDisplayName(id, locale.languageCode) ?? nameKo;
  }

  /// 화면에 보여 줄 값 문구. 가격이 없으면 비운다.
  String get priceLabel {
    if (rarity == AccessoryRarity.tierReward) {
      return AccessoryRarity.tierReward.label();
    }
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
  ),
  Accessory(
    id: 'GAT',
    nameKo: '갓',
    slot: AccessorySlot.head,
    file: 'gat',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 40,
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
    nameKo: '비글 마스터',
    slot: AccessorySlot.skin,
    file: 'S002-beagle-master',
    rarity: AccessoryRarity.legend,
    currency: AccessoryCurrency.dia,
    price: 220,
    tierLock: TierAnimal.beagle,
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
    nameKo: '한복(동물)',
    slot: AccessorySlot.skin,
    file: 'S008-hanbok',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 180,
  ),
  Accessory(
    id: 'S009',
    nameKo: '얼룩말 마스터',
    slot: AccessorySlot.skin,
    file: 'S009-zebra-master',
    rarity: AccessoryRarity.legend,
    currency: AccessoryCurrency.dia,
    price: 250,
    tierLock: TierAnimal.zebra,
  ),

  // ---- 의상 스킨 1차(자리표시 그림). 가격: 운동복 60 · 동물+캐릭터 세트 90 · 전통의상 120 · 남녀 세트 200 DIA.
  Accessory(
    id: 'W1A',
    slot: AccessorySlot.outfit,
    file: 'soccer',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.animal,
    parts: [AccessorySlot.top, AccessorySlot.bottom, AccessorySlot.feet],
  ),
  Accessory(
    id: 'W1C',
    slot: AccessorySlot.costume,
    file: 'soccer',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.character,
  ),
  Accessory(
    id: 'W1B',
    slot: AccessorySlot.outfit,
    file: 'soccer',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 90,
    target: AccessoryTarget.both,
    bundle: ['W1A', 'W1C'],
  ),
  Accessory(
    id: 'W2A',
    slot: AccessorySlot.outfit,
    file: 'singlet',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.animal,
    parts: [AccessorySlot.top, AccessorySlot.bottom, AccessorySlot.feet, AccessorySlot.head],
  ),
  Accessory(
    id: 'W2C',
    slot: AccessorySlot.costume,
    file: 'singlet',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.character,
  ),
  Accessory(
    id: 'W2B',
    slot: AccessorySlot.outfit,
    file: 'singlet',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 90,
    target: AccessoryTarget.both,
    bundle: ['W2A', 'W2C'],
  ),
  Accessory(
    id: 'W3A',
    slot: AccessorySlot.outfit,
    file: 'basketball',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.animal,
    parts: [AccessorySlot.top, AccessorySlot.bottom, AccessorySlot.feet],
  ),
  Accessory(
    id: 'W3C',
    slot: AccessorySlot.costume,
    file: 'basketball',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.character,
  ),
  Accessory(
    id: 'W3B',
    slot: AccessorySlot.outfit,
    file: 'basketball',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 90,
    target: AccessoryTarget.both,
    bundle: ['W3A', 'W3C'],
  ),
  Accessory(
    id: 'W4A',
    slot: AccessorySlot.outfit,
    file: 'baseball',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.animal,
    parts: [AccessorySlot.top, AccessorySlot.bottom, AccessorySlot.feet, AccessorySlot.head],
  ),
  Accessory(
    id: 'W4C',
    slot: AccessorySlot.costume,
    file: 'baseball',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.character,
  ),
  Accessory(
    id: 'W4B',
    slot: AccessorySlot.outfit,
    file: 'baseball',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 90,
    target: AccessoryTarget.both,
    bundle: ['W4A', 'W4C'],
  ),
  Accessory(
    id: 'W5A',
    slot: AccessorySlot.outfit,
    file: 'badminton',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.animal,
    parts: [AccessorySlot.top, AccessorySlot.bottom, AccessorySlot.feet, AccessorySlot.head],
  ),
  Accessory(
    id: 'W5C',
    slot: AccessorySlot.costume,
    file: 'badminton',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.character,
  ),
  Accessory(
    id: 'W5B',
    slot: AccessorySlot.outfit,
    file: 'badminton',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 90,
    target: AccessoryTarget.both,
    bundle: ['W5A', 'W5C'],
  ),
  Accessory(
    id: 'W6A',
    slot: AccessorySlot.outfit,
    file: 'taekwondo',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.animal,
    parts: [AccessorySlot.top, AccessorySlot.bottom],
  ),
  Accessory(
    id: 'W6C',
    slot: AccessorySlot.costume,
    file: 'taekwondo',
    rarity: AccessoryRarity.rare,
    currency: AccessoryCurrency.dia,
    price: 60,
    target: AccessoryTarget.character,
  ),
  Accessory(
    id: 'W6B',
    slot: AccessorySlot.outfit,
    file: 'taekwondo',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 90,
    target: AccessoryTarget.both,
    bundle: ['W6A', 'W6C'],
  ),
  Accessory(
    id: 'T1M',
    slot: AccessorySlot.costume,
    file: 'hanbok',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.male,
  ),
  Accessory(
    id: 'T1F',
    slot: AccessorySlot.costume,
    file: 'hanbok',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.female,
  ),
  Accessory(
    id: 'T1S',
    slot: AccessorySlot.costume,
    file: 'hanbok',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 200,
    target: AccessoryTarget.character,
    bundle: ['T1M', 'T1F'],
  ),
  Accessory(
    id: 'T2M',
    slot: AccessorySlot.costume,
    file: 'yukata',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.male,
  ),
  Accessory(
    id: 'T2F',
    slot: AccessorySlot.costume,
    file: 'yukata',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.female,
  ),
  Accessory(
    id: 'T2S',
    slot: AccessorySlot.costume,
    file: 'yukata',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 200,
    target: AccessoryTarget.character,
    bundle: ['T2M', 'T2F'],
  ),
  Accessory(
    id: 'T3M',
    slot: AccessorySlot.costume,
    file: 'aodai',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.male,
  ),
  Accessory(
    id: 'T3F',
    slot: AccessorySlot.costume,
    file: 'aodai',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.female,
  ),
  Accessory(
    id: 'T3S',
    slot: AccessorySlot.costume,
    file: 'aodai',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 200,
    target: AccessoryTarget.character,
    bundle: ['T3M', 'T3F'],
  ),
  Accessory(
    id: 'T4M',
    slot: AccessorySlot.costume,
    file: 'bavaria',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.male,
  ),
  Accessory(
    id: 'T4F',
    slot: AccessorySlot.costume,
    file: 'bavaria',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 120,
    target: AccessoryTarget.character,
    gender: AccessoryGender.female,
  ),
  Accessory(
    id: 'T4S',
    slot: AccessorySlot.costume,
    file: 'bavaria',
    rarity: AccessoryRarity.hero,
    currency: AccessoryCurrency.dia,
    price: 200,
    target: AccessoryTarget.character,
    bundle: ['T4M', 'T4F'],
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

/// id로 찾는다. 없으면 null.
Accessory? accessoryById(String id) {
  for (final a in accessoryCatalog) {
    if (a.id == id) return a;
  }
  return null;
}

/// 목록에 보여 줄 대표 그림을 내는 상품. 세트는 첫 번째 구성품, 나머지는 자기 자신.
Accessory previewSourceOf(Accessory a) =>
    a.isBundle ? (accessoryById(a.bundle.first) ?? a) : a;

/// 옷 칸. 운동복을 입으면 이 칸의 낱개 소품이 빠지고, 낱개 옷을 입으면 운동복이 빠진다.
const _clothingSlots = {
  AccessorySlot.top,
  AccessorySlot.bottom,
  AccessorySlot.feet,
};

/// [pick]을 입히면 같은 칸에 있던 것은 빠진다. 이미 입은 것이면 벗는다.
/// 스킨은 동물 전체를 바꾸므로 입으면 나머지가 모두 빠지고, 다른 소품을 입으면 스킨이 벗겨진다.
/// 세트 상품과 캐릭터 의상은 동물에게 입히지 않으므로 아무것도 바꾸지 않는다.
Set<Accessory> toggleAccessory(Set<Accessory> worn, Accessory pick) {
  if (!pick.wornOnAnimal) return {...worn};
  if (worn.contains(pick)) return {...worn}..remove(pick);
  if (pick.slot == AccessorySlot.skin) return {pick};
  bool keep(Accessory a) {
    if (a.slot == AccessorySlot.skin) return false;
    if (a.slot == pick.slot) return false;
    if (pick.slot == AccessorySlot.outfit && _clothingSlots.contains(a.slot)) {
      return false;
    }
    if (a.slot == AccessorySlot.outfit && _clothingSlots.contains(pick.slot)) {
      return false;
    }
    return true;
  }

  return {...worn.where(keep), pick};
}
