import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/user_model.dart';
import '../models/coach_plus_product.dart';
import '../services/coach_plus_entitlement_store.dart';

final coachPlusEntitlementStoreProvider = Provider<CoachPlusEntitlementStore>(
  (ref) => const CoachPlusEntitlementStore(),
);

/// Writes the account entitlement. Tests replace this so they do not call
/// the network. Production always hits the server.
typedef CoachPlusServerGrant = Future<void> Function(String productId);

final coachPlusServerGrantProvider = Provider<CoachPlusServerGrant>((ref) {
  return (productId) {
    return ref.read(securedActionApiClientProvider).activateCoachPlus(productId);
  };
});

/// True when this account's server profile says Coach+ is still inside the
/// window the server stored. Device prefs are not the source of truth.
final coachPlusFromProfileProvider = Provider<bool>((ref) {
  final profile = ref.watch(activeUserProfileProvider).asData?.value;
  return coachPlusActiveOnProfile(profile, DateTime.now());
});

bool coachPlusActiveOnProfile(UserModel? profile, DateTime now) {
  if (profile == null) return false;
  if (!CoachPlusPlan.isCoachPlusId(profile.coachPlusProductId)) return false;
  final until = DateTime.tryParse(profile.coachPlusActiveUntil);
  if (until == null) return false;
  return now.isBefore(until);
}

/// True while the server profile (or the debug override) says Coach+ is active.
final coachPlusActiveProvider =
    NotifierProvider<CoachPlusActiveNotifier, bool>(CoachPlusActiveNotifier.new);

class CoachPlusActiveNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (coachPlusForceDebug) return true;
    return ref.watch(coachPlusFromProfileProvider);
  }

  Future<void> grant(String productId) async {
    if (!CoachPlusPlan.isCoachPlusId(productId)) return;
    await ref.read(coachPlusServerGrantProvider)(productId);
  }
}

/// Increments once when a heart-rate cue is blocked for lack of Coach+.
final coachPlusUpsellCountProvider =
    NotifierProvider<CoachPlusUpsellNotifier, int>(CoachPlusUpsellNotifier.new);

class CoachPlusUpsellNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() {
    if (state > 0) return;
    state = 1;
  }
}
