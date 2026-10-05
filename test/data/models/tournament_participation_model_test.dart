import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/tournament_participation_model.dart';

void main() {
  test('shows the server ticket reward line and does not invent a won value', () {
    final model = TournamentParticipationModel.fromFirestore(
      tournamentId: 'race',
      tournamentJson: {
        'title': '초급',
        'prizeTier': 'beginner',
        'entryFeeShare': 300,
      },
      participantJson: {
        'status': 'joined',
        'entryFeeShare': 0,
        'ticketRewardLabel': '+ 중급 참가권 1장 (다음 2회 유효)',
      },
    );

    expect(model.ticketRewardLabel, '+ 중급 참가권 1장 (다음 2회 유효)');
    expect(model.ticketRewardLabel, isNot(contains('원')));
  });
}
