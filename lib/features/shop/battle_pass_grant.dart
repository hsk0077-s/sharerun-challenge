/// Server-confirmed 배틀런 패스 cosmetics for the current season.
///
/// Ownership and reward ids come from `shopInventory/battle_run_pass`.
/// The phone does not invent a frame, skin, or badge the server did not write.
class BattlePassReward {
  const BattlePassReward({
    required this.id,
    required this.title,
    required this.plusOnly,
  });

  final String id;
  final String title;
  final bool plusOnly;
}

const battlePassItemId = 'battle_run_pass';
const battlePassPlusItemId = 'battle_run_pass_plus';

const battlePassRewards = <BattlePassReward>[
  BattlePassReward(id: 'season1_frame', title: '시즌 1 프레임', plusOnly: false),
  BattlePassReward(id: 'season1_badge', title: '시즌 1 배지', plusOnly: false),
  BattlePassReward(
    id: 'season1_plus_frame',
    title: '시즌 1 플러스 프레임',
    plusOnly: true,
  ),
  BattlePassReward(id: 'season1_skin', title: '시즌 1 스킨', plusOnly: true),
  BattlePassReward(
    id: 'season1_plus_badge',
    title: '시즌 1 플러스 배지',
    plusOnly: true,
  ),
];

class BattlePassGrant {
  const BattlePassGrant({this.tier = '', this.rewardIds = const []});

  final String tier;
  final List<String> rewardIds;

  bool get ownsPass => tier == 'pass' || tier == 'plus';
  bool get ownsPlus => tier == 'plus';

  bool owned(String rewardId) => rewardIds.contains(rewardId);
}

BattlePassGrant battlePassGrantFromDoc(Map<String, dynamic>? data) {
  if (data == null) return const BattlePassGrant();
  final rawTier = data['tier'];
  var tier = rawTier == 'pass' || rawTier == 'plus' ? rawTier as String : '';
  if (tier.isEmpty && _qty(data['quantity']) >= 1) tier = 'pass';
  return BattlePassGrant(tier: tier, rewardIds: _rewardIds(data['rewards']));
}

int _qty(Object? raw) {
  if (raw is int) return raw < 0 ? 0 : raw;
  if (raw is num) {
    final value = raw.toInt();
    return value < 0 ? 0 : value;
  }
  return 0;
}

List<String> _rewardIds(Object? raw) {
  if (raw is! List) return const [];
  final ids = <String>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final id = row['id'];
    if (id is String && id.isNotEmpty) ids.add(id);
  }
  return ids;
}
