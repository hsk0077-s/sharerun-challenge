import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_env.dart';
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

  final Widget child;

  @override
  ConsumerState<DebugTestWalletGrantHost> createState() =>
      _DebugTestWalletGrantHostState();
}

class _DebugTestWalletGrantHostState
    extends ConsumerState<DebugTestWalletGrantHost> {
  var _inFlight = false;

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

  Future<void> _tryGrantOnce() async {
    if (!kDebugMode || _inFlight) return;
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final uidKey = DebugTestWalletGrantHost.prefsKeyForUid(uid);
    if (prefs.getBool(uidKey) ?? false) {
      return;
    }

    _inFlight = true;
    try {
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
      await prefs.setBool(uidKey, true);
      await prefs.setBool(DebugTestWalletGrantHost.prefsKey, true);
      debugPrint(
        '[TEST GRANT 1M] ${result.status} '
        'SHARE=${result.shareBalance} '
        'DIA=${result.diamondBalance} '
        'VALUE=${result.valueTokenBalance}',
      );
    } catch (e, st) {
      debugPrint('[TEST GRANT 1M] failed: $e\n$st');
      _inFlight = false;
    }
  }
}
