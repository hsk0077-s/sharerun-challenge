class ShopItemModel {
  const ShopItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.diamondCost,
    required this.iconName,
  });

  final String id;
  final String title;
  final String description;
  final int diamondCost;
  final String iconName;

  static const catalog = <ShopItemModel>[
    ShopItemModel(
      id: 'record_cpr_ticket',
      title: '기록 심폐소생권',
      description: '끊긴 연속 출석을 72시간 안에 되돌립니다. 한 달에 2번까지.',
      diamondCost: 12,
      iconName: 'favorite',
    ),
    ShopItemModel(
      id: 'record_safe_guard',
      title: '기록 마감 세이프 가드',
      description: '놓친 하루를 스트릭이 끊기기 전에 막아 줍니다. 최대 2개.',
      diamondCost: 8,
      iconName: 'shield',
    ),
    ShopItemModel(
      id: 'coach_one_point_ticket',
      title: '코치 원포인트권',
      description: '비구독 러닝 1회에 Coach+ 페이스 코칭을 엽니다. 하루 1회, 러닝 시작 시 사용.',
      diamondCost: 5,
      iconName: 'campaign',
    ),
    ShopItemModel(
      id: 'extra_entry_ticket',
      title: '추가 참가권',
      description: '모집이 끝났거나 정원이 찬 비상금 대회에 참가합니다. 하루 2회. 상금 대회는 불가.',
      diamondCost: 10,
      iconName: 'confirmation_number',
    ),
    ShopItemModel(
      id: 'extra_entry_ticket_3pack',
      title: '추가 참가권 3장',
      description: '추가 참가권 3장. 한 장씩 사는 것보다 저렴합니다.',
      diamondCost: 25,
      iconName: 'confirmation_number',
    ),
    ShopItemModel(
      id: 'friend_ghost_pace',
      title: '친구 고스트 페이스',
      description: '친구의 검증된 기록과 이번 러닝 페이스를 비교합니다. 내 최고 기록은 무료입니다.',
      diamondCost: 5,
      iconName: 'speed',
    ),
    ShopItemModel(
      id: 'friend_ghost_pace_10pack',
      title: '친구 고스트 10회',
      description: '친구 고스트 페이스 10회. 한 번씩 사는 것보다 저렴합니다.',
      diamondCost: 40,
      iconName: 'speed',
    ),
    ShopItemModel(
      id: 'crew_cheer_flag',
      title: '크루 응원 깃발',
      description: '하루 1회. 대회에서 크루원이 받는 SHARE 보상만 10% 늘어납니다.',
      diamondCost: 15,
      iconName: 'flag',
    ),
    ShopItemModel(
      id: 'ghost_pace_match',
      title: '고스트 페이스 매칭',
      description: '과거 최고 페이스 고스트와 실시간 페이스 대결을 시작합니다.',
      diamondCost: 8,
      iconName: 'speed',
    ),
    ShopItemModel(
      id: 'battle_run_pass',
      title: '배틀런 챌린지 패스',
      description: '시즌 1 프레임과 배지. 유료 DIA로만 살 수 있습니다.',
      diamondCost: 120,
      iconName: 'emoji_events',
    ),
    ShopItemModel(
      id: 'battle_run_pass_plus',
      title: '배틀런 패스+',
      description: '패스 보상에 프레임, 스킨, 배지를 더합니다. 패스가 있으면 차액만 냅니다.',
      diamondCost: 200,
      iconName: 'emoji_events',
    ),
  ];
}
