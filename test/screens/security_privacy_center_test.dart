import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/privacy/ai_learning_tile.dart';
import 'package:share_run_challenge/screens/fair_earning_policy_screen.dart';
import 'package:share_run_challenge/screens/security_privacy_center_screen.dart';

void main() {
  testWidgets('AI switch shows the server value and saves server-first',
      (tester) async {
    var server = false;
    final saved = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiLearningProvider.overrideWith((ref) async => server),
          aiLearningSaverProvider.overrideWithValue((bool next) async {
            saved.add(next);
            server = next;
            return server;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AiLearningTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Switch sw() => tester.widget<Switch>(find.byKey(AiLearningTile.switchKey));
    expect(sw().value, isFalse);

    await tester.tap(find.byKey(AiLearningTile.switchKey));
    await tester.pumpAndSettle();

    expect(saved, [true]);
    expect(sw().value, isTrue);
  });

  testWidgets('a slow save shows progress, then the value the server returned',
      (tester) async {
    final reply = Completer<bool>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiLearningProvider.overrideWith((ref) async => false),
          aiLearningSaverProvider.overrideWithValue(
            (bool next) => reply.future,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AiLearningTile())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AiLearningTile.switchKey));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(AiLearningTile.switchKey), findsNothing);

    reply.complete(true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(find.byKey(AiLearningTile.switchKey)).value,
      isTrue,
    );
  });

  testWidgets('a failed save keeps the server value and says so',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiLearningProvider.overrideWith((ref) async => false),
          aiLearningSaverProvider.overrideWithValue(
            (bool next) async => throw Exception('offline'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AiLearningTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AiLearningTile.switchKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Switch>(find.byKey(AiLearningTile.switchKey)).value,
      isFalse,
    );
    expect(find.textContaining('저장하지 못했어요'), findsOneWidget);
  });

  testWidgets('center lists the policy and appeal entries and opens the policy',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiLearningProvider.overrideWith((ref) async => false)],
        child: const MaterialApp(home: SecurityPrivacyCenterScreen()),
      ),
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
