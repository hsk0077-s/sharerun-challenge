import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/company_tournament_config.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/features/tournaments/utils/prize_display.dart';
import 'package:share_run_challenge/features/tournaments/utils/prize_race_entry.dart';

TournamentModel _race(String tier) {
  return TournamentModel.fromJson(
    id: 'race',
    json: {
      'title': tier,
      'prizeTier': tier,
      'entryFeeShare': 99999,
      'targetDistanceKm': 3,
      'status': 'recruiting',
    },
  );
}

void main() {
  test('reads SHARE and ticket costs from the server config', () {
    const config = CompanyTournamentConfig(
      tiers: {
        'beginner': CompanyTournamentTier(entryShare: 600, freeTicketCost: 1),
        'half': CompanyTournamentTier(entryShare: 4200, freeTicketCost: 3),
        'final': CompanyTournamentTier(entryShare: 0, freeTicketCost: 0),
      },
    );

    final beginner = resolvePrizeRaceQuote(
      tournament: _race('beginner'),
      configLoading: false,
      config: config,
    )!;
    expect(beginner.entryShare, 600);
    expect(beginner.ticketCost, 1);
    expect(beginner.costLabel(1), '600 SHARE 또는 무료 참가권 1장 · 보유 1장');
    expect(beginner.canUseTickets(1), isTrue);
    expect(beginner.canUseTickets(0), isFalse);
    expect(beginner.shareJoinLabel, '600 SHARE로 참가');

    final half = resolvePrizeRaceQuote(
      tournament: _race('half'),
      configLoading: false,
      config: config,
    )!;
    expect(half.canUseTickets(2), isFalse);
    expect(half.canUseTickets(3), isTrue);
    expect(half.ticketJoinLabel, '무료 참가권 3장으로 참가');

    final finalRace = resolvePrizeRaceQuote(
      tournament: _race('final'),
      configLoading: false,
      config: config,
    )!;
    expect(finalRace.shareJoinLabel, '무료 참가');
    expect(finalRace.canUseTickets(3), isFalse);
    expect(finalRace.costLabel(1), '무료 참가');
  });

  test('a normal room keeps the document fee path', () {
    final room = TournamentModel.fromJson(
      id: 'room',
      json: {
        'title': 'room',
        'entryFeeShare': 30000,
        'targetDistanceKm': 1,
        'status': 'recruiting',
      },
    );
    expect(
      resolvePrizeRaceQuote(
        tournament: room,
        configLoading: false,
        config: const CompanyTournamentConfig(tiers: {}),
      ),
      isNull,
    );
  });

  test('free entry and limits appear only from the server payload', () {
    const hidden = CompanyTournamentConfig(
      tiers: {
        'beginner': CompanyTournamentTier(entryShare: 300, freeTicketCost: 1),
        'mid': CompanyTournamentTier(entryShare: 1200, freeTicketCost: 1),
      },
      weeklyLimitLabelKo: '같은 등급은 일주일에 1번만 참가할 수 있어요.',
      prizeIneligibleReasonKo: '본인인증된 계정이 아니라 다이아 상금을 받을 수 없어요.',
    );
    final closed = resolvePrizeRaceQuote(
      tournament: _race('beginner'),
      configLoading: false,
      config: hidden,
    )!;
    expect(closed.entryShare, 300);
    expect(closed.freeEntryLabel, isNull);
    expect(closed.costLabel(0), '300 SHARE 또는 무료 참가권 1장 · 보유 0장');
    expect(closed.shareJoinLabel, '300 SHARE로 참가');
    expect(closed.rulesLabel, contains('일주일에 1번'));
    expect(closed.rulesLabel, contains('본인인증'));

    const open = CompanyTournamentConfig(
      tiers: {
        'beginner': CompanyTournamentTier(entryShare: 111, freeTicketCost: 1),
      },
      beginnerFreeEntryEligible: true,
      freeEntryLabelKo: '첫 2회 무료',
    );
    final eligible = resolvePrizeRaceQuote(
      tournament: _race('beginner'),
      configLoading: false,
      config: open,
    )!;
    expect(eligible.entryShare, 111);
    expect(eligible.freeEntryLabel, '첫 2회 무료');
    expect(eligible.costLabel(1), contains('첫 2회 무료'));
    expect(eligible.shareJoinLabel, '첫 2회 무료로 참가');

    final home = prizeRaceHomeFeeLine(
      tournament: _race('beginner'),
      configLoading: false,
      config: open,
    );
    expect(home, contains('첫 2회 무료'));
    expect(home, isNot(contains('99999')));

    final midHome = prizeRaceHomeFeeLine(
      tournament: _race('mid'),
      configLoading: false,
      config: hidden,
    );
    expect(midHome, contains('1200 SHARE'));
    expect(midHome, isNot(contains('첫 2회 무료')));
  });

  test('missing config does not invent a zero fee', () {
    final pending = resolvePrizeRaceQuote(
      tournament: _race('mid'),
      configLoading: true,
      config: null,
    )!;
    expect(pending.ready, isFalse);
    expect(pending.costLabel(0), '참가비 확인 중');

    final missing = resolvePrizeRaceQuote(
      tournament: _race('mid'),
      configLoading: false,
      config: const CompanyTournamentConfig(tiers: {}),
    )!;
    expect(missing.ready, isFalse);
    expect(missing.shareJoinLabel, '참가비를 불러오지 못했습니다');
    expect(missing.canUseTickets(5), isFalse);
  });

  test('tier ticket join label comes from the server and has no won value', () {
    final config = CompanyTournamentConfig.fromJson({
      'tiers': {
        'mid': {'entryShare': 1200, 'freeTicketCost': 1},
      },
      'viewer': {
        'tierTickets': [
          {'targetTier': 'mid', 'joinLabelKo': '중급 참가권으로 참가'},
        ],
      },
    });
    final quote = resolvePrizeRaceQuote(
      tournament: _race('mid'),
      configLoading: false,
      config: config,
    )!;
    expect(quote.tierTicketJoinLabel, '중급 참가권으로 참가');
    expect(quote.tierTicketJoinLabel, isNot(contains('원')));
    expect(quote.costLabel(0), isNot(contains('원')));
  });

  test('prize copy uses the server DIA total and won rate', () {
    final config = CompanyTournamentConfig.fromJson({
      'diaKrw': 100,
      'tiers': {
        'beginner': {
          'entryShare': 300,
          'freeTicketCost': 1,
          'prizeDiaByRank': {'1': 1000, '2': 500, '3': 300},
        },
      },
    });
    expect(config.diaKrw, 100);
    expect(config.tier('beginner')!.advertisedPrizeDia, 1800);
    expect(
      prizePoolLine(
        room: _race('beginner'),
        configLoading: false,
        config: config,
      ),
      '18만 원 상당 다이아',
    );

    final advertised = CompanyTournamentConfig.fromJson({
      'diaKrw': 100,
      'tiers': {
        'mid': {
          'entryShare': 1200,
          'freeTicketCost': 1,
          'advertisedPrizeDia': 7200,
          'prizeDiaByRank': {'1': 1},
        },
      },
    });
    expect(
      prizePoolLine(
        room: _race('mid'),
        configLoading: false,
        config: advertised,
      ),
      '72만 원 상당 다이아',
    );
  });

  test('a missing won rate does not invent a prize amount', () {
    final config = CompanyTournamentConfig.fromJson({
      'tiers': {
        'beginner': {
          'entryShare': 300,
          'freeTicketCost': 1,
          'advertisedPrizeDia': 1800,
        },
      },
    });
    expect(
      prizePoolLine(
        room: _race('beginner'),
        configLoading: false,
        config: config,
      ),
      '상금을 불러오지 못했어요',
    );
    expect(
      prizePoolLine(
        room: _race('beginner'),
        configLoading: true,
        config: null,
      ),
      '상금을 확인하는 중이에요',
    );
  });
}
