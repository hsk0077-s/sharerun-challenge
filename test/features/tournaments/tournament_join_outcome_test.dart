import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/data/models/tournament_join_result.dart';
import 'package:share_run_challenge/features/tournaments/providers/local_joined_ids_provider.dart';
import 'package:share_run_challenge/features/tournaments/utils/tournament_join_debit.dart';
import 'package:share_run_challenge/features/tournaments/utils/tournament_join_outcome.dart';

void main() {
  const entryFee = 30000;
  const personalSponsorShare = 50000;

  test('Jena success debits entry fee once and uses paid snackbar', () {
    const joined = TournamentJoinResult(
      accepted: true,
      status: 'joined',
      shareCredited: -30000,
      shareBalance: 970000,
    );
    final plan = TournamentJoinPlanner.fromJenaSuccess(
      result: joined,
      entryFeeShare: entryFee,
    );
    expect(plan.kind, TournamentJoinKind.paid);
    expect(plan.applyDebit, isTrue);
    expect(plan.debitAmount, 30000);
    expect(plan.persistLocalJoin, isFalse);
    expect(plan.joinedForUi, isTrue);
    expect(plan.unlockRun, isTrue);
    expect(plan.showsPaidSnackbar, isTrue);
    expect(plan.snackbarMessage, contains('참가비 30000 SHARE'));
    expect(plan.snackbarMessage, isNot(contains('Entry Share locked')));
    expect(plan.debugLog, contains('debit=Y'));
    expect(kTournamentEntryHistoryTitle, '대회 참가');
  });

  test('already_joined does not debit and does not fake a paid snackbar', () {
    const again = TournamentJoinResult(
      accepted: true,
      status: 'already_joined',
      shareCredited: 0,
      shareBalance: 970000,
    );
    expect(
      TournamentJoinDebit.shouldApplyEntryFee(
        result: again,
        entryFeeShare: entryFee,
      ),
      isFalse,
    );
    final plan = TournamentJoinPlanner.fromJenaSuccess(
      result: again,
      entryFeeShare: entryFee,
    );
    expect(plan.kind, TournamentJoinKind.alreadyJoined);
    expect(plan.applyDebit, isFalse);
    expect(plan.debitAmount, 0);
    expect(plan.showsPaidSnackbar, isFalse);
    expect(plan.snackbarMessage, TournamentJoinMessages.alreadyJoined);
    expect(plan.snackbarMessage, isNot(contains('잠겼')));
    expect(plan.snackbarMessage, isNot(contains('Entry Share locked')));
    expect(plan.debugLog, contains('debit=N'));
    expect(plan.joinedForUi, isTrue);
    expect(plan.unlockRun, isTrue);
  });

  test('Jena Invalid Firebase ID token in debug uses local debit once', () {
    const error = ApiException(
      statusCode: 401,
      detail: 'Invalid Firebase ID token.',
    );
    expect(
      TournamentJoinPlanner.isJenaUnavailableForDebugFallback(error),
      isTrue,
    );
    final plan = TournamentJoinPlanner.fromJenaError(
      error: error,
      entryFeeShare: entryFee,
      debugMode: true,
      alreadyLocallyJoined: false,
    );
    expect(plan.kind, TournamentJoinKind.debugLocalPaid);
    expect(plan.applyDebit, isTrue);
    expect(plan.debitAmount, 30000);
    expect(plan.persistLocalJoin, isTrue);
    expect(plan.joinedForUi, isTrue);
    expect(plan.unlockRun, isTrue);
    expect(plan.showsPaidSnackbar, isTrue);
    expect(plan.snackbarMessage, contains('디버그'));
    expect(plan.debugLog, contains('debit=Y'));
    expect(plan.debugLog, contains('Invalid Firebase ID token'));
  });

  test('Jena auth failure in release is fail-closed with no debit', () {
    const error = ApiException(
      statusCode: 401,
      detail: 'Invalid Firebase ID token.',
    );
    final plan = TournamentJoinPlanner.fromJenaError(
      error: error,
      entryFeeShare: entryFee,
      debugMode: false,
      alreadyLocallyJoined: false,
    );
    expect(plan.kind, TournamentJoinKind.failedClosed);
    expect(plan.applyDebit, isFalse);
    expect(plan.persistLocalJoin, isFalse);
    expect(plan.joinedForUi, isFalse);
    expect(plan.unlockRun, isFalse);
    expect(plan.showsPaidSnackbar, isFalse);
    expect(plan.snackbarMessage, contains('참가·결제가 완료되지 않았습니다'));
    expect(plan.debugLog, contains('debit=N'));
  });

  test('127.0.0.1 unreachable in debug uses local debit', () {
    final error = Exception('Connection refused 127.0.0.1:8000');
    expect(
      TournamentJoinPlanner.isJenaUnavailableForDebugFallback(error),
      isTrue,
    );
    final plan = TournamentJoinPlanner.fromJenaError(
      error: error,
      entryFeeShare: entryFee,
      debugMode: true,
      alreadyLocallyJoined: false,
    );
    expect(plan.kind, TournamentJoinKind.debugLocalPaid);
    expect(plan.applyDebit, isTrue);
    expect(plan.persistLocalJoin, isTrue);
  });

  test('debug local join does not double-charge when already locally paid', () {
    const error = ApiException(
      statusCode: 401,
      detail: 'Invalid Firebase ID token.',
    );
    final plan = TournamentJoinPlanner.fromJenaError(
      error: error,
      entryFeeShare: entryFee,
      debugMode: true,
      alreadyLocallyJoined: true,
    );
    expect(plan.kind, TournamentJoinKind.alreadyJoined);
    expect(plan.applyDebit, isFalse);
    expect(plan.persistLocalJoin, isFalse);
    expect(plan.showsPaidSnackbar, isFalse);
    expect(plan.unlockRun, isTrue);
  });

  test('business-rule Jena errors stay fail-closed even in debug', () {
    const full = ApiException(
      statusCode: 409,
      detail: 'Tournament is full.',
    );
    expect(
      TournamentJoinPlanner.isJenaUnavailableForDebugFallback(full),
      isFalse,
    );
    final plan = TournamentJoinPlanner.fromJenaError(
      error: full,
      entryFeeShare: entryFee,
      debugMode: true,
      alreadyLocallyJoined: false,
    );
    expect(plan.kind, TournamentJoinKind.failedClosed);
    expect(plan.applyDebit, isFalse);
    expect(plan.unlockRun, isFalse);
    expect(plan.snackbarMessage, contains('참가·결제가 완료되지 않았습니다'));
    expect(plan.snackbarMessage, contains('대회 정원이 가득 찼습니다'));
  });

  test('sponsorship 50k remains a separate SHARE spend from entry fee', () {
    const joined = TournamentJoinResult(
      accepted: true,
      status: 'joined',
      shareCredited: -30000,
    );
    final plan = TournamentJoinPlanner.fromJenaSuccess(
      result: joined,
      entryFeeShare: entryFee,
    );
    expect(plan.debitAmount, 30000);
    expect(plan.debitAmount, isNot(personalSponsorShare));
    expect(personalSponsorShare, 50000);
    expect(kTournamentEntryHistoryTitle, isNot(contains('유니세프')));
  });

  test('legacy joined body without share_credited still plans a debit', () {
    const legacy = TournamentJoinResult(accepted: true, status: 'joined');
    final plan = TournamentJoinPlanner.fromJenaSuccess(
      result: legacy,
      entryFeeShare: 50000,
    );
    expect(plan.applyDebit, isTrue);
    expect(plan.debitAmount, 50000);
  });

  test('DebugLocalJoinLedger prefs parse is one-shot per room', () {
    expect(
      DebugLocalJoinLedger.prefsListKey('uid-1'),
      'debugLocalJoinedIds_uid-1',
    );
    expect(
      DebugLocalJoinLedger.parseJoinedIds(['room-1', '', 'room-2']),
      {'room-1', 'room-2'},
    );
    expect(
      DebugLocalJoinLedger.alreadyPaid(
        localJoinedIds: {'room-1'},
        tournamentId: 'room-1',
      ),
      isTrue,
    );
    expect(
      DebugLocalJoinLedger.alreadyPaid(
        localJoinedIds: {'room-1'},
        tournamentId: 'room-2',
      ),
      isFalse,
    );
  });

  test('local joined ids overlay accumulates rooms without double-add', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(localJoinedTournamentIdsProvider), isEmpty);
    container.read(localJoinedTournamentIdsProvider.notifier).add('room-1');
    container.read(localJoinedTournamentIdsProvider.notifier).addAll([
      'room-1',
      'room-2',
      '',
    ]);
    expect(
      container.read(localJoinedTournamentIdsProvider),
      {'room-1', 'room-2'},
    );
  });

  test('already-joined gate does not unlock the run without payment proof', () {
    expect(
      TournamentJoinPlanner.unlockWhenAlreadyJoinedBlocked(
        remoteOrJenaJoined: false,
        durablePaidJoin: false,
      ),
      isFalse,
    );
    expect(
      TournamentJoinPlanner.unlockWhenAlreadyJoinedBlocked(
        remoteOrJenaJoined: true,
        durablePaidJoin: false,
      ),
      isTrue,
    );
    expect(
      TournamentJoinPlanner.unlockWhenAlreadyJoinedBlocked(
        remoteOrJenaJoined: false,
        durablePaidJoin: true,
      ),
      isTrue,
    );
  });

  test('stale PR14 local overlay ids are not payment proof', () {
    expect(
      DebugLocalJoinLedger.alreadyPaid(
        localJoinedIds: {'demo-intermediate-3km'},
        tournamentId: 'demo-intermediate-3km',
      ),
      isTrue,
    );
    expect(
      TournamentJoinPlanner.unlockWhenAlreadyJoinedBlocked(
        remoteOrJenaJoined: false,
        durablePaidJoin: false,
      ),
      isFalse,
    );
  });
}
