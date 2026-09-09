/// 자생적 챌린지 방 개설(src-8) 참가비(SHARE) 수식.
abstract final class ChallengeEntryFee {
  /// 목표 거리(km) → 참가비 SHARE.
  ///
  /// - 1km → 30,000
  /// - 3km → 50,000
  /// - 5km → 70,000
  /// - 10km → 100,000
  /// - 10km 초과: 100,000 + ((km - 10) ~/ 5) × 50,000
  ///   (15km → 150,000 / 20km → 200,000)
  static int forDistanceKm(int km) {
    return switch (km) {
      1 => 30000,
      3 => 50000,
      5 => 70000,
      10 => 100000,
      _ when km > 10 => 100000 + ((km - 10) ~/ 5) * 50000,
      _ => 30000,
    };
  }
}
