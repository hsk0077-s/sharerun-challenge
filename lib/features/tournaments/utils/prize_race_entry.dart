import '../../../data/models/company_tournament_config.dart';
import '../../../data/models/tournament_model.dart';

/// Server config cost for a company prize race. Null when the room is not one.
class PrizeRaceQuote {
  const PrizeRaceQuote._({
    required this.ready,
    required this.pending,
    required this.entryShare,
    required this.ticketCost,
  });

  final bool ready;
  final bool pending;
  final int entryShare;
  final int ticketCost;

  bool canUseTickets(int held) =>
      ready && entryShare > 0 && ticketCost > 0 && held >= ticketCost;

  String costLabel(int held) {
    if (pending) return '참가비 확인 중';
    if (!ready) return '참가비를 불러오지 못했습니다';
    final String base;
    if (entryShare <= 0 && ticketCost <= 0) {
      base = '무료 참가';
    } else if (ticketCost <= 0) {
      base = '$entryShare SHARE';
    } else if (entryShare <= 0) {
      base = '무료 참가권 $ticketCost장';
    } else {
      base = '$entryShare SHARE 또는 무료 참가권 $ticketCost장';
    }
    if (ticketCost <= 0) return base;
    return '$base · 보유 $held장';
  }

  String get shareJoinLabel {
    if (pending) return '참가비 확인 중';
    if (!ready) return '참가비를 불러오지 못했습니다';
    if (entryShare <= 0) return '무료 참가';
    return '$entryShare SHARE로 참가';
  }

  String get ticketJoinLabel => '무료 참가권 $ticketCost장으로 참가';
}

PrizeRaceQuote? resolvePrizeRaceQuote({
  required TournamentModel tournament,
  required bool configLoading,
  required CompanyTournamentConfig? config,
}) {
  if (!tournament.isPrizeRace) return null;
  if (configLoading) {
    return const PrizeRaceQuote._(
      ready: false,
      pending: true,
      entryShare: 0,
      ticketCost: 0,
    );
  }
  final tier = config?.tier(tournament.prizeTier);
  if (tier == null) {
    return const PrizeRaceQuote._(
      ready: false,
      pending: false,
      entryShare: 0,
      ticketCost: 0,
    );
  }
  return PrizeRaceQuote._(
    ready: true,
    pending: false,
    entryShare: tier.entryShare,
    ticketCost: tier.freeTicketCost,
  );
}
