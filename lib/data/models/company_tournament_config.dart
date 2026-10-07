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
    this.tierTicketJoinLabels = const {},
    this.diaKrw = 0,
  });

  final Map<String, CompanyTournamentTier> tiers;
  final bool beginnerFreeEntryEligible;
  final String? freeEntryLabelKo;
  final String? weeklyLimitLabelKo;
  final String? prizeIneligibleReasonKo;
  final Map<String, String> tierTicketJoinLabels;

  /// Won per 1 DIA from the same config payload. 0 until the server sends it.
  final int diaKrw;

  CompanyTournamentTier? tier(String id) => tiers[id.trim().toLowerCase()];

  String? tierTicketJoinLabel(String tierId) {
    final label = tierTicketJoinLabels[tierId.trim().toLowerCase()];
    if (label == null || label.isEmpty) return null;
    return label;
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
