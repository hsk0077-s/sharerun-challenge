import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/share_to_dia_view.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/features/wallet/share_to_dia_actions.dart';
import 'package:share_run_challenge/screens/share_dia_exchange_screen.dart';
import 'package:share_run_challenge/screens/snail_to_cheetah_book_page.dart';
import 'package:share_run_challenge/screens/watch_connection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/ko_localization.dart';

const _height = 800.0;

/// A 3-button Android navigation bar reports itself as bottom view padding.
const _navBar = 48.0;

void _phoneWithNavBar(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, _height);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: _navBar);
  tester.view.viewPadding = const FakeViewPadding(bottom: _navBar);
  addTearDown(tester.view.reset);
}

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

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tier book: the unrated guide button sits above the nav bar',
      (tester) async {
    _phoneWithNavBar(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: SnailToCheetahBookPage()),
      ),
    );
    await tester.pump();

    final button = find.byKey(const Key('tier-book-go-run'));
    expect(button, findsOneWidget);
    expect(
      tester.getBottomLeft(button).dy,
      lessThanOrEqualTo(_height - _navBar),
    );
  });

  testWidgets('push prompt sheet: both buttons sit above the nav bar',
      (tester) async {
    _phoneWithNavBar(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: koTestLocale,
        supportedLocales: koTestSupportedLocales,
        localizationsDelegates: koTestDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const PushSoftPromptSheet(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    for (final label in ['알림 허용하고 계속', '나중에']) {
      final button = find.text(label);
      expect(button, findsOneWidget, reason: label);
      expect(
        tester.getBottomLeft(button).dy,
        lessThanOrEqualTo(_height - _navBar),
        reason: label,
      );
    }
  });

  testWidgets('SHARE to DIA: a server refusal shows the user line, not the raw '
      'server text', (tester) async {
    const quote = ShareToDiaView(
      status: 'quote',
      rateSharePerDia: 120,
      unitDia: 10,
      weeklyCapDia: 20,
      remainingDia: 20,
      spendableShare: 5000,
      lockedShare: 0,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith(_SpyWallet.new),
          shareToDiaQuoteProvider.overrideWith((ref) => () async => quote),
          shareToDiaExchangeProvider.overrideWith((ref) {
            return (dia) async => throw const ApiException(
                  statusCode: 400,
                  detail: 'Insufficient Share balance.',
                );
          }),
        ],
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const ShareDiaExchangeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '교환'));
    await tester.pump();
    await tester.pump();

    expect(find.text('SHARE가 부족합니다.'), findsOneWidget);
    expect(find.textContaining('Insufficient'), findsNothing);
  });
}
