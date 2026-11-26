import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/donation/donation_settlement.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
import 'package:share_run_challenge/screens/donation_settlement_screen.dart';

Widget _app(
  DonationSettlementLoader loader, {
  DonationReceiptImageBuilder? receipt,
}) {
  return ProviderScope(
    overrides: [
      donationSettlementLoaderProvider.overrideWithValue(loader),
      if (receipt != null)
        donationReceiptImageBuilderProvider.overrideWithValue(receipt),
    ],
    child: const MaterialApp(
      locale: Locale('ko', 'KR'),
      supportedLocales: ShareRunLocalizations.supportedLocales,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DonationSettlementScreen(),
    ),
  );
}

/// The screen is a lazy list; a tall view builds every block.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join('\n');

Text _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key));

DonationExecution _execution({
  String month = '2026-10',
  int amount = 150000,
  String partner = '테스트 기부처',
  String path = 'donation-receipts/2026-10/a.jpg',
}) =>
    DonationExecution(
      month: month,
      amountWon: amount,
      executedAt: DateTime(2026, 11, 3),
      partnerName: partner,
      receiptImagePath: path,
      note: '',
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('month doc gives the parts, the total and the server cap', () {
    final data = settlementFrom(
      monthDoc: {
        'totalWon': 4000,
        'capWon': 1000000,
        'stepWon': 500,
        'matchWon': 1000,
      },
    );
    expect(data.monthTotalWon, 4000);
    expect(data.monthCapWon, 1000000);
    expect(data.stepWon, 500);
    expect(data.matchWon, 1000);
    // The run part is what is left after steps and the store match.
    expect(data.runWon, 2500);
    expect(data.capReached, isFalse);

    final empty = settlementFrom();
    expect(empty.monthTotalWon, 0);
    expect(empty.monthCapWon, 0);
    expect(empty.runWon, 0);
    expect(empty.capReached, isFalse);
    expect(empty.partnerName, isNull);

    expect(
      settlementFrom(monthDoc: {'totalWon': 1000, 'capWon': 1000}).capReached,
      isTrue,
    );
    expect(settlementFrom(monthDoc: {'totalWon': 'x', 'capWon': -3}).monthTotalWon, 0);
    // A step or match part larger than the total never makes a negative run part.
    expect(
      settlementFrom(monthDoc: {'totalWon': 10, 'stepWon': 50}).runWon,
      0,
    );
  });

  test('an execution needs a positive amount; the partner comes from the newest', () {
    expect(DonationExecution.tryParse('2026-10', {'amountWon': 0}), isNull);
    expect(DonationExecution.tryParse('2026-10', null), isNull);
    final row = DonationExecution.tryParse('2026-10', {
      'amountWon': 1200,
      'executedAt': Timestamp.fromDate(DateTime(2026, 11, 3)),
      'partnerName': ' 기부처 ',
      'receiptImagePath': 'donation-receipts/2026-10/a.jpg',
    })!;
    expect(row.partnerName, '기부처');
    expect(row.executedAt, DateTime(2026, 11, 3));
    final data = settlementFrom(executions: [
      _execution(month: '2026-09', partner: '예전'),
      _execution(month: '2026-10', partner: '최근'),
    ]);
    expect(data.executions.first.month, '2026-10');
    expect(data.partnerName, '최근');
  });

  test('month key is the KST month', () {
    // 2026-09-30 16:00 UTC is already 10-01 01:00 in Seoul.
    expect(donationMonthKey(DateTime.utc(2026, 9, 30, 16)), '2026-10');
    expect(donationMonthKey(DateTime.utc(2026, 10, 15)), '2026-10');
  });

  testWidgets('shows the title, the fixed line and the month parts', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 4000,
          monthCapWon: 1000000,
          stepWon: 500,
          matchWon: 1000,
        )));
    await tester.pumpAndSettle();

    expect(_text(tester, DonationSettlementScreen.titleKey).data, '나의 활동으로 이어진 기부');
    expect(_text(tester, DonationSettlementScreen.fixedNoteKey).data,
        '기부금은 쉐어런이 부담해요. 내 돈은 나가지 않아요.');
    expect(_text(tester, DonationSettlementScreen.runKey).data, '2,500원');
    expect(_text(tester, DonationSettlementScreen.stepKey).data, '500원');
    expect(_text(tester, DonationSettlementScreen.matchKey).data, '1,000원');
    expect(_text(tester, DonationSettlementScreen.totalKey).data, '4,000원');
    expect(_text(tester, DonationSettlementScreen.statusKey).data, '기부 예정');
    expect(find.text('러닝 기부'), findsOneWidget);
    expect(find.text('걸음 기부'), findsOneWidget);
    expect(find.text('상점 매칭'), findsOneWidget);
  });

  testWidgets('there is no km gauge made from won and no personal total',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 480000,
          monthCapWon: 1000000,
        )));
    await tester.pumpAndSettle();

    final text = _allText(tester);
    expect(text.contains('4,800'), isFalse); // 480,000 won / 100 as km
    expect(text.contains('48%'), isFalse);
    expect(text.contains('내가 만든'), isFalse);
    expect(find.byKey(const Key('donation-settlement-mine')), findsNothing);
    // km is only the distance really run this month.
    expect(_text(tester, DonationSettlementScreen.kmKey).data,
        contains('이번 달 내가 달린 거리'));
  });

  testWidgets('rules show the server cap, never a fixed number', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 0,
          monthCapWon: 300000,
        )));
    await tester.pumpAndSettle();

    expect(find.text('러닝: 검증된 달리기 1km마다 100원'), findsOneWidget);
    expect(find.text('걸음: 하루 6,000보 이상이면 50원 (하루 1번)'), findsOneWidget);
    expect(find.text('한 사람이 하루에 최대 1,000원까지'), findsOneWidget);
    expect(_text(tester, DonationSettlementScreen.capKey).data, '이번 달 전체 한도: 300,000원');
    expect(find.text('1,000,000'), findsNothing);
  });

  testWidgets('without a cap in the month doc the limit is shown as not known yet',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 0,
          monthCapWon: 0,
        )));
    await tester.pumpAndSettle();

    expect(_text(tester, DonationSettlementScreen.capKey).data,
        '이번 달 전체 한도는 첫 기부가 기록되면 여기에 표시돼요.');
    expect(_allText(tester).contains('1,000,000'), isFalse);
  });

  testWidgets('says the limit is reached only when it is', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 100,
          monthCapWon: 1000000,
        )));
    await tester.pumpAndSettle();
    expect(find.byKey(DonationSettlementScreen.capLineKey), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 1000000,
          monthCapWon: 1000000,
        )));
    await tester.pumpAndSettle();
    expect(_text(tester, DonationSettlementScreen.capLineKey).data,
        '이번 달 기부 한도에 도달했어요. 이후 활동은 이번 달 기부에 더해지지 않아요.');
  });

  testWidgets('with no payment records it says so and does not claim a donation was made',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 4000,
          monthCapWon: 1000000,
        )));
    await tester.pumpAndSettle();

    expect(_text(tester, DonationSettlementScreen.execNoneKey).data,
        '아직 실제 집행 내역이 없어요. 첫 기부를 보내면 금액, 날짜, 증빙을 여기에 공개할게요.');
    expect(_text(tester, DonationSettlementScreen.partnerPendingKey).data, '기부처 선정 중');
    final text = _allText(tester);
    for (final banned in ['기부 완료', '100%', '전액', '증빙 이미지']) {
      expect(text.contains(banned), isFalse, reason: banned);
    }
  });

  testWidgets('with a record it shows the amount, date, recipient and proof',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(
      () async => DonationSettlement(
        monthTotalWon: 4000,
        monthCapWon: 1000000,
        executions: [_execution()],
      ),
      receipt: (context, path) => Text('proof:$path', key: const Key('fake-proof')),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(DonationSettlementScreen.execNoneKey), findsNothing);
    expect(find.byKey(DonationSettlementScreen.execRowKey('2026-10')), findsOneWidget);
    expect(find.text('2026-10 · 150,000원 기부 완료'), findsOneWidget);
    expect(find.text('집행일 2026-11-03'), findsOneWidget);
    expect(find.text('기부처: 테스트 기부처'), findsWidgets);
    expect(find.text('proof:donation-receipts/2026-10/a.jpg'), findsOneWidget);
    expect(find.byKey(DonationSettlementScreen.partnerPendingKey), findsNothing);
  });

  testWidgets('a record without a recipient keeps the recipient as pending',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(
      () async => DonationSettlement(
        monthTotalWon: 0,
        monthCapWon: 0,
        executions: [_execution(partner: '', path: '')],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(DonationSettlementScreen.partnerPendingKey), findsOneWidget);
    expect(find.text('증빙 이미지'), findsNothing);
  });

  testWidgets('the footer and the receipt/tax wording are always there',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 0,
          monthCapWon: 0,
        )));
    await tester.pumpAndSettle();

    expect(_text(tester, DonationSettlementScreen.footerKey).data,
        '기부금영수증과 연말정산 공제 대상이 아니에요. 기부금은 쉐어런 운영사가 다이아 상점 수익과 자체 예산으로 부담해요. 위치 정보는 판매하지 않아요.');
  });

  testWidgets('never names a beneficiary before there is a record, or says the user paid',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 100,
          monthCapWon: 1000000,
        )));
    await tester.pumpAndSettle();

    final text = _allText(tester);
    for (final banned in ['UNICEF', '유니세프', '월드비전', '초록우산', '완벽', '내 이름으로', '스폰서']) {
      expect(text.contains(banned), isFalse, reason: banned);
    }
  });

  testWidgets('no personal won amount appears anywhere on the screen', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(() async => const DonationSettlement(
          monthTotalWon: 4000,
          monthCapWon: 1000000,
          stepWon: 500,
          matchWon: 1000,
        )));
    await tester.pumpAndSettle();

    final text = _allText(tester);
    expect(text.contains('내 기부'), isFalse);
    expect(text.contains('내가 기여'), isFalse);
    expect(text.contains('내 기여'), isFalse);
  });

  testWidgets('a failed load can be retried', (tester) async {
    _tall(tester);
    var calls = 0;
    await tester.pumpWidget(
      _app(() async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return const DonationSettlement(monthTotalWon: 700, monthCapWon: 0);
      }),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(DonationSettlementScreen.retryKey), findsOneWidget);

    await tester.tap(find.byKey(DonationSettlementScreen.retryKey));
    await tester.pumpAndSettle();

    expect(_text(tester, DonationSettlementScreen.totalKey).data, '700원');
    expect(find.byKey(DonationSettlementScreen.retryKey), findsNothing);
  });
}
