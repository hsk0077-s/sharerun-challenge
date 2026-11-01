import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/company_tournament_config.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

Map<String, dynamic> _json({bool structured = true}) => {
      'tiers': {
        'beginner': {'entryShare': 300, 'freeTicketCost': 1},
      },
      'viewer': {
        'beginnerFreeEntryEligible': true,
        'freeEntryLabelKo': '첫 2회 무료',
        'weeklyLimitLabelKo': '같은 등급은 일주일에 1번만 참가할 수 있어요.',
        'prizeIneligibleReason': 'account_too_new',
        'prizeIneligibleReasonKo': '가입 7일이 지나야 다이아 상금을 받을 수 있어요.',
        'tierTickets': [
          {'targetTier': 'mid', 'joinLabelKo': '중급 참가권으로 참가'},
        ],
        if (structured) ...{
          'beginnerFreeEntryCount': 2,
          'weeklyEntriesPerTier': 1,
          'prizeClaimMinAccountAgeDays': 7,
          'prizeClaimMinVerifiedRuns': 3,
          'prizeClaimVerifiedRunWindowDays': 30,
        },
      },
    };

void main() {
  final saved = RemainingSurface.currentLocale;
  tearDown(() => RemainingSurface.currentLocale = saved);

  test('Korean keeps the sentences the server sent', () {
    RemainingSurface.currentLocale = const Locale('ko');
    final c = CompanyTournamentConfig.fromJson(_json());
    expect(c.freeEntryLabel, '첫 2회 무료');
    expect(c.weeklyLimitLabel, '같은 등급은 일주일에 1번만 참가할 수 있어요.');
    expect(c.prizeIneligibleLabel, '가입 7일이 지나야 다이아 상금을 받을 수 있어요.');
    expect(c.tierTicketJoinLabel('mid'), '중급 참가권으로 참가');
  });

  test('other languages build the sentence from the numbers, with no Korean', () {
    RemainingSurface.currentLocale = const Locale('ja');
    final c = CompanyTournamentConfig.fromJson(_json());
    final all = [
      c.freeEntryLabel,
      c.weeklyLimitLabel,
      c.prizeIneligibleLabel,
      c.tierTicketJoinLabel('mid'),
    ];
    for (final text in all) {
      expect(text, isNotNull);
      expect(RegExp(r'[가-힣]').hasMatch(text!), isFalse, reason: text);
    }
    expect(c.freeEntryLabel, contains('2'));
    expect(c.prizeIneligibleLabel, contains('7'));
  });

  test('an older server without the numbers falls back to its Korean sentence', () {
    RemainingSurface.currentLocale = const Locale('ja');
    final c = CompanyTournamentConfig.fromJson(_json(structured: false));
    expect(c.freeEntryLabel, '첫 2회 무료');
    expect(c.prizeIneligibleLabel, '가입 7일이 지나야 다이아 상금을 받을 수 있어요.');
  });
}
