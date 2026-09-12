import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_env.dart';
import '../../../core/constants/debug_wallet_grant.dart';
import '../../../data/models/pedometer_harvest_result.dart';
import '../tournaments/providers/local_joined_ids_provider.dart';
import 'debug_economy_status.dart';
import 'debug_local_wallet_store.dart';
import 'providers/debug_local_share_history_provider.dart';
import 'providers/wallet_provider.dart';

/// Debug one-shot 1,000,000 SHARE/DIA/VALUE after login.
///
/// **Who:** [kDebugMode] (`flutter run`) only. Release/profile store builds
/// never mount this host and never call the grant API or local write.
///
/// **Once per uid:** SharedPreferences [prefsKeyForUid] + Firestore
/// `testGrant1mDone`. Relaunch does not reset balances; spend/earn continue.
///
/// **Reliability:** Home reads `walletProvider` / `users/{uid}.wallet`.
/// The local Firestore write is the primary path so USB testing does not
/// depend on Jena being reachable. Jena `POST /actions/debug/test-grant-1m`
/// is still attempted once as a best-effort sync.
class DebugTestWalletGrantHost extends ConsumerStatefulWidget {
  const DebugTestWalletGrantHost({required this.child, super.key});

  static const prefsKey = DebugWalletGrant.prefsKey;
  static const amount = DebugWalletGrant.amount;
  static const maxAttempts = DebugWalletGrant.maxAttempts;
  static const debugClientSecret = DebugWalletGrant.debugClientSecret;

  static String prefsKeyForUid(String uid) =>
      DebugWalletGrant.prefsKeyForUid(uid);

  /// Secret sent by debug clients. Empty outside [kDebugMode].
  static String grantSecret() {
    if (!kDebugMode) return '';
    final fromEnv = AppEnv.testWalletGrantSecret;
    if (fromEnv.isNotEmpty) return fromEnv;
    return debugClientSecret;
  }

  static bool shouldApplyLocalGrant({
    required bool debugMode,
    required bool walletEmpty,
    bool prefsMarkedDone = false,
  }) {
    return DebugWalletGrant.shouldRunLocalGrant(
      debugMode: debugMode,
      prefsMarkedDone: prefsMarkedDone,
      walletEmpty: walletEmpty,
    );
  }

  static bool shouldRunLocalGrant({
    required bool debugMode,
    required bool prefsMarkedDone,
    required bool walletEmpty,
  }) {
    return DebugWalletGrant.shouldRunLocalGrant(
      debugMode: debugMode,
      prefsMarkedDone: prefsMarkedDone,
      walletEmpty: walletEmpty,
    );
  }

  static Map<String, dynamic> localGrantFirestoreFields({
    int amount = amount,
  }) {
    return DebugWalletGrant.firestoreMergeFields(amount: amount);
  }

  static PedometerHarvestResult localGrantedResult({int amount = amount}) {
    return PedometerHarvestResult(
      status: 'granted',
      shareBalance: amount,
      diamondBalance: amount,
      valueTokenBalance: amount,
    );
  }

