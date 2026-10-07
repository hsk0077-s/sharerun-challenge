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

  group('TournamentModel cash prize copy', () {
    test('hides a prize taken from the entry fee', () {
      final room = TournamentModel.fromJson(
        id: 'user-room',
        json: {
          'entryFeeShare': 600000,
          'winnerRewardValue': 240000,
          'donationValue': 120000,
        },
      );

      expect(room.cashPrizePoolLabel, isNull);
    });

    test('hides an empty pool on a room with no sponsor prize', () {
      final room = TournamentModel.fromJson(
        id: 'user-room',
        json: {
          'entryFeeShare': 600000,
          'winnerRewardValue': 0,
          'donationValue': 0,
        },
      );

      expect(room.cashPrizePoolLabel, isNull);
    });

    test('keeps a prize that is not a cut of the entry fee', () {
      expect(_room().cashPrizePoolLabel, 'Donation pool: 200 Value');
    });
  });

  group('TournamentModel capacity', () {
    test('treats zero maxParticipants as unlimited capacity', () {
      final room = _room(maxParticipants: 0, participantCount: 99);

      expect(room.hasCapacityLimit, isFalse);
      expect(room.isFull, isFalse);
      expect(room.recruitmentSummary, '참가자 99명');
      expect(room.recruitmentSummary, isNot(contains('BEP')));
    });

    test('marks room full when participant count reaches cap', () {
      final room = _room(maxParticipants: 20, participantCount: 20);

      expect(room.hasCapacityLimit, isTrue);
      expect(room.isFull, isTrue);
      expect(room.recruitmentSummary, '참가자 20/20명');
      expect(room.recruitmentSummary, isNot(contains('BEP')));
    });
  });
}
