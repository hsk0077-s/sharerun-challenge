/// 자생적 챌린지 방 개설(src-8) 참가비(SHARE) 수식.
abstract final class ChallengeEntryFee {
  /// 목표 거리(km) → 참가비 SHARE.
  ///
  /// - 1km beginner → 600
  /// - 3km intermediate → 1,200
  /// - 5km → 1,800
  /// - 10km → 3,000
  /// - 10km 초과: 3,000 + ((km - 10) ~/ 5) × 600
  ///   (15km → 3,600 / 20km → 4,200)
  static const beginner1kmShare = 600;
  static const intermediate3kmShare = 1200;

  static int forDistanceKm(int km) {
    return switch (km) {
      1 => beginner1kmShare,
      3 => intermediate3kmShare,
      5 => 1800,
      10 => 3000,
      _ when km > 10 => 3000 + ((km - 10) ~/ 5) * 600,
      _ => beginner1kmShare,
    };
  }

  static String labelShare(int share) {
    final digits = share.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return '참가비: ${share < 0 ? '-' : ''}$formatted SHARE';
  }
}
