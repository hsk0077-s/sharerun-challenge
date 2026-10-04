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
    int extraEntryTickets = 0,
    int? prizeEntryShare,
    int prizeTicketCost = 0,
    int freeTicketBalance = 0,
    bool payingWithTickets = false,
  }) {
    final ticketOpens = extraEntryTickets > 0 && extraEntryCanOpen(tournament);
    if (!signedIn) {
      return '로그인 후 챌린지에 참가할 수 있습니다.';
    }
    if (alreadyJoined) {
      return '이미 참가한 챌린지입니다.';
    }
    if (!tournament.isRecruiting && !ticketOpens) {
      return '현재 모집 중인 대회가 아닙니다.';
    }
    if (tournament.lockedForTier(userTier)) {
      return '내 등급보다 낮은 방은 참가할 수 없습니다.';
    }
    if (tournament.isFull && !ticketOpens) {
      return '대회 정원이 가득 찼습니다.';
    }
    if (tournament.isPrizeRace && prizeEntryShare != null) {
      if (payingWithTickets) {
        if (prizeTicketCost <= 0 || freeTicketBalance < prizeTicketCost) {
          return '무료 참가권이 부족합니다.';
        }
        return null;
      }
      if (prizeEntryShare > 0 && shareBalance < prizeEntryShare) {
        return 'Share 잔액이 부족합니다.';
      }
      return null;
    }
    if (shareBalance < tournament.entryFeeShare) {
      return 'Share 잔액이 부족합니다.';
    }
    return null;
  }

  /// Full, or recruiting already closed, on a room that is not a prize race
  /// and not cancelled or finished.
  static bool extraEntryCanOpen(TournamentModel tournament) {
    if (tournament.isPrizeRace || tournament.isTerminal) return false;
    return !tournament.isRecruiting || tournament.isFull;
  }

  static bool canAttemptJoin({
    required bool signedIn,
    required bool alreadyJoined,
    required TournamentModel tournament,
    required int userTier,
    int extraEntryTickets = 0,
  }) {
    if (!signedIn || alreadyJoined || tournament.lockedForTier(userTier)) {
      return false;
    }
    if (tournament.isRecruiting && !tournament.isFull) return true;
    return extraEntryTickets > 0 && extraEntryCanOpen(tournament);
  }
}
