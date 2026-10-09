import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/screens/fair_earning_policy_screen.dart';
import 'package:share_run_challenge/screens/security_privacy_center_screen.dart';

void main() {
  testWidgets('center lists the policy and appeal entries and opens the policy',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SecurityPrivacyCenterScreen()),
    );

    expect(find.text('보안·프라이버시 센터'), findsOneWidget);
    expect(find.byKey(SecurityPrivacyCenterScreen.policyTileKey), findsOneWidget);
    expect(find.byKey(SecurityPrivacyCenterScreen.appealTileKey), findsOneWidget);

    await tester.tap(find.byKey(SecurityPrivacyCenterScreen.policyTileKey));
    await tester.pumpAndSettle();

    expect(find.byType(FairEarningPolicyScreen), findsOneWidget);
    expect(find.text('기본 원칙'), findsOneWidget);
  });

  test('policy text never claims perfect security or a lottery', () {
    final all = FairEarningPolicyScreen.sections
        .expand((s) => [s.title, ...s.lines])
        .join('\n');
    expect(all.contains('완벽'), isFalse);
    expect(all.contains('뽑기'), isFalse);
    expect(all, contains('120~210'));
    expect(all, contains('하루 최대 600 SHARE'));
  });
}
