import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/pedometer/debug_local_harvest.dart';

void main() {
  test('debug harvest credits locally only in debug when there is SHARE to claim',
      () {
    expect(
      DebugLocalHarvest.shouldCreditOnJenaFailure(
        debugMode: true,
        toClaim: 29,
      ),
      isTrue,
    );
    expect(
      DebugLocalHarvest.shouldCreditOnJenaFailure(
        debugMode: true,
        toClaim: 0,
      ),
      isFalse,
    );
    expect(
      DebugLocalHarvest.shouldCreditOnJenaFailure(
        debugMode: false,
        toClaim: 29,
      ),
      isFalse,
    );
  });

  test('debug harvest log is tagged [DEBUG LOCAL]', () {
    expect(
      DebugLocalHarvest.successLog(credited: 29, shareBalance: 1000029),
      '[DEBUG LOCAL] harvest +29 SHARE walletShare=1000029',
    );
  });
}
