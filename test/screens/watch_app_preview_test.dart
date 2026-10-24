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
}
