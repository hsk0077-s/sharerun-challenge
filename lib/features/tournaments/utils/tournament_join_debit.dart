import '../../../data/models/tournament_join_result.dart';

/// Decides whether a successful join HTTP response should debit Home SHARE.
///
/// Jena is the ledger. This only mirrors the entry fee onto [walletProvider]
/// the same way personal sponsorship calls `subtractShare`, and only once.
abstract final class TournamentJoinDebit {
  /// True for a newly accepted join. False for idempotent re-join, failures
  /// (those never produce a result), and zero-fee rooms.
  static bool shouldApplyEntryFee({
    required TournamentJoinResult result,
    required int entryFeeShare,
  }) {
    if (entryFeeShare <= 0) return false;
    if (!result.accepted) return false;
    if (result.alreadyJoined) return false;
    if (result.shareCredited > 0) return false;
    if (result.status == 'joined' || result.status.isEmpty) return true;
    return result.shareCredited < 0;
  }

  static int debitAmount({
    required TournamentJoinResult result,
    required int entryFeeShare,
  }) {
    if (result.shareCredited < 0) return -result.shareCredited;
    return entryFeeShare;
  }
}
