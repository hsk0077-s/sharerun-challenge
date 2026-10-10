import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/donation/today_donation.dart';
import 'package:share_run_challenge/features/home/home_cards.dart';
import 'package:share_run_challenge/features/profile/widgets/retention_widgets.dart';

Widget _host(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: SrcTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Map<String, dynamic> _row(DateTime at, int won) => {
      'createdAt': Timestamp.fromDate(at),
      'companyWon': won,
    };

void main() {
  group('hero numbers', () {
    test('pending and received come only from steps and the claimed watermark',
        () {
      final n = HomeHeroNumbers.from(steps: 2500, claimed: 1000);
      expect(n.pendingShare, 150); // 1,500 steps / 10
      expect(n.receivedShare, 100);
      expect(n.steps, 2500);
    });

    test('the daily SHARE cap and a negative step count are respected', () {
      final capped = HomeHeroNumbers.from(steps: 20000, claimed: 0);
      expect(capped.pendingShare, 600);
      expect(capped.progress, 1.0);
      final odd = HomeHeroNumbers.from(steps: -5, claimed: 0);
      expect(odd.steps, 0);
      expect(odd.pendingShare, 0);
    });
  });

  group('today donation', () {
    // 2026-10-10 12:00 in Seoul = 03:00 UTC.
    final now = DateTime.utc(2026, 10, 10, 3);

    test('sums only today (KST) rows from the server ledger', () {
      final rows = [
        _row(DateTime.utc(2026, 10, 10, 1), 100),
        _row(DateTime.utc(2026, 10, 9, 14, 59), 900), // 23:59 KST on the 9th
        _row(DateTime.utc(2026, 10, 9, 15, 0), 250), // 00:00 KST on the 10th
        {'companyWon': 70}, // no timestamp yet
      ];
      expect(todayWonFrom(rows, now: now), 350);
    });

    test('ignores bad amounts', () {
      final at = DateTime.utc(2026, 10, 10, 1);
      expect(
        todayWonFrom([
          {'createdAt': Timestamp.fromDate(at), 'companyWon': -5},
          {'createdAt': Timestamp.fromDate(at), 'companyWon': 'x'},
        ], now: now),
        0,
      );
    });
  });

  group('diamond card', () {
    const split = WalletModel(
      shareBalance: 0,
      diamondBalance: 1250,
      valueTokenBalance: 0,
      totalDonationValue: 0,
      freeDiamondBalance: 250,
      paidDiamondBalance: 1000,
    );

    testWidgets('shows the total, then bonus and paid when opened',
        (tester) async {
      var store = 0;
      await tester.pumpWidget(
        _host(HomeDiamondCard(wallet: split, onOpenStore: () => store++)),
      );
      expect(find.text('1,250 DIA'), findsOneWidget);
      expect(find.byKey(HomeDiamondCard.bonusKey), findsNothing);

      await tester.tap(find.byKey(HomeDiamondCard.toggleKey));
      await tester.pump();
      expect(find.text('250'), findsOneWidget);
      expect(find.text('1,000'), findsOneWidget);
      expect(find.text('먼저 사용'), findsOneWidget);
      expect(find.textContaining('환불은 결제 다이아 기준'), findsOneWidget);

      await tester.tap(find.byKey(HomeDiamondCard.storeKey));
      expect(store, 1);
    });

    testWidgets('does not split when the server split does not add up',
        (tester) async {
      const odd = WalletModel(
        shareBalance: 0,
        diamondBalance: 100,
        valueTokenBalance: 0,
        totalDonationValue: 0,
        freeDiamondBalance: 10,
        paidDiamondBalance: 10,
      );
      await tester.pumpWidget(
        _host(HomeDiamondCard(wallet: odd, onOpenStore: () {})),
      );
      await tester.tap(find.byKey(HomeDiamondCard.toggleKey));
      await tester.pump();
      expect(find.byKey(HomeDiamondCard.bonusKey), findsNothing);
      expect(find.byKey(HomeDiamondCard.paidKey), findsNothing);
      expect(find.text('100 DIA'), findsOneWidget);
    });
  });

  group('donation card', () {
    Widget card(Future<TodayDonation> Function() load) => _host(
          HomeDonationCard(onOpenSettlement: () {}),
          overrides: [
            todayDonationLoaderProvider.overrideWithValue(load),
          ],
        );

    testWidgets('shows today\'s server amount and the company wording',
        (tester) async {
      await tester.pumpWidget(
        card(() async => const TodayDonation(todayWon: 1200, capReached: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('1,200원'), findsOneWidget);
      expect(find.byKey(HomeDonationCard.capKey), findsNothing);
      expect(find.textContaining('회사·스폰서 이름으로 100원'), findsOneWidget);
    });

    testWidgets('says the goal is reached and handles no donation yet',
        (tester) async {
      await tester.pumpWidget(
        card(() async => const TodayDonation(todayWon: 0, capReached: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('오늘은 아직 기여가 없어요'), findsOneWidget);
      expect(find.text(HomeDonationCard.capReachedLine), findsOneWidget);
    });

    testWidgets('never names a beneficiary or says the user paid',
        (tester) async {
      await tester.pumpWidget(
        card(() async => const TodayDonation(todayWon: 500, capReached: false)),
      );
      await tester.pumpAndSettle();
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      for (final banned in ['UNICEF', '유니세프', '영수증', '세금', '완벽', '내 이름으로']) {
        expect(text.contains(banned), isFalse, reason: banned);
      }
    });

    testWidgets('a failed read can be retried', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        card(() async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return const TodayDonation(todayWon: 300, capReached: false);
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(HomeDonationCard.retryKey), findsOneWidget);

      await tester.tap(find.byKey(HomeDonationCard.retryKey));
      await tester.pumpAndSettle();
      expect(find.text('300원'), findsOneWidget);
    });
  });
}
