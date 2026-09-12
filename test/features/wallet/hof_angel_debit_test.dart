import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/screens/hall_of_fame_screen.dart';
import 'package:share_run_challenge/screens/personal_sponsor_screen.dart';

void main() {
  test('angel sponsorship is a 50k SHARE debit', () {
    expect(AngelSponsorDebit.shareAmount, 50000);
    expect(AngelSponsorDebit.canAfford(49999), isFalse);
    expect(AngelSponsorDebit.canAfford(50000), isTrue);
    expect(AngelSponsorDebit.canAfford(1000000), isTrue);
  });

  test('Hall of Fame donate is a 500 VALUE debit without auto-credit', () {
    expect(HallOfFameDonate.valueAmount, 500);
    expect(HallOfFameDonate.canAfford(499), isFalse);
    expect(HallOfFameDonate.canAfford(500), isTrue);
    expect(HallOfFameDonate.canAfford(1000000), isTrue);
  });
}
