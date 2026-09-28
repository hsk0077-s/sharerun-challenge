import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coach_plus_product.dart';
import '../services/coach_plus_entitlement_store.dart';

final coachPlusEntitlementStoreProvider = Provider<CoachPlusEntitlementStore>(
  (ref) => const CoachPlusEntitlementStore(),
);

/// True while Coach+ (or the debug override) is active.
final coachPlusActiveProvider =
    NotifierProvider<CoachPlusActiveNotifier, bool>(CoachPlusActiveNotifier.new);

class CoachPlusActiveNotifier extends Notifier<bool> {
  var _generation = 0;

  @override
  bool build() {
    if (coachPlusForceDebug) return true;
    _hydrate();
    return false;
  }

  Future<void> _hydrate() async {
    if (coachPlusForceDebug) return;
    final generation = _generation;
    final active =
        await ref.read(coachPlusEntitlementStoreProvider).readActive();
    if (!ref.mounted || coachPlusForceDebug || generation != _generation) {
      return;
    }
    state = active;
  }

  Future<void> grant(String productId) async {
    if (!CoachPlusPlan.isCoachPlusId(productId)) return;
    _generation += 1;
    await ref.read(coachPlusEntitlementStoreProvider).grant(productId);
    if (!ref.mounted) return;
    state = true;
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
