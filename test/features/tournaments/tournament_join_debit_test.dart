import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/tournament_join_result.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/features/tournaments/utils/tournament_join_debit.dart';
import 'package:share_run_challenge/features/tournaments/utils/tournament_join_gate.dart';
import 'package:share_run_challenge/features/tournaments/utils/tournament_join_outcome.dart';

TournamentModel _room({int entryFeeShare = 30000}) {
  return TournamentModel.fromJson(
    id: 'room-1',
    json: {
      'title': 'SRC 1K',
      'targetDistanceKm': 1,
      'entryFeeShare': entryFeeShare,
      'winnerRewardValue': 500,
      'donationValue': 200,
      'minParticipantsBep': 10,
      'maxParticipants': 20,
      'participantCount': 1,
      'requiredTier': 1,
      'status': 'recruiting',
      'sponsorName': 'UNICEF',
    },
  );
}

void main() {
  test('new join result debits entry fee exactly once', () {
    const joined = TournamentJoinResult(
      accepted: true,
      status: 'joined',
      shareCredited: -30000,
      shareBalance: 970000,
    );
    expect(
      TournamentJoinDebit.shouldApplyEntryFee(
        result: joined,
        entryFeeShare: 30000,
      ),
      isTrue,
    );
    expect(
      TournamentJoinDebit.debitAmount(
        result: joined,
        entryFeeShare: 30000,
      ),
      30000,
    );
  });

  test('legacy joined body without share_credited still debits', () {
    const legacy = TournamentJoinResult(accepted: true, status: 'joined');
    expect(
      TournamentJoinDebit.shouldApplyEntryFee(
        result: legacy,
        entryFeeShare: 50000,
      ),
      isTrue,
    );
    expect(
      TournamentJoinDebit.debitAmount(
        result: legacy,
        entryFeeShare: 50000,
      ),
      50000,
    );
  });

  test('already_joined does not debit SHARE', () {
    const again = TournamentJoinResult(
      accepted: true,
      status: 'already_joined',
      shareCredited: 0,
      shareBalance: 970000,
    );
    expect(
      TournamentJoinDebit.shouldApplyEntryFee(
        result: again,
        entryFeeShare: 30000,
      ),
      isFalse,
    );
    final planSnack = TournamentJoinPlanner.fromJenaSuccess(
      result: again,
      entryFeeShare: 30000,
    );
    expect(planSnack.showsPaidSnackbar, isFalse);
    expect(planSnack.snackbarMessage, isNot(contains('Entry Share locked')));
  });

  test('failed or zero-fee join does not debit', () {
    expect(
      TournamentJoinDebit.shouldApplyEntryFee(
        result: const TournamentJoinResult(accepted: false, status: 'joined'),
        entryFeeShare: 30000,
      ),
      isFalse,
    );
    expect(
      TournamentJoinDebit.shouldApplyEntryFee(
        result: const TournamentJoinResult(accepted: true, status: 'joined'),
        entryFeeShare: 0,
      ),
      isFalse,
    );
  });

  test('gate blocks failed joins so debit is never considered', () {
    expect(
      TournamentJoinGate.blockReason(
        signedIn: false,
        alreadyJoined: false,
        tournament: _room(),
        userTier: 1,
        shareBalance: 1000000,
      ),
      isNotNull,
    );
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: true,
        tournament: _room(),
        userTier: 1,
        shareBalance: 1000000,
      ),
      isNotNull,
    );
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: false,
        tournament: _room(),
        userTier: 1,
        shareBalance: 100,
      ),
      isNotNull,
    );
  });

  test('join debit is the entry fee; sponsorship 50k is a separate SHARE spend',
      () {
    const joined = TournamentJoinResult(
      accepted: true,
      status: 'joined',
      shareCredited: -30000,
    );
    expect(
      TournamentJoinDebit.debitAmount(
        result: joined,
        entryFeeShare: 30000,
      ),
      30000,
    );
    const personalSponsorShare = 50000;
    expect(personalSponsorShare, 50000);
    expect(
      TournamentJoinDebit.shouldApplyEntryFee(
        result: joined,
        entryFeeShare: personalSponsorShare,
      ),
      isTrue,
    );
    expect(
      TournamentJoinDebit.debitAmount(
        result: joined,
        entryFeeShare: personalSponsorShare,
      ),
      30000,
    );
  });

  test('TournamentJoinResult parses Jena join snapshot', () {
    final parsed = TournamentJoinResult.fromJson({
      'accepted': true,
      'status': 'joined',
      'share_credited': -30000,
      'share_balance': 970000,
    });
    expect(parsed.accepted, isTrue);
    expect(parsed.alreadyJoined, isFalse);
    expect(parsed.shareCredited, -30000);
    expect(parsed.shareBalance, 970000);
    expect(
      TournamentJoinResult.fromJson({'status': 'already_joined'}).alreadyJoined,
      isTrue,
    );
  });
}
