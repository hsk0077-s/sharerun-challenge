import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import 'pedometer_step_truth.dart';

/// Today's displayed steps from `users/{uid}/daily_metrics/{yyyy-MM-dd}.steps`.
///
/// The phone still uploads through DailyMetricsAccount.commit. The walking
/// screen shows this document, not max(server, this phone's sensor).
class AccountDayMetric {
  const AccountDayMetric({
    required this.dayKey,
    required this.steps,
    this.km = 0,
    this.streakCovered = false,
  });

  final String dayKey;
  final int steps;
  final double km;

  /// Server marked this day so a broken streak stays connected. Not distance.
  final bool streakCovered;
}

abstract final class AccountDailySteps {
  static final _dayKey = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static int stepsOf(Map<String, dynamic>? data) {
    return PedometerStepTruth.clampDaily((data?['steps'] as num?)?.toInt() ?? 0);
  }

  static bool coveredOf(Map<String, dynamic>? data) {
    final raw = data?['streakCovered'];
    return raw == 'cpr' || raw == 'safeguard';
  }

  static AccountDayMetric? dayOf(String dayKey, Map<String, dynamic>? data) {
    if (!_dayKey.hasMatch(dayKey) || data == null) return null;
    final steps = stepsOf(data);
    final kmRaw = data['km'];
    final km = kmRaw is num && kmRaw > 0 ? kmRaw.toDouble() : 0.0;
    final covered = coveredOf(data);
    if (steps <= 0 && km <= 0 && !covered) return null;
    return AccountDayMetric(
      dayKey: dayKey,
      steps: steps,
      km: km,
      streakCovered: covered,
    );
  }

  static List<AccountDayMetric> daysOf(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final rows = <AccountDayMetric>[];
    for (final doc in docs) {
      final row = dayOf(doc.id, doc.data());
      if (row != null) rows.add(row);
    }
    return rows;
  }
}

final accountDailyStepsProvider = StreamProvider.family<int, String>((ref, dayKey) {
  if (dayKey.isEmpty || !_firestoreReady()) {
    return Stream.value(0);
  }
  final authUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final sessionUid = ref.watch(persistedAuthSessionProvider)?.uid ?? '';
  final uid = authUid.isNotEmpty ? authUid : sessionUid;
  if (uid.isEmpty) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('daily_metrics')
      .doc(dayKey)
      .snapshots()
      .map((snap) => AccountDailySteps.stepsOf(snap.data()));
});

/// Every account day in `users/{uid}/daily_metrics`. My Page reads this,
/// not the phone's `{date}_steps` prefs.
final accountDailyMetricsProvider = StreamProvider<List<AccountDayMetric>>((ref) {
  if (!_firestoreReady()) return Stream.value(const []);
  final authUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final sessionUid = ref.watch(persistedAuthSessionProvider)?.uid ?? '';
  final uid = authUid.isNotEmpty ? authUid : sessionUid;
  if (uid.isEmpty) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('daily_metrics')
      .snapshots()
      .map((snap) => AccountDailySteps.daysOf(snap.docs));
});

bool _firestoreReady() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
