import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/features/tournaments/utils/tournament_join_gate.dart';

TournamentModel _room({
  int entryFeeShare = 30000,
  int maxParticipants = 20,
  int participantCount = 1,
  int requiredTier = 1,
  String status = 'recruiting',
}) {
  return TournamentModel.fromJson(
    id: 'room-1',
    json: {
      'title': 'SRC 1K',
      'targetDistanceKm': 1,
      'entryFeeShare': entryFeeShare,
      'winnerRewardValue': 500,
      'donationValue': 200,
      'minParticipantsBep': 10,
      'maxParticipants': maxParticipants,
      'participantCount': participantCount,
      'requiredTier': requiredTier,
      'status': status,
      'sponsorName': 'UNICEF',
    },
  );
}

void main() {
  test('blocks unsigned-in join without touching wallet', () {
    expect(
      TournamentJoinGate.blockReason(
        signedIn: false,
        alreadyJoined: false,
        tournament: _room(),
        userTier: 1,
        shareBalance: 1000000,
      ),
      '로그인 후 챌린지에 참가할 수 있습니다.',
    );
  });

  test('blocks already joined, full, locked, and insufficient SHARE', () {
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: true,
        tournament: _room(),
        userTier: 1,
        shareBalance: 1000000,
      ),
      '이미 참가한 챌린지입니다.',
    );
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: false,
        tournament: _room(status: 'active'),
        userTier: 1,
        shareBalance: 1000000,
      ),
      '현재 모집 중인 대회가 아닙니다.',
    );
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: false,
        tournament: _room(requiredTier: 1),
        userTier: 3,
        shareBalance: 1000000,
      ),
      '내 등급보다 낮은 방은 참가할 수 없습니다.',
    );
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: false,
        tournament: _room(maxParticipants: 10, participantCount: 10),
        userTier: 1,
        shareBalance: 1000000,
      ),
      '대회 정원이 가득 찼습니다.',
    );
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: false,
        tournament: _room(entryFeeShare: 30000),
        userTier: 1,
        shareBalance: 100,
      ),
      'Share 잔액이 부족합니다.',
    );
  });

  test('allows a recruiting room when SHARE and tier are valid', () {
    expect(
      TournamentJoinGate.blockReason(
        signedIn: true,
        alreadyJoined: false,
        tournament: _room(),
        userTier: 1,
        shareBalance: 1000000,
      ),
      isNull,
    );
  });
}
