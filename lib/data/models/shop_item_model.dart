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
      description: '무효 처리된 러닝 1회를 복구해 기록을 되살립니다.',
      diamondCost: 3,
      iconName: 'favorite',
    ),
    ShopItemModel(
      id: 'record_safe_guard',
      title: '기록 마감 세이프 가드',
      description: '대회 마감 직전 누락된 GPS 구간을 안전하게 보완합니다.',
      diamondCost: 5,
      iconName: 'shield',
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
      diamondCost: 15,
      iconName: 'emoji_events',
    ),
  ];
}
