import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/share_to_dia_view.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/features/wallet/share_to_dia_actions.dart';
import 'package:share_run_challenge/screens/share_dia_exchange_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpyWallet extends WalletNotifier {
  @override
  WalletState build() => const WalletState();

  @override
  void applyWalletSnapshot({
    int? shareBalance,
    int? diamondBalance,
    int? valueBalance,
  }) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows rate, weekly cap, and lock reason without exchanging',
      (tester) async {
    var exchangeCalls = 0;
    const quote = ShareToDiaView(
      status: 'quote',
      rateSharePerDia: 120,
      unitDia: 10,
      weeklyCapDia: 20,
      remainingDia: 20,
      spendableShare: 0,
      lockedShare: 1200,
      lockReason: '추천 보상 SHARE는 받은 날부터 30일 동안 교환할 수 없습니다.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(_SpyWallet.new),
          shareToDiaQuoteProvider.overrideWith((ref) => () async => quote),
          shareToDiaExchangeProvider.overrideWith((ref) {
            return (dia) async {
              exchangeCalls++;
              return quote;
            };
          }),
        ],
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const ShareDiaExchangeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('120 SHARE = 1 DIA'), findsOneWidget);
    expect(find.text('이번 주 남은 한도 20 / 20 DIA'), findsOneWidget);
    expect(
      find.text('추천 보상 SHARE는 받은 날부터 30일 동안 교환할 수 없습니다.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '교환'));
    expect(button.onPressed, isNull);
    expect(exchangeCalls, 0);
  });
}
