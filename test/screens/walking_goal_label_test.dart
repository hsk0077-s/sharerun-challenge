import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/screens/solo_pedometer_screen.dart';

String _comma(int n) => n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

void main() {
  test('before the tier goal: shows the percent of the tier goal', () {
    expect(
      walkingGoalLabel(
          percent: 62, complete: false, steps: 2800, comma: _comma),
      '등급 목표 달성률: 62%',
    );
  });

  test('tier goal done but bar not full: says so and counts to 10,000', () {
    expect(
      walkingGoalLabel(
          percent: 100, complete: true, steps: 4738, comma: _comma),
      '등급 목표 달성! 만보까지 5,262걸음',
    );
  });

  test('10,000 steps reached', () {
    for (final steps in [10000, 12345]) {
      expect(
        walkingGoalLabel(
            percent: 100, complete: true, steps: steps, comma: _comma),
        '등급 목표 달성 · 만보 달성!',
      );
    }
  });
}
