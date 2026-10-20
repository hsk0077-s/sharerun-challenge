import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/api/secured_action_api_client.dart';
import 'package:share_run_challenge/features/crew/crew_membership.dart';
import 'package:share_run_challenge/features/donation/sponsorship_records.dart';
import 'package:share_run_challenge/screens/personal_sponsor_screen.dart';

class _FakeApi extends Fake implements SecuredActionApiClient {
  _FakeApi({required this.summary, this.mine = const MySponsorship()});

  final SponsorshipSummary summary;
  final MySponsorship mine;

  @override
  Future<SponsorshipSummary> sponsorshipSummary() async => summary;

  @override
  Future<MySponsorship> mySponsorship() async => mine;
}

Future<void> _pump(WidgetTester tester, _FakeApi? api) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [crewApiProvider.overrideWithValue(api)],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: SponsorshipStatusCard())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _status(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('sponsorship-status-line'))).data!;

void main() {
  testWidgets('everyone sees the principle and the totals once enough people sponsored',
      (tester) async {
    await _pump(
      tester,
      _FakeApi(
        summary: const SponsorshipSummary(
          sponsorCount: 7,
          showAmounts: true,
          totalWon: 350000,
          monthWon: 100000,
          monthCount: 2,
        ),
      ),
    );
    expect(find.text('후원은 운영자 이름으로 기부돼요. 운영자는 전달만 해요.'), findsOneWidget);
    expect(_status(tester), '이번 달 100,000원 · 누적 350,000원 · 참여 7명');
  });

  testWidgets('with too few sponsors no amount is shown, only how many joined',
      (tester) async {
    await _pump(
      tester,
      _FakeApi(summary: const SponsorshipSummary(sponsorCount: 2, minSponsors: 5)),
    );
    expect(_status(tester), '참여 2명 · 금액은 5명 이상 모이면 보여 드려요.');
    expect(find.textContaining('원 ·'), findsNothing);
  });

  testWidgets('no sponsors yet says so', (tester) async {
    await _pump(tester, _FakeApi(summary: const SponsorshipSummary()));
    expect(_status(tester), '아직 후원한 분이 없어요.');
  });

  testWidgets('offline the card keeps the principle and hides the status line',
      (tester) async {
    await _pump(tester, null);
    expect(find.text('후원은 운영자 이름으로 기부돼요. 운영자는 전달만 해요.'), findsOneWidget);
    expect(find.byKey(const Key('sponsorship-status-line')), findsNothing);
  });

  testWidgets('the sponsor opens their own list: the total and each entry',
      (tester) async {
    await _pump(
      tester,
      _FakeApi(
        summary: const SponsorshipSummary(),
        mine: MySponsorship(
          donationCount: 2,
          donationWon: 100000,
          entries: [
            SponsorshipEntry(purpose: 'donation', share: 50000, won: 50000, createdAt: DateTime(2026, 10, 17)),
            SponsorshipEntry(purpose: 'prize', share: 50000, won: 50000, createdAt: DateTime(2026, 10, 10)),
            SponsorshipEntry(purpose: 'donation', share: 50000, won: 50000, createdAt: DateTime(2026, 10, 1)),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(SponsorshipStatusCard.mineButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('이 내역은 나만 볼 수 있어요.'), findsOneWidget);
    expect(find.text('기부 후원 2번 · 100,000원'), findsOneWidget);
    expect(find.text('기부 후원'), findsNWidgets(2));
    expect(find.text('상금 후원'), findsOneWidget);
    expect(find.text('2026.10.17'), findsOneWidget);
  });

  testWidgets('an empty list says nothing has been sponsored yet', (tester) async {
    await _pump(tester, _FakeApi(summary: const SponsorshipSummary()));
    await tester.tap(find.byKey(SponsorshipStatusCard.mineButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('아직 후원한 내역이 없어요.'), findsOneWidget);
  });

  test('summary parsing keeps held-back amounts null', () {
    final s = SponsorshipSummary.fromJson({
      'sponsor_count': 3,
      'show_amounts': false,
      'min_sponsors': 5,
      'total_won': null,
    });
    expect(s.totalWon, isNull);
    expect(s.showAmounts, isFalse);
  });
}
