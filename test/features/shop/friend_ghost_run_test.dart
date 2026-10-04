import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/friend_ghost_run.dart';

void main() {
  test('only a spent friend ticket shows that pace', () {
    expect(friendGhostStatusUnlocks('used'), isTrue);
    expect(friendGhostStatusUnlocks('already_used'), isTrue);
    expect(friendGhostStatusUnlocks('own_best'), isFalse);
    expect(friendGhostStatusUnlocks(''), isFalse);
  });

  test('pace label is minutes and seconds per km', () {
    expect(formatPaceSecPerKm(285), '4:45 /km');
    expect(formatPaceSecPerKm(300), '5:00 /km');
  });
}
