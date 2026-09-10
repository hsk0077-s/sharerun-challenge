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
  });
}
