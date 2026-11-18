import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/features/iap/providers/iap_providers.dart';
import 'package:share_run_challenge/features/iap/widgets/iap_lifecycle_host.dart';

void main() {
  tearDown(() => AppEnv.debugInAppPurchasesOverride = null);

  testWidgets('스위치가 꺼져 있으면 결제 컨트롤러를 만들지 않는다', (tester) async {
    AppEnv.debugInAppPurchasesOverride = false;
    var created = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapPurchaseControllerProvider.overrideWith((ref) {
            created++;
            throw StateError('must not be created');
          }),
        ],
        child: const MaterialApp(
          home: IapLifecycleHost(child: Text('child')),
        ),
      ),
    );
    expect(find.text('child'), findsOneWidget);
    expect(created, 0);
  });

  testWidgets('스위치가 켜져 있으면 컨트롤러를 만든다', (tester) async {
    AppEnv.debugInAppPurchasesOverride = true;
    var created = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapPurchaseControllerProvider.overrideWith((ref) {
            created++;
            throw StateError('created');
          }),
        ],
        child: const MaterialApp(
          home: IapLifecycleHost(child: Text('child')),
        ),
      ),
    );
    expect(created, greaterThan(0));
    tester.takeException();
  });
}
