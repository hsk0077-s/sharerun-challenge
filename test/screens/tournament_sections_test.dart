import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/screens/tournament_screen.dart';

TournamentModel _t(String id, {String kind = '', int tierAnimal = 0}) =>
    TournamentModel(
      id: id,
      title: id,
      targetDistanceKm: 5,
      entryFeeShare: 0,
      winnerRewardValue: 0,
      donationValue: 0,
      minParticipantsBep: 5,
      maxParticipants: 50,
      participantCount: 0,
      requiredTier: 1,
      status: TournamentStatus.recruiting,
      sponsorName: '후원',
      kind: kind,
      tierAnimal: tierAnimal,
    );

void main() {
  test('kind and tierAnimal are read from the server document', () {
    final t = TournamentModel.fromJson(id: 'a', json: {
      'title': '비글 대회',
      'kind': 'tier',
      'tierAnimal': 2,
      'status': 'recruiting',
    });
    expect(t.isTierTournament, isTrue);
    expect(t.isFreeTournament, isFalse);
    expect(t.tierAnimal, 2);

    final plain = TournamentModel.fromJson(id: 'b', json: {'title': '일반'});
    expect(plain.kind, '');
    expect(plain.tierAnimal, 0);
  });

  test('rooms split into tier, free and other; my tier comes first', () {
    final rooms = [
      _t('other-1'),
      _t('free-1', kind: 'free'),
      _t('tier-wolf', kind: 'tier', tierAnimal: 3),
      _t('tier-turtle', kind: 'tier', tierAnimal: 1),
      _t('tier-beagle', kind: 'tier', tierAnimal: 2),
    ];
    final g = TournamentSections.group(rooms, TierAnimal.wolf);
    expect(
        g.tier.map((r) => r.id), ['tier-wolf', 'tier-turtle', 'tier-beagle']);
    expect(g.free.map((r) => r.id), ['free-1']);
    expect(g.other.map((r) => r.id), ['other-1']);
  });

  test('without a tier (snail) tier rooms keep the low-to-high order', () {
    final rooms = [
      _t('b', kind: 'tier', tierAnimal: 2),
      _t('a', kind: 'tier', tierAnimal: 1),
    ];
    final g = TournamentSections.group(rooms, null);
    expect(g.tier.map((r) => r.id), ['a', 'b']);
  });
}
