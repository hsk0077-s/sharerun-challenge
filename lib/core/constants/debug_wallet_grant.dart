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

  /// First-time fill only. [prefsMarkedDone] is durable across kill/relaunch
  /// and wins even while Home still shows 0 (cold-start hydration).
  static bool shouldApplyLocalGrant({
    required bool debugMode,
    required bool walletEmpty,
    bool prefsMarkedDone = false,
  }) {
    return shouldRunLocalGrant(
      debugMode: debugMode,
      prefsMarkedDone: prefsMarkedDone,
      walletEmpty: walletEmpty,
    );
  }

  /// One-shot per install/uid. A spent wallet that looks empty before
  /// Firestore hydrates must not restore 1M.
  static bool shouldRunLocalGrant({
    required bool debugMode,
    required bool prefsMarkedDone,
    required bool walletEmpty,
  }) {
    if (!debugMode) return false;
    if (prefsMarkedDone) return false;
    return walletEmpty;
  }

  /// Fields merged into `users/{uid}` so Home/`walletProvider` see 1M.
  /// Does not write donation totals — those persist independently of the grant.
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
    };
  }

  /// Sponsorship / debug SHARE spend. Never resets donation aggregates to 0.
  static Map<String, dynamic> donationPersistFields({
    required int donationCount,
    required int cumulativeDonationAmount,
  }) {
    return {
      'donationCount': donationCount,
      'cumulativeDonationAmount': cumulativeDonationAmount,
      'isSponsored': true,
    };
  }

  /// Dotted-field merge for `validDebugShareSpend`. Absolute SHARE plus
  /// unchanged DIA/VALUE so rules see a full wallet map. Does not include
  /// `updatedAt` (callers add a server timestamp).
  static Map<String, dynamic> shareSpendMergeFields({
    required String uid,
    required int shareBalanceAfter,
    int? diamondBalance,
    int? valueBalance,
    int? donationCount,
    int? cumulativeDonationAmount,
    bool isSponsored = false,
  }) {
    return {
      'uid': uid,
      prefsKey: true,
      'wallet.shareBalance': shareBalanceAfter,
      if (diamondBalance != null) 'wallet.diamondBalance': diamondBalance,
      if (valueBalance != null) 'wallet.valueTokenBalance': valueBalance,
      if (donationCount != null) 'donationCount': donationCount,
      if (cumulativeDonationAmount != null)
        'cumulativeDonationAmount': cumulativeDonationAmount,
      if (isSponsored) 'isSponsored': true,
    };
  }
}
