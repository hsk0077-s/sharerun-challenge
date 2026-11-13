import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/activity_model.dart';
import 'package:share_run_challenge/screens/watch_run_record_screen.dart';

ActivityModel _activity({
  String id = 'watch_abc',
  double km = 3.10,
}) {
  return ActivityModel(
    id: id,
    userId: 'user-1',
    distanceKm: km,
    durationSeconds: 1180,
    averagePaceSecondsPerKm: 380,
    completedAt: DateTime.utc(2026, 11, 10, 6, 20),
    validationStatus: ActivityValidationStatus.verified,
    jenaReason: null,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  String? activityId,
  List<ActivityModel> recent = const [],
  Future<ActivityModel?> Function(String id)? lookup,
  Duration fallbackAfter = Duration.zero,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recentActivitiesProvider.overrideWith((ref) => Stream.value(recent)),
      ],
      child: MaterialApp(
        home: WatchRunRecordScreen(
          activityId: activityId,
          lookup: lookup ?? ((_) async => null),
          fallbackAfter: fallbackAfter,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the matching run when it is already on the phone',
      (tester) async {
    final activity = _activity();
    await _pumpScreen(
      tester,
      activityId: activity.id,
      recent: [activity],
    );
    expect(find.byKey(WatchRunRecordScreen.distanceKey), findsOneWidget);
    expect(find.text('3.10 km'), findsOneWidget);
    expect(find.byKey(WatchRunRecordScreen.fallbackKey), findsNothing);
  });

  testWidgets('shows a syncing then fallback state if the run is not uploaded yet',
      (tester) async {
    await _pumpScreen(
      tester,
      activityId: 'watch_missing',
      recent: const [],
      fallbackAfter: const Duration(milliseconds: 30),
    );
    expect(find.byKey(WatchRunRecordScreen.syncingKey), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(WatchRunRecordScreen.fallbackKey), findsOneWidget);
    expect(find.byKey(WatchRunRecordScreen.seeListKey), findsOneWidget);
    expect(find.byKey(WatchRunRecordScreen.distanceKey), findsNothing);
  });

  testWidgets('loads the run by id even if it is not in the recent list',
      (tester) async {
    final activity = _activity(id: 'watch_direct', km: 1.25);
    await _pumpScreen(
      tester,
      activityId: 'watch_direct',
      recent: const [],
      lookup: (id) async => id == 'watch_direct' ? activity : null,
    );
    await tester.pump();
    expect(find.text('1.25 km'), findsOneWidget);
  });
}
