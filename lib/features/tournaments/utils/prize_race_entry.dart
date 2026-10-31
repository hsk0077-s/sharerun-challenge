import '../../../data/models/company_tournament_config.dart';
import '../../../data/models/tournament_model.dart';
import '../../../l10n/remaining_surface.dart';

/// Server config cost for a company prize race. Null when the room is not one.
class PrizeRaceQuote {
  const PrizeRaceQuote._({
    required this.ready,
    required this.pending,
    required this.entryShare,
    required this.ticketCost,
    this.freeEntryLabel,
    this.rulesLabel,
    this.tierTicketJoinLabel,
  });

  final bool ready;
  final bool pending;
  final int entryShare;
  final int ticketCost;
  final String? freeEntryLabel;
  final String? rulesLabel;
  final String? tierTicketJoinLabel;

  bool canUseTickets(int held) =>
      ready && entryShare > 0 && ticketCost > 0 && held >= ticketCost;

  String costLabel(int held) {
    if (pending) {
      return RemainingSurface.trNow(
        'tournaments.prize_race_entry.body',
        '참가비 확인 중',
      );
    }
    if (!ready) {
      return RemainingSurface.trNow(
        'tournaments.prize_race_entry.body.2',
        '참가비를 불러오지 못했습니다',
      );
    }
    var base = switch ((entryShare <= 0, ticketCost <= 0)) {
      (true, true) => RemainingSurface.trNow(
          'tournaments.prize_race_entry.body.3',
          '무료 참가',
        ),
      (false, true) => '$entryShare SHARE',
      (true, false) => RemainingSurface.trNow(
          'tournaments.prize_race_entry.body.4',
          '무료 참가권 $ticketCost장',
          {'ticketCost': ticketCost},
        ),
      (false, false) => RemainingSurface.trNow(
          'tournaments.prize_race_entry.body.5',
          '$entryShare SHARE 또는 무료 참가권 $ticketCost장',
          {'entryShare': entryShare, 'ticketCost': ticketCost},
        ),
    };
    if (freeEntryLabel != null) {
      base = '$base · $freeEntryLabel';
    }
    if (ticketCost <= 0) return base;
    return RemainingSurface.trNow(
      'tournaments.prize_race_entry.body.6',
      '$base · 보유 $held장',
      {'base': base, 'held': held},
    );
  }

  String get shareJoinLabel {
    if (pending) {
      return RemainingSurface.trNow(
        'tournaments.prize_race_entry.body',
        '참가비 확인 중',
      );
    }
    if (!ready) {
      return RemainingSurface.trNow(
        'tournaments.prize_race_entry.body.2',
        '참가비를 불러오지 못했습니다',
      );
    }
    if (freeEntryLabel != null) {
      return RemainingSurface.trNow(
        'tournaments.prize_race_entry.body.7',
        '$freeEntryLabel로 참가',
        {'freeEntryLabel': freeEntryLabel},
      );
    }
    if (entryShare <= 0) {
      return RemainingSurface.trNow(
        'tournaments.prize_race_entry.body.3',
        '무료 참가',
      );
    }
    return RemainingSurface.trNow(
      'tournaments.prize_race_entry.body.8',
      '$entryShare SHARE로 참가',
      {'entryShare': entryShare},
    );
  }

  String get ticketJoinLabel => RemainingSurface.trNow(
        'tournaments.prize_race_entry.body.9',
        '무료 참가권 $ticketCost장으로 참가',
        {'ticketCost': ticketCost},
      );
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
  final readyConfig = config;
  final tier = readyConfig?.tier(tournament.prizeTier);
  if (readyConfig == null || tier == null) {
    return const PrizeRaceQuote._(
      ready: false,
      pending: false,
      entryShare: 0,
      ticketCost: 0,
    );
  }
  final beginner = tournament.prizeTier.trim().toLowerCase() == 'beginner';
  return PrizeRaceQuote._(
    ready: true,
    pending: false,
    entryShare: tier.entryShare,
    ticketCost: tier.freeTicketCost,
    freeEntryLabel: beginner && readyConfig.beginnerFreeEntryEligible
        ? readyConfig.freeEntryLabelKo
        : null,
    rulesLabel: _rulesLabel(readyConfig),
    tierTicketJoinLabel: readyConfig.tierTicketJoinLabel(tournament.prizeTier),
  );
}

String? _rulesLabel(CompanyTournamentConfig config) {
  final parts = <String>[
    if (config.weeklyLimitLabelKo != null) config.weeklyLimitLabelKo!,
    if (config.prizeIneligibleReasonKo != null) config.prizeIneligibleReasonKo!,
  ];
  if (parts.isEmpty) return null;
  return parts.join(' ');
}

/// Home-card fee. Prize races use the server config, never the room document.
String prizeRaceHomeFeeLine({
  required TournamentModel tournament,
  required bool configLoading,
  required CompanyTournamentConfig? config,
}) {
  final distance = '${tournament.targetDistanceKm.toStringAsFixed(1)}km';
  final quote = resolvePrizeRaceQuote(
    tournament: tournament,
    configLoading: configLoading,
    config: config,
  );
  if (quote == null) {
    return '$distance · ${tournament.entryFeeShare} SHARE';
  }
  if (!quote.ready) return '$distance · ${quote.costLabel(0)}';
  final fee = quote.freeEntryLabel == null
      ? '${quote.entryShare} SHARE'
      : '${quote.entryShare} SHARE · ${quote.freeEntryLabel}';
  return '$distance · $fee';
}
