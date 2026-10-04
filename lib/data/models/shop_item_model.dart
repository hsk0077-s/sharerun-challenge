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
      id: 'ghost_pace_match',
      title: '고스트 페이스 매칭',
      description: '과거 최고 페이스 고스트와 실시간 페이스 대결을 시작합니다.',
      diamondCost: 8,
      iconName: 'speed',
    ),
    ShopItemModel(
      id: 'battle_run_pass',
      title: '배틀런 챌린지 패스',
      description: '프리미엄 배틀런 시즌 입장권 및 주간 보너스 SRV를 제공합니다.',
      diamondCost: 120,
      iconName: 'emoji_events',
    ),
  ];
}
