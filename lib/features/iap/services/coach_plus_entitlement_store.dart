import 'package:shared_preferences/shared_preferences.dart';

import '../models/coach_plus_product.dart';

/// Device cache of an owned Coach+ subscription.
///
/// The store (purchase / restore) is what grants this. Expiry here is only
/// the local window on [CoachPlusPlan.localActiveWindow].
class CoachPlusEntitlementStore {
  const CoachPlusEntitlementStore();

  static const productIdKey = 'src.coach_plus.product_id';
  static const activeUntilKey = 'src.coach_plus.active_until_ms';

  Future<bool> readActive({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final productId = prefs.getString(productIdKey);
    final untilMs = prefs.getInt(activeUntilKey);
    if (productId == null ||
        untilMs == null ||
        !CoachPlusPlan.isCoachPlusId(productId)) {
      return false;
    }
    final clock = now ?? DateTime.now();
    return clock.isBefore(DateTime.fromMillisecondsSinceEpoch(untilMs));
  }

  Future<void> grant(String productId, {DateTime? now}) async {
    final plan = CoachPlusPlan.byProductId(productId);
    if (plan == null) return;
    final start = now ?? DateTime.now();
    final until = start.add(plan.localActiveWindow);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(productIdKey, plan.productId);
    await prefs.setInt(activeUntilKey, until.millisecondsSinceEpoch);
  }
}
