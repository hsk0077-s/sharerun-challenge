import '../../l10n/remaining_surface.dart';

/// `GET /actions/company-tournament/config`. Fees come from this payload.
class CompanyTournamentTier {
  const CompanyTournamentTier({
    required this.entryShare,
    required this.freeTicketCost,
    this.advertisedPrizeDia = 0,
  });

  final int entryShare;
  final int freeTicketCost;

  /// Sum of bonus DIA prizes. The server sends this as `advertisedPrizeDia`.
  final int advertisedPrizeDia;
}

class CompanyTournamentConfig {
  const CompanyTournamentConfig({
    required this.tiers,
    this.beginnerFreeEntryEligible = false,
    this.freeEntryLabelKo,
    this.weeklyLimitLabelKo,
    this.prizeIneligibleReasonKo,
    this.freeEntryCount,
    this.weeklyEntriesPerTier,
    this.prizeIneligibleReason,
    this.claimMinAccountAgeDays,
    this.claimMinVerifiedRuns,
    this.claimWindowDays,
    this.tierTicketJoinLabels = const {},
    this.diaKrw = 0,
  });

  final Map<String, CompanyTournamentTier> tiers;
  final bool beginnerFreeEntryEligible;
  final String? freeEntryLabelKo;
  final String? weeklyLimitLabelKo;
  final String? prizeIneligibleReasonKo;

  /// 서버가 한국어 문장과 함께 보내는 숫자·사유 코드. 앱이 사용자 언어 문장을 만드는 데 쓴다.
  /// 옛 서버라 없으면 위 한국어 문장을 그대로 쓴다.
  final int? freeEntryCount;
  final int? weeklyEntriesPerTier;
  final String? prizeIneligibleReason;
  final int? claimMinAccountAgeDays;
  final int? claimMinVerifiedRuns;
  final int? claimWindowDays;
  final Map<String, String> tierTicketJoinLabels;

  /// "첫 2회 무료" — 화면 언어로.
  String? get freeEntryLabel {
    final n = freeEntryCount;
    if (n == null || freeEntryLabelKo == null) return freeEntryLabelKo;
    return RemainingSurface.trNow('prize.free_entries', '첫 \$count회 무료', {'count': n});
  }

  /// "같은 등급은 일주일에 1번만…" — 화면 언어로.
  String? get weeklyLimitLabel {
    final n = weeklyEntriesPerTier;
    if (n == null || weeklyLimitLabelKo == null) return weeklyLimitLabelKo;
    return RemainingSurface.trNow('prize.weekly_limit', '같은 등급은 일주일에 \$limit번만 참가할 수 있어요.', {'limit': n});
  }

  /// 다이아 상금을 못 받는 이유 — 화면 언어로.
  String? get prizeIneligibleLabel {
    final fallback = prizeIneligibleReasonKo;
    final age = claimMinAccountAgeDays;
    final runs = claimMinVerifiedRuns;
    final window = claimWindowDays;
    return switch (prizeIneligibleReason) {
      'not_identity_verified' => RemainingSurface.trNow('prize.reason.identity', '본인인증된 계정이 아니라 다이아 상금을 받을 수 없어요.'),
      'account_too_new' when age != null => RemainingSurface.trNow('prize.reason.account_new', '가입 \$age일이 지나야 다이아 상금을 받을 수 있어요.', {'age': age}),
      'not_enough_verified_runs' when runs != null && window != null => RemainingSurface.trNow(
          'prize.reason.runs', '최근 \$window일 안에 인증된 달리기가 \$runs회 이상이어야 다이아 상금을 받을 수 있어요.', {'window': window, 'runs': runs}),
      _ => fallback,
    };
  }

  /// 등급 이름(초급·중급·상급·하프) — 화면 언어로.
  static String tierName(String tierId) => switch (tierId.trim().toLowerCase()) {
        'beginner' => RemainingSurface.trNow('mini_bot.mini_bot_intent.body.23', '초급'),
        'mid' => RemainingSurface.trNow('mini_bot.mini_bot_intent.body.24', '중급'),
        'advanced' => RemainingSurface.trNow('mini_bot.mini_bot_intent.body.25', '상급'),
        'half' => RemainingSurface.trNow('mini_bot.mini_bot_intent.body.26', '하프'),
        _ => tierId,
      };

