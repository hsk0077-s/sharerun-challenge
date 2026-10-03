import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import 'pedometer_step_truth.dart';

/// Today's displayed steps from `users/{uid}/daily_metrics/{yyyy-MM-dd}.steps`.
///
/// The phone still uploads through DailyMetricsAccount.commit. The walking
/// screen shows this document, not max(server, this phone's sensor).
abstract final class AccountDailySteps {
  static int stepsOf(Map<String, dynamic>? data) {
    return PedometerStepTruth.clampDaily((data?['steps'] as num?)?.toInt() ?? 0);
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

bool _firestoreReady() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
