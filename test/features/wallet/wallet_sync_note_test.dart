import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_sync_provider.dart';
import 'package:share_run_challenge/features/wallet/widgets/wallet_sync_note.dart';

Future<void> _pump(WidgetTester tester, {required bool confirmed}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [walletServerConfirmedProvider.overrideWithValue(confirmed)],
      child: MaterialApp(
        theme: SrcTheme.night,
        home: const Scaffold(body: WalletSyncNote()),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a note while the balance is not server confirmed',
      (tester) async {
    await _pump(tester, confirmed: false);
    expect(find.byKey(const Key('wallet-unconfirmed-note')), findsOneWidget);
  });

  testWidgets('shows nothing once the server confirmed the balance',
      (tester) async {
    await _pump(tester, confirmed: true);
    expect(find.byKey(const Key('wallet-unconfirmed-note')), findsNothing);
  });
}
