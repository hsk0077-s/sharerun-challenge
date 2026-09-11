/// Debug-only walking harvest fallback when Jena is unreachable.
///
/// Release/profile builds must never credit SHARE locally.
abstract final class DebugLocalHarvest {
  static const logPrefix = '[DEBUG LOCAL]';

  static bool shouldCreditOnJenaFailure({
    required bool debugMode,
    required int toClaim,
  }) {
    return debugMode && toClaim > 0;
  }

  static String successLog({
    required int credited,
    required int shareBalance,
  }) {
    return '$logPrefix harvest +$credited SHARE walletShare=$shareBalance';
  }
}
