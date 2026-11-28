import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_models.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_run_progress.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_shop_art.dart';

void main() {
  test('km left matches the chip, and the fraction matches that remainder', () {
    final mission = _mission(target: 5, progress: 3);
    expect(
      WorldTourRunProgress.kmLeft(mission: mission, runKm: 1),
      1,
    );
    expect(
      WorldTourRunProgress.fraction(mission: mission, runKm: 1),
      0.8,
    );
    expect(
      WorldTourRunProgress.arrived(mission: mission, runKm: 1),
      isFalse,
    );

    expect(
      WorldTourRunProgress.kmLeft(mission: mission, runKm: 2),
      0,
    );
    expect(
      WorldTourRunProgress.fraction(mission: mission, runKm: 2),
      1,
    );
    expect(
      WorldTourRunProgress.arrived(mission: mission, runKm: 2),
      isTrue,
    );
  });

  test('a run past the landmark stays at the landmark', () {
    final mission = _mission(target: 5, progress: 4);
    expect(
      WorldTourRunProgress.kmLeft(mission: mission, runKm: 2),
      closeTo(-1, 0.001),
    );
    expect(
      WorldTourRunProgress.fraction(mission: mission, runKm: 2),
      1,
    );
  });

  test('backdrop follows the country and is absent when there is no picture',
      () {
    expect(
      WorldTourRunProgress.backdropAsset('eiffel_tower'),
      WorldTourShopArt.village('eiffel_tower'),
    );
    expect(
      WorldTourRunProgress.backdropAsset('gwanghwamun'),
      'assets/images/world_tour/gwanghwamun_approach_far.webp',
    );
    expect(WorldTourRunProgress.backdropAsset(''), isNull);
    expect(WorldTourRunProgress.canDraw(null), isFalse);
    expect(
      WorldTourRunProgress.canDraw(
          _mission(target: 5, progress: 0, landmarkId: '')),
      isFalse,
    );
    expect(
      WorldTourRunProgress.canDraw(_mission(target: 5, progress: 0)),
      isTrue,
    );
  });
}

WorldTourMission _mission({
  required double target,
  required double progress,
  String landmarkId = 'eiffel_tower',
}) {
  return WorldTourMission(
    missionId: 'm1',
    title: 'landmark',
    countryCode: 'FR',
    landmarkId: landmarkId,
    targetKm: target,
    order: 1,
    progressKm: progress,
    completed: false,
  );
}
