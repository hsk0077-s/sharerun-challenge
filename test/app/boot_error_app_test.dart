import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/boot_error_app.dart';

void main() {
  testWidgets('shows a message and retries on tap', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      BootErrorApp(onRetry: () async => retries++),
    );

    expect(find.byKey(const Key('boot-error-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('boot-error-retry')));
    await tester.pumpAndSettle();

    expect(retries, 1);
    expect(find.byKey(const Key('boot-error-retry')), findsOneWidget);
  });
}
