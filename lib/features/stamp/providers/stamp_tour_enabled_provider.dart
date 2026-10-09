import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/constants/firestore_paths.dart';

/// `config/stamp_tour` field `enabled`. Anything but `true` keeps the tour hidden.
bool stampTourEnabledFrom(Map<String, dynamic>? data) => data?['enabled'] == true;

/// Read once per sign-in. A new value shows up after the app is reopened.
/// A missing doc, a missing field, or a read error all mean hidden.
final stampTourEnabledProvider = FutureProvider<bool>((ref) async {
  try {
    ref.watch(authStateChangesProvider);
    final snap = await ref
        .read(firestoreServiceProvider)
        .doc(FirestorePaths.stampTourConfig)
        .get();
    return stampTourEnabledFrom(snap.data());
  } catch (e) {
    debugPrint('stampTourEnabledProvider: $e');
    return false;
  }
});
