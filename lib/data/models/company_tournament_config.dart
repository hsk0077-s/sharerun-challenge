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
  const CompanyTournamentConfig({required this.tiers});

  final Map<String, CompanyTournamentTier> tiers;

  CompanyTournamentTier? tier(String id) => tiers[id.trim().toLowerCase()];

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
    return CompanyTournamentConfig(tiers: tiers);
  }
}

int? _readInt(Object? value) {
  if (value is num) return value.toInt();
  return null;
}
