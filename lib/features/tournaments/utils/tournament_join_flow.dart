import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/email_verification_guard.dart';
import '../../../data/models/tournament_model.dart';

Future<void> joinTournamentWithPreflight({
  required BuildContext context,
  required WidgetRef ref,
  required TournamentModel tournament,
}) async {
  final authUser = ref.read(authStateChangesProvider).value;
  if (authUser == null) {
    return;
  }
  final verified = await ensureEmailVerified(
    context: context,
    user: authUser,
  );
  if (!verified) {
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
