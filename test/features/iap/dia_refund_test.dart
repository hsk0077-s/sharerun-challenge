import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/data/api/secured_action_api_client.dart';
import 'package:share_run_challenge/features/crew/crew_membership.dart';
import 'package:share_run_challenge/features/iap/dia_refund.dart';
import 'package:share_run_challenge/features/iap/widgets/dia_notice.dart';

class _FakeApi extends Fake implements SecuredActionApiClient {
  _FakeApi(this.purchases);

  final List<DiaPurchase> purchases;
  final calls = <String>[];
  String refundStatus = 'refund_requested';
  int? failWith;

  @override
  Future<DiaPurchases> diaPurchases() async =>
      DiaPurchases(refundDays: 7, purchases: purchases);

  @override
  Future<DiaRefundResult> requestDiaRefund(String purchaseId) async {
    calls.add('refund:$purchaseId');
    if (failWith != null) throw ApiException(statusCode: failWith!, detail: 'x');
    return DiaRefundResult(
      status: refundStatus,
      refundKrw: 12000,
      playRefunded: refundStatus == 'refunded',
    );
  }
}

DiaPurchase _purchase({
  String id = 'p1',
  bool eligible = true,
  String reason = '',
  String status = '',
  int paid = 120,
  int bonus = 10,
  int spent = 0,
  int krw = 12000,
}) =>
    DiaPurchase(
      purchaseId: id,
      productId: 'dia_pack_130',
      priceKrw: 12000,
      createdAt: DateTime(2026, 10, 15),
      status: status,
      eligible: eligible,
      reason: reason,
      paidDia: paid,
      bonusRevoked: bonus,
      bonusSpent: spent,
      refundKrw: krw,
    );

Future<_FakeApi> _pump(WidgetTester tester, List<DiaPurchase> list) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = _FakeApi(list);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [crewApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: SrcTheme.night,
        home: const Scaffold(body: SingleChildScrollView(child: DiaNoticeCard())),
      ),
    ),
  );
  return api;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(DiaNoticeCard.refundButtonKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the notice states the rules that are true today', (tester) async {
    await _pump(tester, const []);
    final text = DiaNoticeCard.lines.join('\n');
    expect(text, contains('1 DIA는 100원'));
    expect(text, contains('보너스 DIA를 먼저'));
    expect(text, contains('현금으로 바꿀 수 없어요'));
    expect(text, contains('배틀패스'));
    expect(text, contains('7일'));
    for (final line in DiaNoticeCard.lines) {
      expect(find.text('• $line'), findsOneWidget);
    }
  });

  testWidgets('an eligible pack shows the amount and asks before refunding',
      (tester) async {
    final api = await _pump(tester, [_purchase()]);
    await _openSheet(tester);
    expect(find.text('DIA 130개 팩 · 12,000원'), findsOneWidget);
    expect(find.textContaining('덤 10개 회수'), findsOneWidget);
    await tester.tap(find.byKey(DiaRefundSheet.refundKey('p1')));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    expect(find.textContaining('12,000원이 환불돼요'), findsOneWidget);
    expect(find.textContaining('되돌릴 수 없어요'), findsOneWidget);
    await tester.tap(find.byKey(DiaRefundSheet.confirmKey));
    await tester.pumpAndSettle();
    expect(api.calls, ['refund:p1']);
    expect(find.textContaining('담당자가 확인해'), findsOneWidget);
  });

  testWidgets('a spent bonus is shown as a deduction before confirming',
      (tester) async {
    await _pump(tester, [_purchase(paid: 120, bonus: 4, spent: 6, krw: 11400)]);
    await _openSheet(tester);
    await tester.tap(find.byKey(DiaRefundSheet.refundKey('p1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('이미 쓴 덤 6개는 600원을 뺐어요'), findsOneWidget);
    expect(find.textContaining('11,400원이 환불돼요'), findsOneWidget);
  });

  testWidgets('packs that cannot be refunded say why, with no button',
      (tester) async {
    await _pump(tester, [
      _purchase(id: 'a', eligible: false, reason: 'nothing_left'),
      _purchase(id: 'b', eligible: false, reason: 'already_refunded', status: 'requested'),
      _purchase(id: 'c', eligible: false, reason: 'already_refunded', status: 'refunded'),
    ]);
    await _openSheet(tester);
    expect(find.textContaining('쓰지 않은 유료 DIA가 없어서'), findsOneWidget);
    expect(find.text('환불을 신청했어요. 확인 중이에요.'), findsOneWidget);
    expect(find.text('환불이 끝났어요.'), findsOneWidget);
    expect(find.byKey(DiaRefundSheet.refundKey('a')), findsNothing);
  });

  testWidgets('no purchases inside the period says so', (tester) async {
    await _pump(tester, const []);
    await _openSheet(tester);
    expect(find.text('7일 안에 산 DIA 팩이 없어요.'), findsOneWidget);
  });

  testWidgets('when Google Play pays back at once, the toast says it is done',
      (tester) async {
    final api = await _pump(tester, [_purchase()]);
    api.refundStatus = 'refunded';
    await _openSheet(tester);
    await tester.tap(find.byKey(DiaRefundSheet.refundKey('p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaRefundSheet.confirmKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('원이 환불됐어요'), findsOneWidget);
  });

  testWidgets('a repeat request is told it was already made', (tester) async {
    final api = await _pump(tester, [_purchase()]);
    api.failWith = 409;
    await _openSheet(tester);
    await tester.tap(find.byKey(DiaRefundSheet.refundKey('p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaRefundSheet.confirmKey));
    await tester.pumpAndSettle();
    expect(find.text('이미 환불을 신청한 구매예요.'), findsOneWidget);
  });
}
