import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/email_verification_guard.dart';
import '../../../data/models/tournament_model.dart';
import '../../wallet/debug_local_wallet_store.dart';
import '../../wallet/providers/debug_local_share_history_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../providers/local_joined_ids_provider.dart';
import 'tournament_join_gate.dart';
import 'tournament_join_outcome.dart';

/// Prevents double-tap from calling Jena twice before `joinedIds` updates.
final Set<String> _joinInFlight = <String>{};

@visibleForTesting
void resetTournamentJoinInFlightForTest() => _joinInFlight.clear();

/// Join a recruiting room. Returns true only when payment succeeded or a
/// prior paid join is proven (Jena participants / durable local ledger).
Future<bool> joinTournamentWithPreflight({
  required BuildContext context,
  required WidgetRef ref,
  required TournamentModel tournament,
}) async {
  // Capture the root container before any await. WidgetRef.read after the
  // join button unmounts throws:
  // "Using ref when a widget is about to or has been unmounted is unsafe."
  final ProviderContainer container;
  final ScaffoldMessengerState? messenger;
  try {
    container = ProviderScope.containerOf(context);
    messenger = ScaffoldMessenger.maybeOf(context);
    // Touch ref only while the element is still mounted.
    if (!context.mounted) {
      return false;
    }
    assert(ref.exists(walletProvider));
  } catch (e) {
    debugPrint('[JOIN] missing ProviderScope: $e');
    return false;
  }

  void snack(String message) {
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  T? readSafe<T>(T Function() read) {
    try {
      return read();
    } catch (e) {
      debugPrint('[JOIN] provider read skipped (disposed): $e');
      return null;
    }
  }

  final authUser =
      readSafe(() => container.read(authStateChangesProvider).value);
  if (authUser == null) {
    snack('로그인 후 챌린지에 참가할 수 있습니다.');
    return false;
  }
  final verified = await ensureEmailVerified(
    context: context,
    user: authUser,
  );
  if (!verified) {
    return false;
  }

  final prefs = await SharedPreferences.getInstance();
  final snap = DebugLocalWalletStore.hydrateFromPrefs(prefs, authUser.uid);
  readSafe(() {
    if (snap.share != null) {
      container
          .read(walletProvider.notifier)
          .rememberDurableDebugShare(snap.share!);
    }
    if (snap.paidIds.isNotEmpty) {
      container
          .read(localJoinedTournamentIdsProvider.notifier)
          .addAll(snap.paidIds);
    }
    if (snap.history.isNotEmpty) {
      container
          .read(debugLocalShareHistoryProvider.notifier)
          .replace(snap.history);
    }
  });

  final remoteJoined =
      readSafe(() => container.read(joinedTournamentIdsProvider).value) ??
          const <String>{};
  final localPaid =
      readSafe(() => container.read(localJoinedTournamentIdsProvider)) ??
          snap.paidIds;
  final durablePaid = {...snap.paidIds, ...localPaid};
  final alreadyPaid = DebugLocalWalletStore.isPaidJoin(
    remoteJoinedIds: remoteJoined,
    durablePaidIds: durablePaid,
    tournamentId: tournament.id,
  );

  final userTier =
      readSafe(() => container.read(activeUserTierProvider).value) ?? 1;
  final shareBalance =
      readSafe(() => container.read(walletProvider).shareBalance) ?? 0;
  final blocked = TournamentJoinGate.blockReason(
    signedIn: true,
    alreadyJoined: alreadyPaid,
    tournament: tournament,
    userTier: userTier,
    shareBalance: shareBalance,
  );
  if (blocked != null) {
    if (kDebugMode) {
      debugPrint(
        '[JOIN] status=blocked debit=N error=$blocked '
        'tournament=${tournament.id} paid=$alreadyPaid',
      );
    }
    snack(blocked);
    if (blocked == '이미 참가한 챌린지입니다.') {
      return TournamentJoinPlanner.unlockWhenAlreadyJoinedBlocked(
        remoteOrJenaJoined: remoteJoined.contains(tournament.id),
        durablePaidJoin: alreadyPaid,
      );
    }
    return false;
  }

  if (!_joinInFlight.add(tournament.id)) {
    return false;
  }

  var unlock = false;
  try {
    TournamentJoinPlan plan;
    try {
      final result =
          await container.read(tournamentRepositoryProvider).joinTournament(
                tournament: tournament,
              );
      plan = TournamentJoinPlanner.fromJenaSuccess(
        result: result,
        entryFeeShare: tournament.entryFeeShare,
      );
    } catch (error) {
      plan = TournamentJoinPlanner.fromJenaError(
        error: error,
        entryFeeShare: tournament.entryFeeShare,
        debugMode: kDebugMode,
        alreadyLocallyJoined: DebugLocalJoinLedger.alreadyPaid(
          localJoinedIds: durablePaid,
          tournamentId: tournament.id,
        ),
      );
    }

    if (kDebugMode) {
      debugPrint(
        '${plan.debugLog} tournament=${tournament.id} '
        'fee=${tournament.entryFeeShare} persist=${plan.persistLocalJoin}',
      );
    }

    var durableRecorded = !plan.applyDebit;
    if (plan.applyDebit) {
      final notifier = container.read(walletProvider.notifier);
      notifier.applyEntryFeeDebit(plan.debitAmount);
      final after = container.read(walletProvider);
      notifier.rememberDurableDebugShare(after.shareBalance);
      try {
        await DebugLocalWalletStore.recordPaidJoin(
          prefs: prefs,
          uid: authUser.uid,
          tournamentId: tournament.id,
          shareBalanceAfter: after.shareBalance,
          debitAmount: plan.debitAmount,
          historyTitle: kTournamentEntryHistoryTitle,
        );
        durableRecorded = true;
      } catch (e) {
        DebugLocalWalletStore.rememberInMemory(
          uid: authUser.uid,
          share: after.shareBalance,
          paidIds: {...durablePaid, tournament.id},
          history: [
            DebugLocalShareTx(
              id: 'TX_SHARE_MEM_${DateTime.now().millisecondsSinceEpoch}',
              title: kTournamentEntryHistoryTitle,
              amount: -plan.debitAmount,
              assetType: 'SHARE',
              timestampMs: DateTime.now().millisecondsSinceEpoch,
            ),
            ...DebugLocalWalletStore.cachedHistory(authUser.uid),
          ],
        );
        durableRecorded = true;
        debugPrint('[JOIN] durable prefs write failed (memory kept): $e');
      }
      readSafe(() {
        container
            .read(debugLocalShareHistoryProvider.notifier)
            .replace(DebugLocalWalletStore.cachedHistory(authUser.uid));
      });
      try {
        await container
            .read(walletRepositoryProvider)
            .logClientWalletTransaction(
              uid: authUser.uid,
              title: kTournamentEntryHistoryTitle,
              amount: -plan.debitAmount,
              assetType: 'SHARE',
            );
      } catch (e) {
        debugPrint('[JOIN] logClientWalletTransaction failed: $e');
      }
      if (plan.persistLocalJoin && kDebugMode) {
        try {
          await container.read(walletRepositoryProvider).persistDebugShareSpend(
                uid: authUser.uid,
                shareDelta: -plan.debitAmount,
                shareBalanceAfter: after.shareBalance,
                diamondBalance: after.diamondBalance,
                valueBalance: after.valueBalance,
              );
        } catch (e) {
          debugPrint('[JOIN] persistDebugShareSpend failed: $e');
        }
      }
    }

    unlock = plan.unlockRun && durableRecorded;
    if (unlock || (plan.joinedForUi && durableRecorded && plan.applyDebit)) {
      readSafe(() {
        container
            .read(localJoinedTournamentIdsProvider.notifier)
            .add(tournament.id);
      });
      try {
        await container
            .read(pushNotificationServiceProvider)
            .subscribeToTournament(
              tournament.id,
            );
      } catch (_) {}
    }

    snack(plan.snackbarMessage);
    return unlock;
  } catch (e, st) {
    debugPrint('[JOIN] failed: $e\n$st');
    snack(TournamentJoinMessages.joinPaymentFailed);
    return false;
  } finally {
    if (!unlock) {
      _joinInFlight.remove(tournament.id);
    }
  }
}
