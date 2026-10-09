import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/donation/donation_settlement.dart';
import 'package:share_run_challenge/screens/donation_settlement_screen.dart';

Widget _app(DonationSettlementLoader loader) {
  return ProviderScope(
    overrides: [donationSettlementLoaderProvider.overrideWithValue(loader)],
    child: const MaterialApp(home: DonationSettlementScreen()),
  );
}

Iterable<String> _allText(WidgetTester tester) {
  return tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '');
}

void main() {
  test('month doc gives the total and the server cap, a missing doc gives 0', () {
    final data = settlementFrom(
      myTotalWon: 3200,
      monthDoc: {'totalWon': 400, 'capWon': 1000000},
    );
    expect(data.myTotalWon, 3200);
    expect(data.monthTotalWon, 400);
    expect(data.monthCapWon, 1000000);
    expect(data.capReached, isFalse);

    final empty = settlementFrom(myTotalWon: 0);
    expect(empty.monthTotalWon, 0);
    expect(empty.capReached, isFalse);

    expect(
      settlementFrom(
        myTotalWon: 10,
        monthDoc: {'totalWon': 1000, 'capWon': 1000},
      ).capReached,
      isTrue,
    );
    expect(
      settlementFrom(myTotalWon: -5, monthDoc: {'totalWon': 'x'}).myTotalWon,
      0,
    );
  });

  test('month key is the KST month', () {
    // 2026-09-30 16:00 UTC is already 10-01 01:00 in Seoul.
    expect(donationMonthKey(DateTime.utc(2026, 9, 30, 16)), '2026-10');
    expect(donationMonthKey(DateTime.utc(2026, 10, 15)), '2026-10');
  });

  testWidgets('shows my contribution and this month, with the company wording',
      (tester) async {
    await tester.pumpWidget(
      _app(() async => const DonationSettlement(
            myTotalWon: 12500,
            monthTotalWon: 480000,
            monthCapWon: 1000000,
          )),
    );
    await tester.pumpAndSettle();

    expect(find.text(DonationSettlementScreen.intro), findsOneWidget);
    expect(find.text('12,500원'), findsOneWidget);
    expect(find.text('480,000원'), findsOneWidget);
    expect(find.text('이번 달 한도 1,000,000원'), findsOneWidget);
    expect(find.text(DonationSettlementScreen.capReachedLine), findsNothing);
  });

  testWidgets('says the monthly goal is reached when the cap is used up',
      (tester) async {
    await tester.pumpWidget(
      _app(() async => const DonationSettlement(
            myTotalWon: 100,
            monthTotalWon: 1000000,
            monthCapWon: 1000000,
          )),
    );
    await tester.pumpAndSettle();

    expect(find.text(DonationSettlementScreen.capReachedLine), findsOneWidget);
  });

  testWidgets('never names a beneficiary, a receipt, or claims the user paid',
      (tester) async {
    await tester.pumpWidget(
      _app(() async => const DonationSettlement(
            myTotalWon: 100,
            monthTotalWon: 100,
            monthCapWon: 1000000,
          )),
    );
    await tester.pumpAndSettle();

    final text = _allText(tester).join('\n');
    for (final banned in ['UNICEF', '유니세프', '영수증', '세금', '공제', '완벽', '내 이름으로']) {
      expect(text.contains(banned), isFalse, reason: banned);
    }
    expect(text, contains('회사·스폰서'));
  });

  testWidgets('a failed load can be retried', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(() async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return const DonationSettlement(
          myTotalWon: 700,
          monthTotalWon: 0,
          monthCapWon: 0,
        );
      }),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(DonationSettlementScreen.retryKey), findsOneWidget);

    await tester.tap(find.byKey(DonationSettlementScreen.retryKey));
    await tester.pumpAndSettle();

    expect(find.text('700원'), findsOneWidget);
    expect(find.byKey(DonationSettlementScreen.retryKey), findsNothing);
  });
}
