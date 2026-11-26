import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../pedometer/kst_calendar.dart';

/// 기부 투명성. 모두 서버가 쓴 값을 읽기만 한다.
/// * 이번 달 합계·한도·걸음/매칭 몫: `donationMonthTotals/{YYYY-MM}` (이용자 전체 합계, uid 없음)
/// * 실제로 보낸 기부: `donationExecutions/{YYYY-MM}` (관리자가 서버로 저장한 기록)
///
/// 개인별 원화 기부액은 읽지도 보여 주지도 않는다.
class DonationSettlement {
  const DonationSettlement({
    required this.monthTotalWon,
    required this.monthCapWon,
    this.stepWon = 0,
    this.matchWon = 0,
    this.executions = const [],
  });

  /// 이번 달 전체 기부 예정액(러닝+걸음+상점 매칭).
  final int monthTotalWon;

  /// 서버 설정 한도. 이번 달 기록이 아직 없어서 모르면 0.
  final int monthCapWon;

  /// 이번 달 걸음 기부 몫.
  final int stepWon;

  /// 이번 달 상점 매칭 몫.
  final int matchWon;

  /// 실제 집행 기록, 최근 달부터.
  final List<DonationExecution> executions;

  /// 러닝 몫. 서버는 러닝 몫을 따로 세지 않아서 합계에서 걸음·매칭을 뺀다.
  int get runWon {
    final rest = monthTotalWon - stepWon - matchWon;
    return rest < 0 ? 0 : rest;
  }

  /// 이번 달 한도를 다 쓴 상태.
  bool get capReached => monthCapWon > 0 && monthTotalWon >= monthCapWon;

  /// 기부처 이름이 있는 가장 최근 집행 기록의 기부처. 없으면 null(기부처 선정 중).
  String? get partnerName {
    for (final row in executions) {
      if (row.partnerName.isNotEmpty) return row.partnerName;
    }
    return null;
  }
}

/// 실제로 보낸 한 달치 기부.
class DonationExecution {
  const DonationExecution({
    required this.month,
    required this.amountWon,
    required this.executedAt,
    required this.partnerName,
    required this.receiptImagePath,
    required this.note,
  });

  final String month;
  final int amountWon;
  final DateTime? executedAt;
  final String partnerName;
  final String receiptImagePath;
  final String note;

  /// 금액이 1원 이상일 때만 집행으로 본다.
  static DonationExecution? tryParse(String month, Map<String, dynamic>? data) {
    if (data == null) return null;
    final amount = _won(data['amountWon']);
    if (amount <= 0) return null;
    final at = data['executedAt'];
    return DonationExecution(
      month: month,
      amountWon: amount,
      executedAt: at is Timestamp ? at.toDate() : (at is DateTime ? at : null),
      partnerName: _text(data['partnerName']),
      receiptImagePath: _text(data['receiptImagePath']),
      note: _text(data['note']),
    );
  }
}

/// KST 기준 `YYYY-MM`. 서버의 `monthKey`와 같은 형식이다.
String donationMonthKey([DateTime? now]) =>
    KstCalendar.dateKey(now).substring(0, 7);

int _won(Object? value) {
  if (value is bool || value is! num || value.isNaN || value < 0) return 0;
  return value.toInt();
}

String _text(Object? value) => value is String ? value.trim() : '';

/// 월 합계 문서와 집행 기록에서 화면 값을 만든다. 문서가 없으면 0.
DonationSettlement settlementFrom({
  Map<String, dynamic>? monthDoc,
  List<DonationExecution> executions = const [],
}) {
  final sorted = [...executions]..sort((a, b) => b.month.compareTo(a.month));
  return DonationSettlement(
    monthTotalWon: _won(monthDoc?['totalWon']),
    monthCapWon: _won(monthDoc?['capWon']),
    stepWon: _won(monthDoc?['stepWon']),
    matchWon: _won(monthDoc?['matchWon']),
    executions: sorted,
  );
}

typedef DonationSettlementLoader = Future<DonationSettlement> Function();

/// 테스트에서 바꿔 끼울 수 있게 provider로 둔다.
final donationSettlementLoaderProvider =
    Provider<DonationSettlementLoader>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final firestore = ref.watch(firestoreServiceProvider);
  return () async {
    if (uid.isEmpty) {
      return const DonationSettlement(monthTotalWon: 0, monthCapWon: 0);
    }
    final month =
        await firestore.doc('donationMonthTotals/${donationMonthKey()}').get();
    final rows = await firestore.collection('donationExecutions').get();
    return settlementFrom(
      monthDoc: month.data(),
      executions: [
        for (final doc in rows.docs)
          if (DonationExecution.tryParse(doc.id, doc.data()) case final row?)
            row,
      ],
    );
  };
});
