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

  test('debug harvest log is tagged [HARVEST] with source', () {
    expect(
      DebugLocalHarvest.resultLog(
        credited: true,
        amount: 18,
        source: 'local',
        walletShare: 970018,
      ),
      '[HARVEST] credited=Y amount=18 source=local walletShare=970018',
    );
    expect(
      DebugLocalHarvest.resultLog(
        credited: true,
        amount: 18,
        source: 'jena',
        walletShare: 970018,
      ),
      '[HARVEST] credited=Y amount=18 source=jena walletShare=970018',
    );
    expect(
      DebugLocalHarvest.resultLog(
        credited: false,
        amount: 0,
        source: 'jena',
      ),
      '[HARVEST] credited=N amount=0 source=jena',
    );
  });
}
