/// `GET /actions/company-tournament/config`. Fees come from this payload.
class CompanyTournamentTier {
  const CompanyTournamentTier({
    required this.entryShare,
    required this.freeTicketCost,
  });

  final int entryShare;
  final int freeTicketCost;
}

class CompanyTournamentConfig {
  const CompanyTournamentConfig({
    required this.tiers,
    this.beginnerFreeEntryEligible = false,
    this.freeEntryLabelKo,
    this.weeklyLimitLabelKo,
    this.prizeIneligibleReasonKo,
    this.tierTicketJoinLabels = const {},
  });

  final Map<String, CompanyTournamentTier> tiers;
  final bool beginnerFreeEntryEligible;
  final String? freeEntryLabelKo;
  final String? weeklyLimitLabelKo;
  final String? prizeIneligibleReasonKo;
  final Map<String, String> tierTicketJoinLabels;

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
      freeEntryLabelKo: freeLabel is String && freeLabel.isNotEmpty
          ? freeLabel
          : null,
      weeklyLimitLabelKo: weekLabel is String && weekLabel.isNotEmpty
          ? weekLabel
          : null,
      prizeIneligibleReasonKo: claimLabel is String && claimLabel.isNotEmpty
          ? claimLabel
          : null,
      tierTicketJoinLabels: _tierTicketLabels(viewer),
    );
  }
}

int? _readInt(Object? value) {
  if (value is num) return value.toInt();
  return null;
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