  /// Won per 1 DIA from the same config payload. 0 until the server sends it.
  final int diaKrw;

  CompanyTournamentTier? tier(String id) => tiers[id.trim().toLowerCase()];

  String? tierTicketJoinLabel(String tierId) {
    final label = tierTicketJoinLabels[tierId.trim().toLowerCase()];
    if (label == null || label.isEmpty) return null;
    final id = tierId.trim().toLowerCase();
    if (id != 'beginner' && id != 'mid' && id != 'advanced' && id != 'half') return label;
    return RemainingSurface.trNow('prize.tier_ticket_join', '\$tier 참가권으로 참가', {'tier': tierName(id)});
  }

  factory CompanyTournamentConfig.fromJson(Map<String, dynamic> json) {
    final raw = json['tiers'];
    final tiers = <String, CompanyTournamentTier>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! Map) continue;
        final share = _readInt(value['entryShare']);
        final tickets = _readInt(value['freeTicketCost']);
        if (share == null || tickets == null) continue;
        tiers[key.trim().toLowerCase()] = CompanyTournamentTier(
          entryShare: share,
          freeTicketCost: tickets,
          advertisedPrizeDia: _advertisedPrizeDia(value),
        );
      }
    }
    final viewer = json['viewer'];
    final freeLabel = viewer is Map ? viewer['freeEntryLabelKo'] : null;
    final weekLabel = viewer is Map ? viewer['weeklyLimitLabelKo'] : null;
    final claimLabel = viewer is Map ? viewer['prizeIneligibleReasonKo'] : null;
    return CompanyTournamentConfig(
      tiers: tiers,
      beginnerFreeEntryEligible:
          viewer is Map && viewer['beginnerFreeEntryEligible'] == true,
      freeEntryLabelKo:
          freeLabel is String && freeLabel.isNotEmpty ? freeLabel : null,
      weeklyLimitLabelKo:
          weekLabel is String && weekLabel.isNotEmpty ? weekLabel : null,
      freeEntryCount: viewer is Map ? _readInt(viewer['beginnerFreeEntryCount']) : null,
      weeklyEntriesPerTier: viewer is Map ? _readInt(viewer['weeklyEntriesPerTier']) : null,
      prizeIneligibleReason: viewer is Map && viewer['prizeIneligibleReason'] is String
          ? viewer['prizeIneligibleReason'] as String
          : null,
      claimMinAccountAgeDays: viewer is Map ? _readInt(viewer['prizeClaimMinAccountAgeDays']) : null,
      claimMinVerifiedRuns: viewer is Map ? _readInt(viewer['prizeClaimMinVerifiedRuns']) : null,
      claimWindowDays: viewer is Map ? _readInt(viewer['prizeClaimVerifiedRunWindowDays']) : null,
      prizeIneligibleReasonKo:
          claimLabel is String && claimLabel.isNotEmpty ? claimLabel : null,
      tierTicketJoinLabels: _tierTicketLabels(viewer),
      diaKrw: _positiveInt(json['diaKrw']),
    );
  }
}

int? _readInt(Object? value) {
  if (value is num) return value.toInt();
  return null;
}

int _positiveInt(Object? value) {
  final parsed = _readInt(value);
  if (parsed == null || parsed <= 0) return 0;
  return parsed;
}

/// Prefers the server total. Falls back to summing `prizeDiaByRank`.
int _advertisedPrizeDia(Map value) {
  if (value.containsKey('advertisedPrizeDia')) {
    return _positiveInt(value['advertisedPrizeDia']);
  }
  final ranks = value['prizeDiaByRank'];
  if (ranks is! Map) return 0;
  var sum = 0;
  for (final amount in ranks.values) {
    final dia = _readInt(amount);
    if (dia != null && dia > 0) sum += dia;
  }
  return sum;
}

Map<String, String> _tierTicketLabels(Object? viewer) {
  if (viewer is! Map) return const {};
  final raw = viewer['tierTickets'];
  if (raw is! List) return const {};
  final labels = <String, String>{};
  for (final item in raw) {
    if (item is! Map) continue;
    final tier = item['targetTier'];
    final label = item['joinLabelKo'];
    if (tier is! String || label is! String || label.isEmpty) continue;
    labels[tier.trim().toLowerCase()] = label;
  }
  return labels;
}
