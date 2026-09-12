import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/stamp/stamp_tour_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('landmark stamps survive a restart', () async {
    const store = StampTourProgressStore();
    await store.write(
      const StampTourProgress(
        visitedLandmarkIds: {'gangbyeon', 'namsan'},
        rewardedLandmarkIds: {'gangbyeon'},
        walkMissionCompleted: true,
        walkDistanceKm: 1.2,
        walkRewardClaimed: true,
        walkDateKey: '2026-09-12',
      ),
    );

    final restored = await const StampTourProgressStore().read(
      todayKey: '2026-09-12',
    );
    expect(restored.visitedLandmarkIds, {'gangbyeon', 'namsan'});
    expect(restored.rewardedLandmarkIds, {'gangbyeon'});
    expect(restored.walkMissionCompleted, isTrue);
    expect(restored.walkDistanceKm, 1.2);
    expect(restored.walkRewardClaimed, isTrue);
  });

  test('daily walk mission resets after KST midnight, stamps stay', () async {
    const store = StampTourProgressStore();
    await store.write(
      const StampTourProgress(
        visitedLandmarkIds: {'modoil'},
        rewardedLandmarkIds: {'modoil'},
        walkMissionCompleted: true,
        walkDistanceKm: 1.0,
        walkRewardClaimed: true,
        walkDateKey: '2026-09-11',
      ),
    );

    final nextDay = await const StampTourProgressStore().read(
      todayKey: '2026-09-12',
    );
    expect(nextDay.visitedLandmarkIds, {'modoil'});
    expect(nextDay.rewardedLandmarkIds, {'modoil'});
    expect(nextDay.walkMissionCompleted, isFalse);
    expect(nextDay.walkDistanceKm, 0);
    expect(nextDay.walkRewardClaimed, isFalse);
    expect(nextDay.walkDateKey, '2026-09-12');
  });
}
