import '../../../core/api/api_exception.dart';
import '../../../data/models/tournament_join_result.dart';
import 'tournament_join_debit.dart';

/// Client payment-history title. Same `users/{uid}/wallet_transactions`
/// collection as personal sponsorship.
const kTournamentEntryHistoryTitle = '대회 참가';

enum TournamentJoinKind {
  /// New Jena join — debit Home SHARE once and write history.
  paid,

  /// Idempotent re-join — no debit, no "paid" snackbar.
  alreadyJoined,

  /// Jena rejected the body (`accepted: false`).
  rejected,

  /// Jena unreachable / Invalid Firebase ID token in debug — local debit.
  debugLocalPaid,

  /// Release (or non-recoverable) Jena failure — no join, no debit.
  failedClosed,
}

/// Pure join decision so USB logs and tests can assert debit / snackbar
/// without spinning a widget tree.
class TournamentJoinPlan {
  const TournamentJoinPlan({
    required this.kind,
    required this.applyDebit,
    required this.debitAmount,
    required this.snackbarMessage,
    required this.debugLog,
    this.persistLocalJoin = false,
    this.joinedForUi = false,
  });

  final TournamentJoinKind kind;
  final bool applyDebit;
  final int debitAmount;
  final String snackbarMessage;
  final String debugLog;

  /// Write Firestore SHARE increment + prefs lock (debug fallback only).
  final bool persistLocalJoin;

  /// Treat the user as joined for navigation / UI (paid, already, debug).
  final bool joinedForUi;

  bool get showsPaidSnackbar =>
      kind == TournamentJoinKind.paid || kind == TournamentJoinKind.debugLocalPaid;
}

abstract final class TournamentJoinMessages {
  static const alreadyJoined =
      '이미 참가한 챌린지입니다. 참가비는 다시 차감되지 않습니다.';
  static const rejected = '참가가 거절되었습니다. 참가비는 차감되지 않았습니다.';
  static const joinPaymentFailed =
      '참가·결제가 완료되지 않았습니다. 서버 연결 또는 인증에 실패했습니다.';

  static String paid(int fee) => '참가 완료. 참가비 $fee SHARE가 잠겼습니다.';

  static String debugLocalPaid(int fee) =>
      '참가 완료(디버그). 참가비 $fee SHARE가 차감되었습니다.';
}

abstract final class DebugLocalJoinLedger {
  static String prefsListKey(String uid) => 'debugLocalJoinedIds_$uid';

  static Set<String> parseJoinedIds(List<String>? stored) {
    if (stored == null || stored.isEmpty) return {};
    return stored.where((id) => id.isNotEmpty).toSet();
  }

  static bool alreadyPaid({
    required Set<String> localJoinedIds,
    required String tournamentId,
  }) {
    if (tournamentId.isEmpty) return false;
    return localJoinedIds.contains(tournamentId);
  }
}

abstract final class TournamentJoinPlanner {
  static TournamentJoinPlan fromJenaSuccess({
    required TournamentJoinResult result,
    required int entryFeeShare,
  }) {
    if (result.alreadyJoined) {
      return const TournamentJoinPlan(
        kind: TournamentJoinKind.alreadyJoined,
        applyDebit: false,
        debitAmount: 0,
        snackbarMessage: TournamentJoinMessages.alreadyJoined,
        debugLog: '[JOIN] status=already_joined debit=N error=',
        joinedForUi: true,
      );
    }
    if (!result.accepted) {
      return TournamentJoinPlan(
        kind: TournamentJoinKind.rejected,
        applyDebit: false,
        debitAmount: 0,
        snackbarMessage: TournamentJoinMessages.rejected,
        debugLog: '[JOIN] status=${result.status} debit=N error=rejected',
      );
    }
    if (!TournamentJoinDebit.shouldApplyEntryFee(
      result: result,
      entryFeeShare: entryFeeShare,
    )) {
      return TournamentJoinPlan(
        kind: TournamentJoinKind.rejected,
        applyDebit: false,
        debitAmount: 0,
        snackbarMessage: TournamentJoinMessages.rejected,
        debugLog:
            '[JOIN] status=${result.status.isEmpty ? 'joined' : result.status} '
            'debit=N error=no_entry_fee',
      );
    }
    final debit = TournamentJoinDebit.debitAmount(
      result: result,
      entryFeeShare: entryFeeShare,
    );
    final status = result.status.isEmpty ? 'joined' : result.status;
    return TournamentJoinPlan(
      kind: TournamentJoinKind.paid,
      applyDebit: true,
      debitAmount: debit,
      snackbarMessage: TournamentJoinMessages.paid(debit),
      debugLog: '[JOIN] status=$status debit=Y amount=$debit error=',
      joinedForUi: true,
    );
  }

