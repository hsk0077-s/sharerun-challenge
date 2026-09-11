import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/wallet/debug_economy_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('homeLine formats Jena and grant for the Home debug row', () {
    expect(
      const DebugEconomyStatus().homeLine,
      'DEBUG Jena: …  grant: pending',
    );
    expect(
      const DebugEconomyStatus(
        jena: DebugJenaReachability.ok,
        grant: DebugGrantPhase.done,
      ).homeLine,
      'DEBUG Jena: ok  grant: done',
    );
    expect(
      const DebugEconomyStatus(
        jena: DebugJenaReachability.fail,
        grant: DebugGrantPhase.failed,
        grantDetail: 'Connection refused',
      ).homeLine,
      'DEBUG Jena: fail  grant: failed:Connection refused',
    );
  });

  test('shortError flattens and truncates for the one-line Home readout', () {
    expect(
      DebugEconomyStatus.shortError('SocketException\nhost'),
      'SocketException host',
    );
    expect(
      DebugEconomyStatus.shortError('x' * 40).endsWith('…'),
      isTrue,
    );
    expect(DebugEconomyStatus.shortError('x' * 40).length, 33);
  });

  testWidgets('Home debug line shows Jena fail and grant done', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: DebugEconomyStatusLine()),
        ),
      ),
    );
    expect(find.textContaining('DEBUG Jena:'), findsOneWidget);

    container.read(debugEconomyStatusProvider.notifier).markJenaFail();
    container.read(debugEconomyStatusProvider.notifier).markGrantDone();
    await tester.pump();

    expect(find.text('DEBUG Jena: fail  grant: done'), findsOneWidget);
  });
}
