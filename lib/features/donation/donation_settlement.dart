import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../pedometer/kst_calendar.dart';

/// 기부 정산. 모두 서버가 쓴 값을 읽기만 한다.
/// * 내 기여: `donationLedger`에서 내 행의 `companyWon` 합계
/// * 이번 달 합계·한도: `donationMonthTotals/{YYYY-MM}`
class DonationSettlement {
  const DonationSettlement({
    required this.myTotalWon,
    required this.monthTotalWon,
    required this.monthCapWon,
  });

  final int myTotalWon;
  final int monthTotalWon;

  /// 서버 설정 한도. 모르면 0.
  final int monthCapWon;

  /// 이번 달 한도를 다 쓴 상태.
  bool get capReached => monthCapWon > 0 && monthTotalWon >= monthCapWon;
}

/// KST 기준 `YYYY-MM`. 서버의 `monthKey`와 같은 형식이다.
String donationMonthKey([DateTime? now]) =>
    KstCalendar.dateKey(now).substring(0, 7);

int _won(Object? value) {
  if (value is bool || value is! num || value < 0) return 0;
  return value.toInt();
}

/// 월 합계 문서에서 이번 달 합계와 한도를 꺼낸다. 문서가 없으면 0.
DonationSettlement settlementFrom({
  required int myTotalWon,
  Map<String, dynamic>? monthDoc,
}) {
  return DonationSettlement(
    myTotalWon: myTotalWon < 0 ? 0 : myTotalWon,
    monthTotalWon: _won(monthDoc?['totalWon']),
    monthCapWon: _won(monthDoc?['capWon']),
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
      return const DonationSettlement(
        myTotalWon: 0,
        monthTotalWon: 0,
        monthCapWon: 0,
      );
    }
    final mine = await firestore
        .collection('donationLedger')
        .where('uid', isEqualTo: uid)
        .aggregate(sum('companyWon'))
        .get();
    final month =
        await firestore.doc('donationMonthTotals/${donationMonthKey()}').get();
    return settlementFrom(
      myTotalWon: (mine.getSum('companyWon') ?? 0).round(),
      monthDoc: month.data(),
    );
  };
});
