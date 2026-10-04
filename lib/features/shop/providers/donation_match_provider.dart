import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../donation_match_line.dart';

/// This account's company donation matches from `donationLedger`.
final donationMatchProvider = StreamProvider<List<DonationMatchEntry>>((ref) {
  if (!_firestoreReady()) return Stream.value(const []);
  final authUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final sessionUid = ref.watch(persistedAuthSessionProvider)?.uid ?? '';
  final uid = authUid.isNotEmpty ? authUid : sessionUid;
  if (uid.isEmpty) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('donationLedger')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snap) {
    final rows = <DonationMatchEntry>[];
    for (final doc in snap.docs) {
      final row = DonationMatchEntry.fromDoc(doc.data());
      if (row != null) rows.add(row);
    }
    return rows;
  });
});

bool _firestoreReady() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
