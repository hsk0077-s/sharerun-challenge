import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/tournaments/utils/tournament_join_outcome.dart';
import 'package:share_run_challenge/features/wallet/debug_local_wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DebugLocalWalletStore.clearCacheForTest();
    SharedPreferences.setMockInitialValues({});
  });

  test('stale grant SHARE is clamped to the durable spent wallet', () {
    expect(
      DebugLocalWalletStore.applyShareCeiling(
        incomingShare: 1000000,
        durableShare: 970000,
      ),
      970000,
    );
    expect(
      DebugLocalWalletStore.applyShareCeiling(
        incomingShare: 970051,
        durableShare: 970000,
      ),
      970051,
    );
    expect(
      DebugLocalWalletStore.applyShareCeiling(
        incomingShare: 900000,
        durableShare: 970000,
      ),
      900000,
    );
    expect(
      DebugLocalWalletStore.applyShareCeiling(
        incomingShare: 970000,
        durableShare: 970018,
      ),
      970018,
    );
  });

  test('hydrate keeps a harvest-sized in-session credit above stale prefs', () {
    expect(
      DebugLocalWalletStore.resolveHydratedShare(
        currentShare: 970018,
        durableShare: 970000,
      ),
      970018,
    );
    expect(
      DebugLocalWalletStore.resolveHydratedShare(
        currentShare: 0,
        durableShare: 970018,
      ),
      970018,
    );
    expect(
      DebugLocalWalletStore.resolveHydratedShare(
        currentShare: 1000000,
        durableShare: 970018,
      ),
      970018,
    );
    expect(
      DebugLocalWalletStore.resolveHydratedShare(
        currentShare: 970000,
        durableShare: 970018,
      ),
      970018,
    );
  });

  test('hydrate restore of a 30k join debit is rejected in debug', () {
    expect(
      DebugLocalWalletStore.shouldRejectHydrateRestore(
        currentShare: 970000,
        incomingShare: 1000000,
      ),
      isTrue,
    );
    expect(
      DebugLocalWalletStore.shouldRejectHydrateRestore(
        currentShare: 0,
        incomingShare: 1000000,
      ),
      isFalse,
    );
    expect(
      DebugLocalWalletStore.shouldRejectHydrateRestore(
        currentShare: 970000,
        incomingShare: 970051,
      ),
      isFalse,
    );
  });

  test('only Jena remote or durable paid ids prove a paid join', () {
    expect(
      DebugLocalWalletStore.isPaidJoin(
        remoteJoinedIds: const {},
        durablePaidIds: const {},
        tournamentId: 'demo-intermediate-3km',
      ),
      isFalse,
    );
    expect(
      DebugLocalWalletStore.isPaidJoin(
        remoteJoinedIds: const {},
        durablePaidIds: {'demo-intermediate-3km'},
        tournamentId: 'demo-intermediate-3km',
      ),
      isTrue,
    );
    expect(
      DebugLocalWalletStore.isPaidJoin(
        remoteJoinedIds: const {'beginner-1km-room'},
        durablePaidIds: const {},
        tournamentId: 'beginner-1km-room',
      ),
      isTrue,
    );
  });

  test('recordPaidJoin writes SHARE history 대회 참가 once per room', () async {
    final prefs = await SharedPreferences.getInstance();
    await DebugLocalWalletStore.recordPaidJoin(
      prefs: prefs,
      uid: 'uid-1',
      tournamentId: 'demo-intermediate-3km',
      shareBalanceAfter: 970000,
      debitAmount: 30000,
      historyTitle: kTournamentEntryHistoryTitle,
    );
    await DebugLocalWalletStore.recordPaidJoin(
      prefs: prefs,
      uid: 'uid-1',
      tournamentId: 'demo-intermediate-3km',
      shareBalanceAfter: 970000,
      debitAmount: 30000,
      historyTitle: kTournamentEntryHistoryTitle,
    );

    expect(prefs.getInt(DebugLocalWalletStore.shareKey('uid-1')), 970000);
    expect(
      prefs.getStringList(DebugLocalWalletStore.paidJoinKey('uid-1')),
      ['demo-intermediate-3km'],
    );
    final history = DebugLocalWalletStore.cachedHistory('uid-1');
    expect(history, hasLength(1));
    expect(history.single.title, '대회 참가');
    expect(history.single.amount, -30000);
    expect(history.single.assetType, 'SHARE');
  });

  test('mergeHistory keeps local 대회 참가 when Firestore is empty', () {
    const local = DebugLocalShareTx(
      id: 'TX_SHARE_LOCAL_1',
      title: '대회 참가',
      amount: -30000,
      assetType: 'SHARE',
      timestampMs: 1,
    );
    final merged = DebugLocalWalletStore.mergeHistory(
      remote: const [],
      local: const [local],
    );
    expect(merged, hasLength(1));
    expect(merged.single.title, '대회 참가');
    expect(merged.single.amount, -30000);
  });

  test('mergeHistory does not duplicate a Firestore receipt', () {
    const local = DebugLocalShareTx(
      id: 'TX_SHARE_LOCAL_1',
      title: '대회 참가',
      amount: -30000,
      assetType: 'SHARE',
      timestampMs: 1000,
    );
    const remote = DebugLocalShareTx(
      id: 'TX_SHARE_FS_1',
      title: '대회 참가',
      amount: -30000,
      assetType: 'SHARE',
      timestampMs: 1500,
    );
    final merged = DebugLocalWalletStore.mergeHistory(
      remote: const [remote],
      local: const [local],
    );
    expect(merged, hasLength(1));
    expect(merged.single.id, 'TX_SHARE_FS_1');
  });

  test('recordHarvestCredit writes SHARE and 줍기 history', () async {
    final prefs = await SharedPreferences.getInstance();
    await DebugLocalWalletStore.recordPaidJoin(
      prefs: prefs,
      uid: 'uid-1',
      tournamentId: 'demo-intermediate-3km',
      shareBalanceAfter: 970000,
      debitAmount: 30000,
      historyTitle: kTournamentEntryHistoryTitle,
    );
    await DebugLocalWalletStore.recordHarvestCredit(
      prefs: prefs,
      uid: 'uid-1',
      shareBalanceAfter: 970018,
      credited: 18,
    );

    expect(prefs.getInt(DebugLocalWalletStore.shareKey('uid-1')), 970018);
    expect(DebugLocalWalletStore.cachedShare('uid-1'), 970018);
    final history = DebugLocalWalletStore.cachedHistory('uid-1');
    expect(history.first.title, DebugLocalWalletStore.harvestHistoryTitle);
    expect(history.first.amount, 18);
    expect(history.first.assetType, 'SHARE');
    expect(history.any((tx) => tx.title == '대회 참가'), isTrue);
  });

  test('hydrateFromPrefs does not clobber an in-memory harvest credit', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DebugLocalWalletStore.shareKey('uid-1'), 970000);
    DebugLocalWalletStore.rememberInMemory(uid: 'uid-1', share: 970018);

    final snap = DebugLocalWalletStore.hydrateFromPrefs(prefs, 'uid-1');
    expect(snap.share, 970018);
    expect(DebugLocalWalletStore.cachedShare('uid-1'), 970018);
  });

  test('DIA/VALUE spend prefs survive hydrate and reject 1M restore', () async {
    final prefs = await SharedPreferences.getInstance();
    await DebugLocalWalletStore.persistBalances(
      prefs: prefs,
      uid: 'uid-1',
      share: 950000,
      diamond: 999970,
      value: 999500,
    );

    expect(
      DebugLocalWalletStore.shouldRejectBalanceRestore(
        current: 999970,
        incoming: 1000000,
      ),
      isTrue,
    );
    expect(
      DebugLocalWalletStore.applyBalanceCeiling(
        incoming: 1000000,
        durable: 999970,
      ),
      999970,
    );
    expect(
      DebugLocalWalletStore.applyBalanceCeiling(
        incoming: 999980,
        durable: 999970,
      ),
      999980,
    );

    final snap = DebugLocalWalletStore.hydrateFromPrefs(prefs, 'uid-1');
    expect(snap.share, 950000);
    expect(snap.diamond, 999970);
    expect(snap.value, 999500);
  });

  test('legacy debugLocalJoinedIds key is not the paid ledger', () {
    expect(
      DebugLocalWalletStore.legacyJoinedKey('uid-1'),
      'debugLocalJoinedIds_uid-1',
    );
    expect(
      DebugLocalWalletStore.paidJoinKey('uid-1'),
      isNot(DebugLocalWalletStore.legacyJoinedKey('uid-1')),
    );
  });
}
