import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';

/// Debug USB overlay: rooms joined via the local debit path (Jena down).
class LocalJoinedTournamentIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String tournamentId) {
    if (tournamentId.isEmpty || state.contains(tournamentId)) return;
    state = {...state, tournamentId};
  }

  void addAll(Iterable<String> ids) {
    final next = {...state, ...ids.where((id) => id.isNotEmpty)};
    if (next.length == state.length && state.containsAll(next)) return;
    state = next;
  }
}

final localJoinedTournamentIdsProvider =
    NotifierProvider<LocalJoinedTournamentIds, Set<String>>(
  LocalJoinedTournamentIds.new,
);

/// Firestore participants ∪ debug-local joins. Use this for Join gates / UI.
final effectiveJoinedTournamentIdsProvider = Provider<Set<String>>((ref) {
  final remote = ref.watch(joinedTournamentIdsProvider).value ?? const {};
  final local = ref.watch(localJoinedTournamentIdsProvider);
  if (local.isEmpty) return remote;
  return {...remote, ...local};
});
