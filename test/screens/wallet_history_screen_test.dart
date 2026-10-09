import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/wallet_transaction_model.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_history_provider.dart';
import 'package:share_run_challenge/screens/wallet_history_screen.dart';

WalletTransactionModel _row(String id, String type, {int share = 0, int dia = 0}) {
  return WalletTransactionModel(
    id: id,
    type: type,
    shareAmount: share,
    valueAmount: 0,
    diamondAmount: dia,
    createdAt: DateTime(2026, 10, 6, 9, 30),
    tournamentId: null,
  );
}

Widget _app(WalletHistoryLoader loader) {
  return ProviderScope(
    overrides: [walletHistoryLoaderProvider.overrideWithValue(loader)],
    child: const MaterialApp(home: WalletHistoryScreen()),
  );
}

void main() {
  testWidgets('shows ledger rows and loads the next page on demand',
      (tester) async {
    final cursors = <Object?>[];
    Future<WalletHistoryPage> loader({Object? cursor}) async {
      cursors.add(cursor);
      if (cursor == null) {
        return WalletHistoryPage(
          rows: [_row('a', 'share_to_dia', share: -1200, dia: 1)],
          cursor: 'page-1',
          hasMore: true,
        );
      }
      return WalletHistoryPage(
        rows: [_row('b', 'streak_bonus', dia: 10)],
        cursor: 'page-2',
        hasMore: false,
      );
    }

    await tester.pumpWidget(_app(loader));
    await tester.pumpAndSettle();

    expect(find.text('SHARE → 다이아 전환'), findsOneWidget);
    expect(find.text('-1200 Share · +1 Diamond'), findsOneWidget);
    expect(find.byKey(WalletHistoryScreen.moreButtonKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(WalletHistoryScreen.moreButtonKey));
    await tester.tap(find.byKey(WalletHistoryScreen.moreButtonKey));
    await tester.pumpAndSettle();

    expect(cursors, [null, 'page-1']);
    expect(find.text('연속 달리기 보너스'), findsOneWidget);
    expect(find.byKey(WalletHistoryScreen.moreButtonKey), findsNothing);
  });

  testWidgets('a failed load can be retried', (tester) async {
    var calls = 0;
    Future<WalletHistoryPage> loader({Object? cursor}) async {
      calls++;
      if (calls == 1) throw StateError('offline');
      return WalletHistoryPage(
        rows: [_row('a', 'streak_bonus', dia: 10)],
        cursor: null,
        hasMore: false,
      );
    }

    await tester.pumpWidget(_app(loader));
    await tester.pumpAndSettle();
    expect(find.byKey(WalletHistoryScreen.retryButtonKey), findsOneWidget);

    await tester.tap(find.byKey(WalletHistoryScreen.retryButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('연속 달리기 보너스'), findsOneWidget);
    expect(find.byKey(WalletHistoryScreen.retryButtonKey), findsNothing);
  });

  testWidgets('an empty ledger shows the empty message', (tester) async {
    await tester.pumpWidget(
      _app(({Object? cursor}) async =>
          const WalletHistoryPage(rows: [], cursor: null, hasMore: false)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(WalletHistoryScreen.moreButtonKey), findsNothing);
  });

  test('negative ledger share is shown as a debit with a readable label', () {
    final row = _row('x', 'share_to_dia', share: -1200);
    expect(row.displayLabel, 'SHARE → 다이아 전환');
    expect(row.amountSummary, '-1200 Share');
    expect(_row('y', 'share_top_up', share: 500).amountSummary, '+500 Share');
  });
}