  static TournamentJoinPlan fromJenaError({
    required Object error,
    required int entryFeeShare,
    required bool debugMode,
    required bool alreadyLocallyJoined,
  }) {
    if (alreadyLocallyJoined) {
      return TournamentJoinPlan(
        kind: TournamentJoinKind.alreadyJoined,
        applyDebit: false,
        debitAmount: 0,
        snackbarMessage: TournamentJoinMessages.alreadyJoined,
        debugLog: '[JOIN] status=already_joined debit=N error=${_errorForLog(error)}',
        joinedForUi: true,
      );
    }

    final unavailable = isJenaUnavailableForDebugFallback(error);
    if (debugMode && unavailable && entryFeeShare > 0) {
      return TournamentJoinPlan(
        kind: TournamentJoinKind.debugLocalPaid,
        applyDebit: true,
        debitAmount: entryFeeShare,
        snackbarMessage: TournamentJoinMessages.debugLocalPaid(entryFeeShare),
        debugLog:
            '[JOIN] status=debug_local_paid debit=Y amount=$entryFeeShare '
            'error=${_errorForLog(error)}',
        persistLocalJoin: true,
        joinedForUi: true,
      );
    }

    final detail = error is ApiException ? error.userMessage : error.toString();
    return TournamentJoinPlan(
      kind: TournamentJoinKind.failedClosed,
      applyDebit: false,
      debitAmount: 0,
      snackbarMessage: '${TournamentJoinMessages.joinPaymentFailed} ($detail)',
      debugLog: '[JOIN] status=failed_closed debit=N error=${_errorForLog(error)}',
    );
  }

  static String _errorForLog(Object error) {
    if (error is ApiException) {
      return 'HTTP ${error.statusCode} ${error.detail}';
    }
    return error.toString();
  }

  /// Auth / unreachable Jena. Not business-rule 400/403/409 (full, locked, broke).
  static bool isJenaUnavailableForDebugFallback(Object error) {
    if (error is ApiException) {
      final detail = error.detail.toLowerCase();
      if (error.statusCode == 401) return true;
      if (detail.contains('id token') ||
          detail.contains('unauthoriz') ||
          detail.contains('not authenticated') ||
          detail.contains('firebase id token')) {
        return true;
      }
      if (error.statusCode >= 400 && error.statusCode < 500) return false;
      if (error.statusCode >= 500) return true;
    }
    final text = error.toString().toLowerCase();
    if (text.contains('invalid firebase id token')) return true;
    if (text.contains('firebase id token is required')) return true;
    if (text.contains('socket')) return true;
    if (text.contains('connection refused')) return true;
    if (text.contains('failed host lookup')) return true;
    if (text.contains('clientexception')) return true;
    if (text.contains('127.0.0.1')) return true;
    if (text.contains('connection reset')) return true;
    if (text.contains('network is unreachable')) return true;
    if (text.contains('timed out') || text.contains('timeout')) return true;
    if (text.contains('xmlhttprequest')) return true;
    return false;
  }
}
