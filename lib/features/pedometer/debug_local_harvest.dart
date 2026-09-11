/// Debug-only walking harvest fallback when Jena is unreachable.
///
/// Release/profile builds must never credit SHARE locally.
abstract final class DebugLocalHarvest {
  static const logPrefix = '[HARVEST]';

  static bool shouldCreditOnJenaFailure({
    required bool debugMode,
    required int toClaim,
  }) {
    return debugMode && toClaim > 0;
  }

  static String resultLog({
    required bool credited,
    required int amount,
    required String source,
    int? walletShare,
  }) {
    final src = source == 'jena' ? 'jena' : 'local';
    final tail = walletShare == null ? '' : ' walletShare=$walletShare';
    return '$logPrefix credited=${credited ? 'Y' : 'N'} amount=$amount '
        'source=$src$tail';
  }
}
