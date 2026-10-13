import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/data/models/activity_model.dart';
import 'package:share_run_challenge/features/appeal/appeal_hold.dart';
import 'package:share_run_challenge/screens/appeal_center_screen.dart';

ActivityModel _run(
  String id, {
  ActivityValidationStatus status = ActivityValidationStatus.pending,
  DateTime? at,
  String? reason = '러닝 케이던스(120~210 SPM) 범위를 벗어났습니다.',
  double km = 3.2,
  bool appealRejected = false,
}) {
  return ActivityModel(
    id: id,
    userId: 'u1',
    distanceKm: km,
    durationSeconds: 1200,
    averagePaceSecondsPerKm: 375,
    completedAt: at ?? DateTime.utc(2026, 10, 10, 9),
    validationStatus: status,
    jenaReason: reason,
    appealRejected: appealRejected,
  );
}

Widget _screen(List<ActivityModel> runs, {String? activityId}) {
  return ProviderScope(
    overrides: [
      recentActivitiesProvider.overrideWith((ref) => Stream.value(runs)),
    ],
    child: MaterialApp(home: AppealCenterScreen(activityId: activityId)),
  );
}

void main() {
  group('which run is shown', () {
    test('verified runs are never offered for appeal', () {
      final hold = pendingHoldFor([
        _run('a', status: ActivityValidationStatus.verified),
      ]);
      expect(hold, isNull);
    });

    test('a run whose appeal an admin turned down is not offered again', () {
      final rejected = _run(
        'no',
        status: ActivityValidationStatus.rejected,
        at: DateTime.now().subtract(const Duration(days: 1)),
        appealRejected: true,
      );
      expect(rejected.needsJenaAppeal, isFalse);
      expect(pendingHoldFor([rejected]), isNull);
      expect(
        _run(
          'again',
          status: ActivityValidationStatus.rejected,
          at: DateTime.now().subtract(const Duration(days: 1)),
        ).needsJenaAppeal,
        isTrue,
      );
    });

    test('with no id the latest held run is chosen', () {
      final hold = pendingHoldFor([
        _run('old', at: DateTime.utc(2026, 10, 1)),
        _run('new', at: DateTime.utc(2026, 10, 9)),
        _run('ok', status: ActivityValidationStatus.verified),
      ]);
      expect(hold?.activity.id, 'new');
    });

    test('an id picks exactly that run, and only if it is held', () {
      final runs = [_run('a'), _run('b')];
      expect(pendingHoldFor(runs, activityId: 'b')?.activity.id, 'b');
      expect(pendingHoldFor(runs, activityId: 'zzz'), isNull);
    });

    test('the server reason is shown, and a code-only reason falls back', () {
      expect(holdReasonText('심박 곡선이 평평합니다.'), '심박 곡선이 평평합니다.');
      expect(holdReasonText('pending'), contains('확인이 더 필요'));
      expect(holdReasonText(null), contains('확인이 더 필요'));
    });
  });

  testWidgets('the banner names the real run and the server reason',
      (tester) async {
    await tester.pumpWidget(_screen([_run('a')]));
    await tester.pumpAndSettle();

    expect(find.textContaining('3.20 km 달리기'), findsOneWidget);
    expect(find.textContaining('케이던스(120~210 SPM)'), findsOneWidget);
    expect(find.textContaining('중급 3km'), findsNothing);
    expect(find.textContaining('비정상적인 GPS'), findsNothing);
  });

  testWidgets('with nothing held it says so and the submit button is off',
      (tester) async {
    await tester.pumpWidget(
      _screen([_run('a', status: ActivityValidationStatus.verified)]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appeal-empty-banner')), findsOneWidget);
    expect(find.text('소명할 기록이 없어요'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  group('which runs can be appealed', () {
    test('a rejected run is appealable for 14 days, then not', () {
      final fresh = _run('a',
          status: ActivityValidationStatus.rejected,
          at: DateTime.now().subtract(const Duration(days: 2)));
      final old = _run('b',
          status: ActivityValidationStatus.rejected,
          at: DateTime.now().subtract(const Duration(days: 15)));
      expect(fresh.needsJenaAppeal, isTrue);
      expect(old.needsJenaAppeal, isFalse);
    });

    test('verified and under-review runs are not appealable', () {
      final now = DateTime.now();
      expect(
        _run('v', status: ActivityValidationStatus.verified, at: now)
            .needsJenaAppeal,
        isFalse,
      );
      expect(
        _run('u', status: ActivityValidationStatus.underReview, at: now)
            .needsJenaAppeal,
        isFalse,
      );
    });
  });
}
