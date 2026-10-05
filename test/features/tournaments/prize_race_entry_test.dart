import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/company_tournament_config.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
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
}