  /// Apply 1M to the same [WalletNotifier] Home watches. Does not need Jena.
  static void applyLocalGrantToNotifier(WalletNotifier notifier) {
    const amount = DebugWalletGrant.amount;
    notifier.applyWalletSnapshot(
      shareBalance: amount,
      diamondBalance: amount,
      valueBalance: amount,
    );
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

  /// Durable one-shot. Prefs stay locked after a real debit even if Home
  /// briefly reads 0 before Firestore hydrates.
  static bool shouldHonorLocalGrantLock({
    required bool prefsMarkedDone,
    required bool walletEmpty,
  }) {
    return prefsMarkedDone;
  }

  /// USB smoking gun (PR #12):
  /// `[DEBUG LOCAL] prefs marked done but Home wallet is still 0 — local re-apply`
  /// then `grant SHARE=DIA=VALUE=1000000 firestore=true`.
  ///
  /// Must stay false. A transient UI 0 is not "never granted".
  static bool shouldLocalReapplyBecauseWalletEmpty({
    required bool prefsMarkedDone,
    required bool walletEmpty,
  }) {
    if (!prefsMarkedDone || !walletEmpty) return false;
    return false;
  }

  /// Jena `already_granted` / `granted` must not restore 1M over a spent wallet.
  static bool shouldApplyGrantSnapshot({
    required String status,
    required bool localWalletEmpty,
  }) {
    if (!localWalletEmpty) return false;
    return status == 'granted' || status == 'already_granted';
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
  var _consumed = false;

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
    if (!kDebugMode || _inFlight || _consumed) return;
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final uidKey = DebugTestWalletGrantHost.prefsKeyForUid(uid);
    final prefsMarkedDone = prefs.getBool(uidKey) ?? false;
    final walletEmpty = ref.read(walletProvider).isEmpty;
    if (DebugTestWalletGrantHost.shouldHonorLocalGrantLock(
      prefsMarkedDone: prefsMarkedDone,
      walletEmpty: walletEmpty,
    )) {
      // Wait for remote hydrate. Do not clear prefs or write 1M.
      _consumed = true;
      ref.read(debugEconomyStatusProvider.notifier).markGrantDone();
      debugPrint(
        '[DEBUG LOCAL] grant already done (prefs); skip re-apply '
        'walletEmpty=$walletEmpty',
      );
      try {
        final snap = DebugLocalWalletStore.hydrateFromPrefs(prefs, uid);
        final notifier = ref.read(walletProvider.notifier);
        if (snap.share != null) {
          final current = ref.read(walletProvider).shareBalance;
          final resolved = DebugLocalWalletStore.resolveHydratedShare(
            currentShare: current,
            durableShare: snap.share!,
          );
          notifier.rememberDurableDebugShare(resolved);
          if (current != resolved) {
            notifier.applyWalletSnapshot(shareBalance: resolved);
          }
        }
        if (snap.diamond != null && snap.diamond! > 0) {
          final resolved = DebugLocalWalletStore.resolveDurableCurrency(
            incoming: ref.read(walletProvider).diamondBalance,
            durable: snap.diamond!,
          );
          notifier.rememberDurableWallet(diamond: resolved);
          if (ref.read(walletProvider).diamondBalance != resolved) {
            notifier.applyWalletSnapshot(diamondBalance: resolved);
          }
        }
        if (snap.value != null && snap.value! > 0) {
          final resolved = DebugLocalWalletStore.resolveDurableCurrency(
            incoming: ref.read(walletProvider).valueBalance,
            durable: snap.value!,
          );
          notifier.rememberDurableWallet(value: resolved);
          if (ref.read(walletProvider).valueBalance != resolved) {
            notifier.applyWalletSnapshot(valueBalance: resolved);
          }
        }
        if (snap.paidIds.isNotEmpty) {
          ref
              .read(localJoinedTournamentIdsProvider.notifier)
              .addAll(snap.paidIds);
        }
        if (snap.history.isNotEmpty) {
          ref
              .read(debugLocalShareHistoryProvider.notifier)
              .replace(snap.history);
        }
      } catch (e) {
        debugPrint('[DEBUG LOCAL] durable SHARE hydrate: $e');
      }
      return;
    }
    if (DebugTestWalletGrantHost.shouldLocalReapplyBecauseWalletEmpty(
      prefsMarkedDone: prefsMarkedDone,
      walletEmpty: walletEmpty,
    )) {
      return;
    }
    if (!DebugTestWalletGrantHost.shouldRunLocalGrant(
      debugMode: kDebugMode,
      prefsMarkedDone: prefsMarkedDone,
      walletEmpty: walletEmpty,
    )) {
      if (!walletEmpty) {
        _consumed = true;
      }
      return;
    }

    _inFlight = true;
    ref.read(debugEconomyStatusProvider.notifier).markGrantPending();
    try {
      try {
        await ref.read(userRepositoryProvider).ensureUserDocument(uid: uid);
      } catch (e) {
        debugPrint('[DEBUG LOCAL] ensureUserDocument: $e');
      }

      // Primary path: Home reads walletProvider. Do this before any HTTP.
      DebugTestWalletGrantHost.applyLocalGrantToNotifier(
        ref.read(walletProvider.notifier),
      );
      try {
        await DebugLocalWalletStore.persistBalances(
          prefs: prefs,
          uid: uid,
          share: DebugWalletGrant.amount,
          diamond: DebugWalletGrant.amount,
          value: DebugWalletGrant.amount,
        );
      } catch (e) {
        debugPrint('[DEBUG LOCAL] grant durable persist: $e');
      }

      var firestoreOk = false;
      try {
        await ref.read(walletRepositoryProvider).applyLocalDebugTestGrant(
              uid: uid,
            );
        firestoreOk = true;
      } catch (e) {
        debugPrint(
          '[DEBUG LOCAL] grant Firestore write failed '
          '(Home still shows in-memory 1M): $e',
        );
      }

      try {
        final result =
            await ref.read(walletRepositoryProvider).grantDebugTestWallet1m(
                  grantSecret: DebugTestWalletGrantHost.grantSecret(),
                );
        ref.read(debugEconomyStatusProvider.notifier).markJenaOk();
        if (DebugTestWalletGrantHost.shouldMarkGrantConsumed(result) &&
            DebugTestWalletGrantHost.shouldApplyGrantSnapshot(
              status: result.status,
              localWalletEmpty: ref.read(walletProvider).isEmpty,
            )) {
          ref.read(walletProvider.notifier).applyWalletSnapshot(
                shareBalance: result.shareBalance,
                diamondBalance: result.diamondBalance,
                valueBalance: result.valueTokenBalance,
              );
          debugPrint(
            '[DEBUG LOCAL] Jena ${result.status} '
            'SHARE=${result.shareBalance} '
            'DIA=${result.diamondBalance} '
            'VALUE=${result.valueTokenBalance}',
          );
        } else {
          debugPrint('[DEBUG LOCAL] Jena ${result.status} ignored');
        }
      } catch (e) {
        ref.read(debugEconomyStatusProvider.notifier).markJenaFail();
        debugPrint(
          '[DEBUG LOCAL] Jena skipped (local grant already applied): $e',
        );
      }

      _consumed = true;
      await prefs.setBool(uidKey, true);
      await prefs.setBool(DebugTestWalletGrantHost.prefsKey, true);
      ref.read(debugEconomyStatusProvider.notifier).markGrantDone();
      debugPrint(
        '[DEBUG LOCAL] grant SHARE=DIA=VALUE=${DebugTestWalletGrantHost.amount} '
        'firestore=$firestoreOk',
      );
    } catch (e, st) {
      ref.read(debugEconomyStatusProvider.notifier).markGrantFailed(e);
      debugPrint('[DEBUG LOCAL] grant failed: $e\n$st');
    } finally {
      _inFlight = false;
    }
  }
}
