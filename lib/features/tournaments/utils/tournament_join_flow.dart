import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/email_verification_guard.dart';
import '../../../data/models/tournament_model.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../providers/local_joined_ids_provider.dart';
import 'tournament_join_gate.dart';
import 'tournament_join_outcome.dart';

/// Prevents double-tap from calling Jena twice before `joinedIds` updates.
final Set<String> _joinInFlight = <String>{};

/// Join a recruiting room. Returns true when the user should be treated as
/// joined (new paid join, debug local paid join, or already joined).
Future<bool> joinTournamentWithPreflight({
  required BuildContext context,
  required WidgetRef ref,
  required TournamentModel tournament,
}) async {
  final authUser = ref.read(authStateChangesProvider).value;
  if (authUser == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 챌린지에 참가할 수 있습니다.')),
      );
    }
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
  final storedLocal = DebugLocalJoinLedger.parseJoinedIds(
    prefs.getStringList(DebugLocalJoinLedger.prefsListKey(authUser.uid)),
  );
  if (storedLocal.isNotEmpty) {
    ref.read(localJoinedTournamentIdsProvider.notifier).addAll(storedLocal);
  }

  final joinedIds = ref.read(effectiveJoinedTournamentIdsProvider);
  final userTier = ref.read(activeUserTierProvider).value ?? 1;
  final shareBalance = ref.read(walletProvider).shareBalance;
  final blocked = TournamentJoinGate.blockReason(
    signedIn: true,
    alreadyJoined: joinedIds.contains(tournament.id),
    tournament: tournament,
    userTier: userTier,
    shareBalance: shareBalance,
  );
  if (blocked != null) {
    if (kDebugMode) {
      debugPrint(
        '[JOIN] status=blocked debit=N error=$blocked '
        'tournament=${tournament.id}',
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked)),
      );
    }
    return blocked == '이미 참가한 챌린지입니다.';
  }

  if (!_joinInFlight.add(tournament.id)) {
    return false;
  }

  TournamentJoinPlan plan;
  try {
    final result = await ref.read(tournamentRepositoryProvider).joinTournament(
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
        localJoinedIds: {
          ...storedLocal,
          ...ref.read(localJoinedTournamentIdsProvider),
        },
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

  if (plan.applyDebit) {
    ref.read(walletProvider.notifier).applyEntryFeeDebit(plan.debitAmount);
    unawaited(
      ref.read(walletRepositoryProvider).logClientWalletTransaction(
            uid: authUser.uid,
            title: kTournamentEntryHistoryTitle,
            amount: -plan.debitAmount,
            assetType: 'SHARE',
          ),
    );
    if (plan.persistLocalJoin && kDebugMode) {
      try {
        await ref.read(walletRepositoryProvider).persistDebugShareSpend(
              uid: authUser.uid,
              shareDelta: -plan.debitAmount,
            );
      } catch (e) {
        debugPrint('[JOIN] persistDebugShareSpend failed: $e');
      }
      final next = {
        ...storedLocal,
        ...ref.read(localJoinedTournamentIdsProvider),
        tournament.id,
      };
      await prefs.setStringList(
        DebugLocalJoinLedger.prefsListKey(authUser.uid),
        next.toList(),
      );
    }
  }

  if (plan.joinedForUi) {
    ref.read(localJoinedTournamentIdsProvider.notifier).add(tournament.id);
    try {
      await ref.read(pushNotificationServiceProvider).subscribeToTournament(
            tournament.id,
          );
    } catch (_) {}
  } else {
    _joinInFlight.remove(tournament.id);
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(plan.snackbarMessage)),
    );
  }

  return plan.joinedForUi;
}
