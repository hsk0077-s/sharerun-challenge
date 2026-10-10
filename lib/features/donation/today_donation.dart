import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../pedometer/kst_calendar.dart';
import 'donation_settlement.dart';

/// 홈의 "오늘 나의 기부 기여". 서버가 쓴 기부 원장 행만 더한다.
/// 폰에서 거리 × 100원을 계산하지 않는다.
class TodayDonation {
  const TodayDonation({required this.todayWon, required this.capReached});

  final int todayWon;

  /// 이번 달 회사 기부 한도를 다 쓴 상태(서버 `donationMonthTotals`).
  final bool capReached;
}

/// 이번 달 내 원장 행 중 KST 오늘 만들어진 행의 `companyWon` 합계.
int todayWonFrom(List<Map<String, dynamic>> monthRows, {DateTime? now}) {
  final today = KstCalendar.dateKey(now);
  var total = 0;
  for (final row in monthRows) {
    final created = row['createdAt'];
    if (created is! Timestamp) continue;
    if (KstCalendar.dateKey(created.toDate()) != today) continue;
    final won = row['companyWon'];
    if (won is num && !won.isNaN && won > 0) total += won.toInt();
  }
  return total;
}

typedef TodayDonationLoader = Future<TodayDonation> Function();

/// 테스트에서 바꿔 끼울 수 있게 provider로 둔다.
final todayDonationLoaderProvider = Provider<TodayDonationLoader>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final firestore = ref.watch(firestoreServiceProvider);
  return () async {
    if (uid.isEmpty) {
      return const TodayDonation(todayWon: 0, capReached: false);
    }
    final month = donationMonthKey();
    // 같음 조건만 써서 별도 색인 없이 읽는다. 오늘 행만 골라 더한다.
    final rows = await firestore
        .collection('donationLedger')
        .where('uid', isEqualTo: uid)
        .where('monthKey', isEqualTo: month)
        .get();
    final totals = await firestore.doc('donationMonthTotals/$month').get();
    final settlement = settlementFrom(myTotalWon: 0, monthDoc: totals.data());
    return TodayDonation(
      todayWon: todayWonFrom([for (final doc in rows.docs) doc.data()]),
      capReached: settlement.capReached,
    );
  };
});

/// 홈을 열 때마다 새로 읽는다(홈을 떠나면 버려진다).
final todayDonationProvider =
    FutureProvider.autoDispose<TodayDonation>((ref) {
  return ref.watch(todayDonationLoaderProvider)();
});
