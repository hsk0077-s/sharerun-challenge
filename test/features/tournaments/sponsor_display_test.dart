import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/tournaments/utils/sponsor_display.dart';

void main() {
  test('a charity name is never shown as the sponsor', () {
    expect(displaySponsorName('UNICEF'), operatorSponsorName);
    expect(displaySponsorName('UNICEF Partner'), operatorSponsorName);
    expect(displaySponsorName('유니세프 파트너'), operatorSponsorName);
    expect(displaySponsorName('unicef'), operatorSponsorName);
  });

  test('an empty name falls back to the operator', () {
    expect(displaySponsorName(''), operatorSponsorName);
    expect(displaySponsorName('   '), operatorSponsorName);
  });

  test('a real sponsor name is kept', () {
    expect(displaySponsorName('쉐어런 스폰서'), '쉐어런 스폰서');
  });
}
