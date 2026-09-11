import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/email_verification_guard.dart';
import '../../../data/models/tournament_model.dart';
import '../../wallet/providers/wallet_provider.dart';
import 'tournament_join_gate.dart';

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

  try {
    await ref.read(tournamentRepositoryProvider).joinTournament(
          tournament: tournament,
        );
    await ref.read(pushNotificationServiceProvider).subscribeToTournament(
          tournament.id,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tournament.title} joined. Entry Share locked.')),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ApiErrorMessage.from(error))),
    );
  }
}
