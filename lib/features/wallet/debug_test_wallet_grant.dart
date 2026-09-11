import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_env.dart';
import '../../../data/models/pedometer_harvest_result.dart';
import 'providers/wallet_provider.dart';

/// Debug one-shot 1,000,000 SHARE/DIA/VALUE after login.
///
/// **Who:** [kDebugMode] (`flutter run`) only. Release/profile store builds
/// never mount this host and never call the grant API.
///
/// **Once per uid:** SharedPreferences [prefsKeyForUid] + Firestore
/// `testGrant1mDone`. Relaunch does not reset balances; spend/earn continue.
class DebugTestWalletGrantHost extends ConsumerStatefulWidget {
  const DebugTestWalletGrantHost({required this.child, super.key});

  static const prefsKey = 'testGrant1mDone';
  static const amount = 1000000;
  static const maxAttempts = 12;

  /// Baked into debug clients only. Must match Jena
  /// `TEST_WALLET_GRANT_DEBUG_CLIENT_SECRET`. Override with
  /// `--dart-define=TEST_WALLET_GRANT_SECRET=...` if needed.
  static const debugClientSecret = 'sharerun-debug-test-grant-1m';

  static String prefsKeyForUid(String uid) => '${prefsKey}_$uid';

  /// Secret sent by debug clients. Empty outside [kDebugMode].
  static String grantSecret() {
    if (!kDebugMode) return '';
    final fromEnv = AppEnv.testWalletGrantSecret;
    if (fromEnv.isNotEmpty) return fromEnv;
    return debugClientSecret;
  }

  /// Local one-shot flag is only written after a real grant or a non-zero
  /// already_granted snapshot. Failures (404 user-not-found, 403 undeployed
  /// path) must not lock the uid out of retries.
  static bool shouldMarkGrantConsumed(PedometerHarvestResult result) {
    if (result.status == 'granted') return true;
    if (result.status != 'already_granted') return false;
    final share = result.shareBalance ?? 0;
    final dia = result.diamondBalance ?? 0;
    final value = result.valueTokenBalance ?? 0;
    return share > 0 || dia > 0 || value > 0;
  }

  /// PR #7 wrote this flag even when the wallet stayed 0. Ignore it so
  /// Home can still receive the 1M grant.
  static bool shouldHonorLocalGrantLock({
    required bool prefsMarkedDone,
    required bool walletEmpty,
  }) {
    if (!prefsMarkedDone) return false;
    return !walletEmpty;
  }

  static bool shouldRetryGrant(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 404 || error.statusCode == 403) return true;
      if (error.statusCode >= 500) return true;
      return false;
    }
    return true;
  }

  final Widget child;

  @override
  ConsumerState<DebugTestWalletGrantHost> createState() =>
      _DebugTestWalletGrantHostState();
}

class _DebugTestWalletGrantHostState
    extends ConsumerState<DebugTestWalletGrantHost> {
  var _inFlight = false;
  var _attempts = 0;
  var _consumed = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_tryGrantOnce());
      });
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      ref.listen(authStateChangesProvider, (_, next) {
        final uid = next.asData?.value?.uid;
        if (uid != null && uid.isNotEmpty) {
          unawaited(_tryGrantOnce());
        }
      });
    }
    return widget.child;
  }

  Duration _retryDelay() {
    final shift = _attempts.clamp(0, 4);
    final ms = 400 * (1 << shift);
    return Duration(milliseconds: ms > 4000 ? 4000 : ms);
  }

  void _scheduleRetry() {
    if (_consumed || _attempts >= DebugTestWalletGrantHost.maxAttempts) {
      debugPrint(
        '[TEST GRANT 1M] stopped after $_attempts attempts. '
        'Need Jena with POST /actions/debug/test-grant-1m deployed, '
        'and users/{uid} must exist.',
      );
      return;
    }
    _retry?.cancel();
    _retry = Timer(_retryDelay(), () {
      unawaited(_tryGrantOnce());
    });
  }

  Future<void> _tryGrantOnce() async {
    if (!kDebugMode || _inFlight || _consumed) return;
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final uidKey = DebugTestWalletGrantHost.prefsKeyForUid(uid);
    final prefsMarkedDone = prefs.getBool(uidKey) ?? false;
    if (DebugTestWalletGrantHost.shouldHonorLocalGrantLock(
      prefsMarkedDone: prefsMarkedDone,
      walletEmpty: ref.read(walletProvider).isEmpty,
    )) {
      _consumed = true;
      return;
    }
    if (prefsMarkedDone) {
      debugPrint(
        '[TEST GRANT 1M] prefs marked done but Home wallet is still 0 — retry',
      );
      await prefs.remove(uidKey);
    }

    _inFlight = true;
    try {
      try {
        await ref.read(userRepositoryProvider).ensureUserDocument(uid: uid);
      } catch (e) {
        debugPrint('[TEST GRANT 1M] ensureUserDocument: $e');
      }
      final result = await ref.read(walletRepositoryProvider).grantDebugTestWallet1m(
            grantSecret: DebugTestWalletGrantHost.grantSecret(),
          );
      const fallback = DebugTestWalletGrantHost.amount;
      final grantedNow = result.status == 'granted';
      ref.read(walletProvider.notifier).applyWalletSnapshot(
            shareBalance: result.shareBalance ?? (grantedNow ? fallback : null),
            diamondBalance:
                result.diamondBalance ?? (grantedNow ? fallback : null),
            valueBalance:
                result.valueTokenBalance ?? (grantedNow ? fallback : null),
          );
      debugPrint(
        '[TEST GRANT 1M] ${result.status} '
        'SHARE=${result.shareBalance} '
        'DIA=${result.diamondBalance} '
        'VALUE=${result.valueTokenBalance}',
      );
      if (DebugTestWalletGrantHost.shouldMarkGrantConsumed(result)) {
        _consumed = true;
        await prefs.setBool(uidKey, true);
        await prefs.setBool(DebugTestWalletGrantHost.prefsKey, true);
      } else {
        _attempts += 1;
        _inFlight = false;
        _scheduleRetry();
      }
    } catch (e, st) {
      debugPrint('[TEST GRANT 1M] failed: $e\n$st');
      _inFlight = false;
      if (DebugTestWalletGrantHost.shouldRetryGrant(e)) {
        _attempts += 1;
        _scheduleRetry();
      }
    }
  }
}
