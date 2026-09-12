/// 자생적 챌린지 방 개설(src-8) 참가비(SHARE) 수식.
abstract final class ChallengeEntryFee {
  /// 목표 거리(km) → 참가비 SHARE.
  ///
  /// - 1km beginner → 30,000
  /// - 3km intermediate → 60,000
  /// - 5km → 70,000
  /// - 10km → 100,000
  /// - 10km 초과: 100,000 + ((km - 10) ~/ 5) × 50,000
  ///   (15km → 150,000 / 20km → 200,000)
  static const beginner1kmShare = 30000;
  static const intermediate3kmShare = 60000;

  static int forDistanceKm(int km) {
    return switch (km) {
      1 => beginner1kmShare,
      3 => intermediate3kmShare,
      5 => 70000,
      10 => 100000,
      _ when km > 10 => 100000 + ((km - 10) ~/ 5) * 50000,
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
