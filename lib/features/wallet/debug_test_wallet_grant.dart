import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import 'providers/wallet_provider.dart';

/// Debug-only one-shot 1,000,000 SHARE/DIA/VALUE grant.
///
/// Trigger: first `kDebugMode` launch after login. Release builds never run.
/// Replay lock: SharedPreferences [prefsKey] and Firestore `testGrant1mDone`.
class DebugTestWalletGrantHost extends ConsumerStatefulWidget {
  const DebugTestWalletGrantHost({required this.child, super.key});

  static const prefsKey = 'testGrant1mDone';
  static const amount = 1000000;

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

    _inFlight = true;
    try {
      final result =
          await ref.read(walletRepositoryProvider).grantDebugTestWallet1m();
      const fallback = DebugTestWalletGrantHost.amount;
      ref.read(walletProvider.notifier).applyWalletSnapshot(
            shareBalance: result.shareBalance ?? fallback,
            diamondBalance: result.diamondBalance ?? fallback,
            valueBalance: result.valueTokenBalance ?? fallback,
          );
      await prefs.setBool(DebugTestWalletGrantHost.prefsKey, true);
      await prefs.setInt('SHARE', result.shareBalance ?? fallback);
      await prefs.setInt('DIA', result.diamondBalance ?? fallback);
      await prefs.setInt('VALUE', result.valueTokenBalance ?? fallback);
      await prefs.setDouble(
        'collected_share_coins',
        (result.shareBalance ?? fallback).toDouble(),
      );
      debugPrint(
        '[TEST GRANT 1M] ${result.status} '
        'SHARE=${result.shareBalance ?? fallback} '
        'DIA=${result.diamondBalance ?? fallback} '
        'VALUE=${result.valueTokenBalance ?? fallback}',
      );
    } catch (e, st) {
      debugPrint('[TEST GRANT 1M] failed: $e\n$st');
      _inFlight = false;
    }
  }
}
