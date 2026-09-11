import '../../../data/models/tournament_model.dart';

/// Fail-closed client checks before `POST /actions/tournaments/join`.
///
/// Does not mutate SHARE/DIA/VALUE. Server remains the ledger.
abstract final class TournamentJoinGate {
  static String? blockReason({
    required bool signedIn,
    required bool alreadyJoined,
    required TournamentModel tournament,
    required int userTier,
    required int shareBalance,
  }) {
    if (!signedIn) {
      return '로그인 후 챌린지에 참가할 수 있습니다.';
    }
    if (alreadyJoined) {
      return '이미 참가한 챌린지입니다.';
    }
    if (!tournament.isRecruiting) {
      return '현재 모집 중인 대회가 아닙니다.';
    }
    if (tournament.lockedForTier(userTier)) {
      return '내 등급보다 낮은 방은 참가할 수 없습니다.';
    }
    if (tournament.isFull) {
      return '대회 정원이 가득 찼습니다.';
    }
    if (shareBalance < tournament.entryFeeShare) {
      return 'Share 잔액이 부족합니다.';
    }
    return null;
  }
}
