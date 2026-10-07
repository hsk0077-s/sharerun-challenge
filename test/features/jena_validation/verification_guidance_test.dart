import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/jena_validation/verification_guidance.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('distance copy uses the room distance and the 1km floor', () {
    expect(formatVerifiedDistanceKm(2), '2km');
    expect(formatVerifiedDistanceKm(0.4), '1km');
    expect(formatVerifiedDistanceKm(21.0975), '21.1km');

    final room = verificationGuidanceCopy(
      roomDistanceKm: 2,
      requiresHeartRate: false,
    );
    expect(room.title, '검증 안내');
    expect(room.body, contains('2km'));
    expect(room.body, contains('120~210'));
    expect(room.body, contains('보폭과 GPS'));
    expect(room.body, contains('상급·하프·파이널'));
    expect(room.body, contains('기록은 언제나, 보상은 검증된 달리기에만'));
    expect(room.body, isNot(contains('이 대회는 워치 심박이 있어야')));

    final race = verificationGuidanceCopy(
      roomDistanceKm: 10,
      requiresHeartRate: true,
    );
    expect(race.body, contains('10km'));
    expect(race.body, contains('이 대회는 워치 심박이 있어야 완주로 인정돼요.'));
  });

  test('watch heart rate is only the advanced company tiers', () {
    expect(roomRequiresWatchHeartRate('advanced'), isTrue);
    expect(roomRequiresWatchHeartRate('half'), isTrue);
    expect(roomRequiresWatchHeartRate('final'), isTrue);
    expect(roomRequiresWatchHeartRate('beginner'), isFalse);
    expect(roomRequiresWatchHeartRate(''), isFalse);
  });

  testWidgets('다시 보지 않기 skips the next prompt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => confirmVerificationGuidance(
                context,
                roomDistanceKm: 2,
                requiresHeartRate: false,
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('검증 안내'), findsOneWidget);
    expect(find.textContaining('기록은 언제나'), findsOneWidget);

    await tester.tap(find.text('다시 보지 않기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인하고 참가'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('검증 안내'), findsNothing);
  });

  testWidgets('닫기 cancels the join and keeps the prompt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final accepted = await confirmVerificationGuidance(
                    context,
                    roomDistanceKm: 3,
                    requiresHeartRate: false,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(accepted ? 'joined' : 'cancelled')),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('cancelled'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(verificationGuidanceDismissedKey), isNot(true));
  });
}
