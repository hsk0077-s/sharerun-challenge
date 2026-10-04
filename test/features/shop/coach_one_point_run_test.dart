import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/coach_one_point_run.dart';

void main() {
  test('only a server use unlocks the run', () {
    expect(coachOnePointStatusUnlocks('used'), isTrue);
    expect(coachOnePointStatusUnlocks('already_used'), isTrue);
    expect(coachOnePointStatusUnlocks('subscriber'), isFalse);
    expect(coachOnePointStatusUnlocks(''), isFalse);
  });
}
