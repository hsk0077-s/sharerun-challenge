import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/tournament_model.dart';

/// 방 개설 직후 Firestore 스냅샷 지연을 메우기 위한 로컬 선행 삽입 버퍼.
class LocalUserRoomsNotifier extends Notifier<List<TournamentModel>> {
  @override
  List<TournamentModel> build() => const [];

  void prepend(TournamentModel room) {
    state = [room, ...state.where((r) => r.id != room.id)];
  }
}

final localUserRoomsProvider =
    NotifierProvider<LocalUserRoomsNotifier, List<TournamentModel>>(
  LocalUserRoomsNotifier.new,
);

/// [3단계] 챌린지 로비용 토너먼트 목록 — Firestore Stream + 로컬 개설 방 병합.
final tournamentListProvider =
    Provider<AsyncValue<List<TournamentModel>>>((ref) {
  final remote = ref.watch(tournamentRoomsProvider);
  final local = ref.watch(localUserRoomsProvider);

  return remote.when(
    data: (rooms) {
      final remoteIds = rooms.map((r) => r.id).toSet();
      final pendingLocal =
          local.where((r) => !remoteIds.contains(r.id)).toList();
      return AsyncValue.data([...pendingLocal, ...rooms]);
    },
    loading: () => local.isEmpty
        ? const AsyncValue.loading()
        : AsyncValue.data(local),
    error: (error, stack) => local.isEmpty
        ? AsyncValue.error(error, stack)
        : AsyncValue.data(local),
  );
});
