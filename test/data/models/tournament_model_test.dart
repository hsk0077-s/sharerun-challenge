import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';

TournamentModel _room({
  int maxParticipants = 0,
  int participantCount = 0,
  int minParticipantsBep = 10,
  int requiredTier = 2,
  String status = 'recruiting',
}) {
  return TournamentModel.fromJson(
    id: 'room-1',
    json: {
      'title': 'SRC 5K',
      'targetDistanceKm': 5,
      'entryFeeShare': 1000,
      'winnerRewardValue': 500,
      'donationValue': 200,
      'minParticipantsBep': minParticipantsBep,
      'maxParticipants': maxParticipants,
      'participantCount': participantCount,
      'requiredTier': requiredTier,
      'status': status,
      'sponsorName': 'UNICEF',
    },
  );
}

void main() {
  group('TournamentModel.fromJson', () {
    test('parses core tournament fields', () {
      final room = _room();

      expect(room.id, 'room-1');
      expect(room.title, 'SRC 5K');
      expect(room.targetDistanceKm, 5);
      expect(room.entryFeeShare, 1000);
      expect(room.sponsorName, 'UNICEF');
      expect(room.isRecruiting, isTrue);
    });

    test('maps cancelled_bep_not_met status', () {
      final room = _room(status: 'cancelled_bep_not_met');

      expect(room.status, TournamentStatus.cancelledBepNotMet);
      expect(room.isRecruiting, isFalse);
    });
  });

  group('TournamentModel tier lock', () {
    test('locks lower-tier rooms for higher-tier users', () {
      final room = _room(requiredTier: 1);

      expect(room.lockedForTier(2), isTrue);
      expect(room.lockedForTier(1), isFalse);
    });
  });

  group('TournamentModel capacity', () {
    test('treats zero maxParticipants as unlimited capacity', () {
      final room = _room(maxParticipants: 0, participantCount: 99);

      expect(room.hasCapacityLimit, isFalse);
      expect(room.isFull, isFalse);
      expect(room.recruitmentSummary, '99/10 BEP');
    });

    test('marks room full when participant count reaches cap', () {
      final room = _room(maxParticipants: 20, participantCount: 20);

      expect(room.hasCapacityLimit, isTrue);
      expect(room.isFull, isTrue);
      expect(room.recruitmentSummary, '20/10 BEP · 20/20 capacity');
    });
  });
}
