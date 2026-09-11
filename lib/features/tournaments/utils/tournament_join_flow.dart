import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/email_verification_guard.dart';
import '../../../data/models/tournament_model.dart';
import '../../wallet/providers/wallet_provider.dart';
import 'tournament_join_debit.dart';
import 'tournament_join_gate.dart';

/// Prevents double-tap from calling Jena twice before `joinedIds` updates.
final Set<String> _joinInFlight = <String>{};

Future<void> joinTournamentWithPreflight({
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
    return;
  }
  final verified = await ensureEmailVerified(
    context: context,
    user: authUser,
  );
  if (!verified) {
    return;
  }

  final joinedIds = ref.read(joinedTournamentIdsProvider).value ?? const {};
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked)),
      );
    }
    return;
  }

  if (!_joinInFlight.add(tournament.id)) {
    return;
  }

  try {
    final result = await ref.read(tournamentRepositoryProvider).joinTournament(
          tournament: tournament,
        );
    if (TournamentJoinDebit.shouldApplyEntryFee(
      result: result,
      entryFeeShare: tournament.entryFeeShare,
    )) {
      final debit = TournamentJoinDebit.debitAmount(
        result: result,
        entryFeeShare: tournament.entryFeeShare,
      );
      ref.read(walletProvider.notifier).applyEntryFeeDebit(debit);
      unawaited(
        ref.read(walletRepositoryProvider).logClientWalletTransaction(
              uid: authUser.uid,
              title: '대회 참가',
              amount: -debit,
              assetType: 'SHARE',
            ),
      );
    }
  } catch (error) {
    _joinInFlight.remove(tournament.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ApiErrorMessage.from(error))),
    );
    return;
  }

  try {
    await ref.read(pushNotificationServiceProvider).subscribeToTournament(
          tournament.id,
        );
  } catch (_) {}
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${tournament.title} joined. Entry Share locked.')),
  );
}
