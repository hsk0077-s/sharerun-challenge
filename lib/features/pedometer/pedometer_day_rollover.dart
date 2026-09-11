import 'kst_calendar.dart';
import 'pedometer_harvest_ledger.dart';

/// In-memory + prefs plan for a KST calendar-day change.
///
/// Wallet SHARE/DIA/VALUE, inventory, and donation history are not in this
/// plan — those must persist across midnight.
class PedometerRolloverPlan {
  const PedometerRolloverPlan({
    required this.dateKey,
    required this.stepOffset,
  });

  final String dateKey;
  final int stepOffset;

  int get steps => 0;
  double get km => 0;
  int get claimedSteps => 0;
  double get collectedShare => 0;
  bool get milestone1 => false;
  bool get milestone2 => false;
  bool get milestone3 => false;
  bool get bonus => false;
}

/// Pure KST midnight rollover rules. The screen/isolate apply the plan.
abstract final class PedometerDayRollover {
  static const lastSavedDateKey = 'lastSavedDate';
  static const stepOffsetKey = 'stepOffset';
  static const collectedShareCoinsKey = 'collected_share_coins';

  static bool needsRollover({
    required String lastSavedDate,
    required String todayKey,
  }) {
    return lastSavedDate.isNotEmpty && lastSavedDate != todayKey;
  }

  /// First launch / prefs not hydrated yet — do not stamp today and skip
  /// yesterday's reset.
  static bool canEvaluate(String lastSavedDate) => lastSavedDate.isNotEmpty;

  static PedometerRolloverPlan plan({
    required String todayKey,
    required int sensorTotal,
  }) {
    return PedometerRolloverPlan(
      dateKey: todayKey,
      stepOffset: sensorTotal < 0 ? 0 : sensorTotal,
    );
  }

  /// After a new KST day, never restore yesterday's claimed watermark.
  static int claimedAfterHydrate({
    required bool rolledOver,
    required int coalescedClaimed,
  }) {
    if (rolledOver) return 0;
    return coalescedClaimed < 0 ? 0 : coalescedClaimed;
  }

  static String dayStepOffsetKey(String dateKey) => '${dateKey}_step_offset';

  static Map<String, Object> prefsToWrite(PedometerRolloverPlan plan) {
    return {
      lastSavedDateKey: plan.dateKey,
      stepOffsetKey: plan.stepOffset,
      dayStepOffsetKey(plan.dateKey): plan.stepOffset,
      collectedShareCoinsKey: 0.0,
      PedometerHarvestLedger.todayClaimedKey(plan.dateKey): 0,
      PedometerHarvestLedger.globalClaimedKey: 0,
      PedometerHarvestLedger.globalClaimedDateKey: plan.dateKey,
    };
  }

  /// Keys that must survive midnight. Used by tests; do not wipe these.
  static bool persistsAcrossMidnight(String key) {
    if (key == 'SHARE' || key == 'DIA' || key == 'VALUE') return true;
    if (key.contains('inventory') || key.contains('Inventory')) return true;
    if (key.contains('donation') || key.contains('Donation')) return true;
    if (key.contains('wallet_transactions') || key.contains('walletHistory')) {
      return true;
    }
    return false;
  }

  static String todayKey([DateTime? now]) => KstCalendar.dateKey(now);
}
