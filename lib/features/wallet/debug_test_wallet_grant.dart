import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_env.dart';
import 'providers/wallet_provider.dart';

/// Debug one-shot 1,000,000 SHARE/DIA/VALUE for the owner/tester only.
///
/// **Who gets it:** only a UID in [allowlistUids], or a user whose Firestore
/// doc has admin-set `testGrant1mEligible: true`, or a matching
/// `TEST_WALLET_GRANT_SECRET`. [allowlistUids] is empty by default — other
/// debug installs never receive the grant.
///
/// **Once:** SharedPreferences [prefsKey] + Firestore `testGrant1mDone`.
/// Relaunch does not reset balances; spend/earn continue from the granted
/// amounts.
class DebugTestWalletGrantHost extends ConsumerStatefulWidget {
  const DebugTestWalletGrantHost({required this.child, super.key});

  static const prefsKey = 'testGrant1mDone';
  static const amount = 1000000;
  static const eligibleField = 'testGrant1mEligible';

  /// Put the tester Firebase Auth UID here, then debug-run once.
  /// Leave empty so nobody is auto-granted.
  static const allowlistUids = <String>[
    // 'YOUR_FIREBASE_UID',
  ];

  static bool isAllowlisted(String uid) =>
      uid.isNotEmpty && allowlistUids.contains(uid);

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
    if (prefs.getBool(DebugTestWalletGrantHost.prefsKey) ?? false) {
      return;
    }

    final secret = AppEnv.testWalletGrantSecret;
    final eligible = await _isCallerEligible(uid: uid, secret: secret);
    if (!eligible) {
      debugPrint(
        '[TEST GRANT 1M] skipped — uid not allowlisted, '
        'no admin eligible flag, no secret',
      );
      return;
    }

    _inFlight = true;
    try {
      final result = await ref.read(walletRepositoryProvider).grantDebugTestWallet1m(
            grantSecret: secret,
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

  Future<bool> _isCallerEligible({
    required String uid,
    required String secret,
  }) async {
    if (DebugTestWalletGrantHost.isAllowlisted(uid)) return true;
    if (secret.isNotEmpty) return true;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return snap.data()?[DebugTestWalletGrantHost.eligibleField] == true;
    } catch (e) {
      debugPrint('[TEST GRANT 1M] eligible lookup failed: $e');
      return false;
    }
  }
}
