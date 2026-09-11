/// Debug one-shot 1,000,000 SHARE/DIA/VALUE.
///
/// Used only from debug clients (`kDebugMode`). Release/profile builds must
/// never call this path. Home reads `users/{uid}.wallet` via walletProvider.
abstract final class DebugWalletGrant {
  static const prefsKey = 'testGrant1mDone';
  static const amount = 1000000;
  static const maxAttempts = 12;

  /// Baked into debug clients only. Must match Jena
  /// `TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET`.
  static const debugClientSecret = 'sharerun-debug-test-grant-1m';

  static String prefsKeyForUid(String uid) => '${prefsKey}_$uid';

  /// Home is empty in debug — apply the local grant even if a stale prefs
  /// lock exists from a previous Jena failure.
  static bool shouldApplyLocalGrant({
    required bool debugMode,
    required bool walletEmpty,
  }) {
    return debugMode && walletEmpty;
  }

  /// Fields merged into `users/{uid}` so Home/`walletProvider` see 1M.
  /// Callers add `updatedAt` (and `uid` when needed).
  static Map<String, dynamic> firestoreMergeFields({int amount = amount}) {
    return {
      prefsKey: true,
      'wallet': walletMap(amount: amount),
    };
  }

  static Map<String, dynamic> walletMap({int amount = amount}) {
    return {
      'shareBalance': amount,
      'diamondBalance': amount,
      'valueTokenBalance': amount,
      'totalDonationValue': 0,
    };
  }
}
