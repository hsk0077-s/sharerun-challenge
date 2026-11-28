import 'world_tour_landmarks.dart';
import 'world_tour_models.dart';
import 'world_tour_shop_art.dart';

/// The numbers the live run chip prints and the path draws.
///
/// Both use [kmLeft], which is `mission.remainingKm - runKm`. The walker
/// on the path uses [fraction], `(progressKm + runKm) / targetKm`. Those
/// two agree: the chip says "arrived" exactly when [fraction] reaches 1.
abstract final class WorldTourRunProgress {
  static double kmLeft({
    required WorldTourMission mission,
    required double runKm,
  }) {
    return mission.remainingKm - runKm;
  }

  /// 0 at the start of the mission, 1 at the landmark. Left to right.
  static double fraction({
    required WorldTourMission mission,
    required double runKm,
  }) {
    final target = mission.targetKm;
    if (target <= 0) return 0;
    final raw = (mission.progressKm + runKm) / target;
    if (!raw.isFinite) return 0;
    return raw.clamp(0.0, 1.0);
  }

  static bool arrived({
    required WorldTourMission mission,
    required double runKm,
  }) {
    return mission.targetKm > 0 && kmLeft(mission: mission, runKm: runKm) <= 0;
  }

  /// A mission whose landmark has a picture. Otherwise the path is hidden.
  static bool canDraw(WorldTourMission? mission) {
    if (mission == null || mission.targetKm <= 0) return false;
    return WorldTourLandmark.of(mission.landmarkId).hasArt;
  }

  /// Still picture behind the path. A village background when this country
  /// has one, otherwise the landmark's far approach scene. Null when
  /// neither file exists: the path is then just the road.
  static String? backdropAsset(String landmarkId) {
    final village = WorldTourShopArt.village(landmarkId);
    if (village != null) return village;
    return WorldTourLandmark.of(landmarkId).artAsset(WorldTourArtScene.far);
  }
}
