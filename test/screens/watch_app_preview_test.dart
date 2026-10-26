import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/api/identity_api_client.dart';
import 'package:share_run_challenge/features/auth/login_connection_providers.dart';
import 'package:share_run_challenge/screens/watch_app_preview_screen.dart';

class _PairingApi implements IdentityApiClient {
  _PairingApi({this.fail = false});

  final bool fail;
  var calls = 0;
  var revoked = 0;
  var revokedOne = <String>[];
  var watches = <ConnectedWatch>[
    const ConnectedWatch(id: 'w1', label: '내 갤럭시 워치'),
    const ConnectedWatch(id: 'w2', label: 'Wear OS 워치'),
  ];

  @override
  Future<WatchPairingCode> requestWatchPairingCode() async {
    calls++;
    if (fail) throw StateError('down');
    return const WatchPairingCode(
      code: '482910',
      expiresIn: Duration(seconds: 300),
    );
  }

  @override
  Future<List<ConnectedWatch>> listWatchDevices() async => List.of(watches);

  @override
  Future<void> revokeWatchDevice(String id) async {
    revokedOne.add(id);
    watches = watches.where((w) => w.id != id).toList();
  }

  @override
  Future<void> revokeWatches() async {
    revoked++;
    if (fail) throw StateError('down');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _PairingApi api) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [identityApiClientProvider.overrideWithValue(api)],
    child: MaterialApp(
      theme: SrcTheme.night,
      home: const WatchAppPreviewScreen(),
    ),
  ));
}

void main() {
  testWidgets('watch preview lists every platform marked 예정', (tester) async {
    await _pump(tester, _PairingApi());
    for (final n in ['갤럭시 워치', '안드로이드 워치 (Wear OS)', '스마트 밴드 (샤오미 등)', '가민', '애플 워치']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('예정'), findsNWidgets(5));
  });

  testWidgets('the pairing button shows the 6-digit code and a countdown',
      (tester) async {
    final api = _PairingApi();
    await _pump(tester, api);
    expect(find.byKey(WatchAppPreviewScreen.pairingCodeKey), findsNothing);

    await tester.tap(find.byKey(WatchAppPreviewScreen.pairingButtonKey));
    await tester.pump();
    await tester.pump();
    expect(api.calls, 1);
    expect(find.text('482910'), findsOneWidget);
    expect(find.text('남은 시간 05:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('남은 시간 04:59'), findsOneWidget);

    await tester.pump(const Duration(seconds: 299));
    expect(find.byKey(WatchAppPreviewScreen.pairingCodeKey), findsNothing);
  });

  testWidgets('a failed request shows a message and no code', (tester) async {
    await _pump(tester, _PairingApi(fail: true));
    await tester.tap(find.byKey(WatchAppPreviewScreen.pairingButtonKey));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(WatchAppPreviewScreen.pairingErrorKey), findsOneWidget);
    expect(find.byKey(WatchAppPreviewScreen.pairingCodeKey), findsNothing);
  });

  testWidgets('disconnecting all watches asks first and then calls the server',
      (tester) async {
    final api = _PairingApi();
    await _pump(tester, api);
    await tester.ensureVisible(find.byKey(WatchAppPreviewScreen.revokeButtonKey));
    await tester.tap(find.byKey(WatchAppPreviewScreen.revokeButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('연결된 워치를 모두 해제할까요?'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(api.revoked, 0);

    await tester.tap(find.byKey(WatchAppPreviewScreen.revokeButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 해제'));
    await tester.pumpAndSettle();
    expect(api.revoked, 1);
    expect(find.byKey(WatchAppPreviewScreen.revokeDoneKey), findsOneWidget);
  });

  testWidgets('a failed disconnect shows a message, not the done line',
      (tester) async {
    final api = _PairingApi(fail: true);
    await _pump(tester, api);
    await tester.ensureVisible(find.byKey(WatchAppPreviewScreen.revokeButtonKey));
    await tester.tap(find.byKey(WatchAppPreviewScreen.revokeButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 해제'));
    await tester.pumpAndSettle();
    expect(find.byKey(WatchAppPreviewScreen.pairingErrorKey), findsOneWidget);
    expect(find.byKey(WatchAppPreviewScreen.revokeDoneKey), findsNothing);
  });

  testWidgets('the phone lists connected watches and removes just one',
      (tester) async {
    final api = _PairingApi();
    await _pump(tester, api);
    await tester.pumpAndSettle();
    expect(find.text('연결된 워치 2/3'), findsOneWidget);
    expect(find.text('내 갤럭시 워치'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('watch-revoke-w1')));
    await tester.tap(find.byKey(const Key('watch-revoke-w1')));
    await tester.pumpAndSettle();
    expect(api.revokedOne, ['w1']);
    expect(find.text('연결된 워치 1/3'), findsOneWidget);
    expect(find.text('내 갤럭시 워치'), findsNothing);
    expect(api.revoked, 0);
  });
}
