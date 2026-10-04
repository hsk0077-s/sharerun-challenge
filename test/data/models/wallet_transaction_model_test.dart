import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/wallet_transaction_model.dart';

void main() {
  group('WalletTransactionModel', () {
    test('maps known transaction types to Korean labels', () {
      const transaction = WalletTransactionModel(
        id: 'tx-1',
        type: 'share_top_up',
        shareAmount: 10000,
        valueAmount: 0,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: null,
      );

      expect(transaction.displayLabel, 'Share 충전');
      expect(transaction.amountSummary, '+10000 Share');
    });

    test('builds multi-currency amount summary', () {
      const transaction = WalletTransactionModel(
        id: 'tx-2',
        type: 'winner_reward_donate_half',
        shareAmount: 0,
        valueAmount: -250,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: 'tournament-1',
      );

      expect(transaction.amountSummary, '-250 Value');
    });
    test('shows debit amounts for tournament entry', () {
      const transaction = WalletTransactionModel(
        id: 'tx-3',
        type: 'tournament_entry',
        shareAmount: 100,
        valueAmount: 0,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: 'tournament-1',
      );

      expect(transaction.amountSummary, '-100 Share');
    });

    test('maps personal sponsor debits to Korean labels', () {
      const donation = WalletTransactionModel(
        id: 'tx-sponsor',
        type: 'personal_sponsor_donation',
        shareAmount: -50000,
        valueAmount: 0,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: null,
      );
      expect(donation.displayLabel, '유니세프 기부 완료');
      expect(donation.amountSummary, '-50000 Share');

      const prize = WalletTransactionModel(
        id: 'tx-prize',
        type: 'personal_sponsor_prize',
        shareAmount: -50000,
        valueAmount: 0,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: null,
      );
      expect(prize.displayLabel, '챌린지 상금 지원 후원');
      expect(prize.amountSummary, '-50000 Share');
    });

    test('maps pedometer harvest to walking-challenge pickup label', () {
      const transaction = WalletTransactionModel(
        id: 'tx-4',
        type: 'pedometer_harvest',
        shareAmount: 20,
        valueAmount: 0,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: null,
      );

      expect(transaction.displayLabel, '워킹챌린지 코인 줍기');
      expect(transaction.amountSummary, '+20 Share');
    });

    test('maps value item spends without treating them as cash', () {
      const rest = WalletTransactionModel(
        id: 'tx-rest',
        type: 'shop_purchase',
        shareAmount: 0,
        valueAmount: -50,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: null,
        itemId: 'rest_day_ticket',
      );
      const match = WalletTransactionModel(
        id: 'tx-match',
        type: 'donation_match',
        shareAmount: 0,
        valueAmount: -100,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: null,
      );

      expect(rest.displayLabel, '휴식일 지정권');
      expect(rest.amountSummary, '-50 Value');
      expect(match.displayLabel, '기부 매칭권');
      expect(match.amountSummary, '-100 Value');
    });

    test('maps incubator hatch to a credit label', () {
      const transaction = WalletTransactionModel(
        id: 'tx-hatch',
        type: 'step_incubator_hatch',
        shareAmount: 500,
        valueAmount: 0,
        diamondAmount: 0,
        createdAt: null,
        tournamentId: null,
      );

      expect(transaction.displayLabel, '만보기 부화');
      expect(transaction.amountSummary, '+500 Share');
    });

    test('maps debug 1M test grant label', () {
      const transaction = WalletTransactionModel(
        id: 'tx-5',
        type: 'debug_test_grant_1m',
        shareAmount: 1000000,
        valueAmount: 1000000,
        diamondAmount: 1000000,
        createdAt: null,
        tournamentId: null,
      );

      expect(transaction.displayLabel, '디버그 테스트 지급');
    });
  });
}
