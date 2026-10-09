abstract final class EconomyConstants {
  static const signupRewardSrv = 100;
  /// Verified 1km runs on different days that set the grade (server-owned).
  static const trialRunsRequired = 3;
  static const referralTrialRunsRequired = 3;
  /// Server credits this as SHARE across the 10,000 and 40,000 trial milestones.
  static const trialCompletionRewardSrv = 50000;
  static const referralRewardSrv = 300;
  static const maxReferralPayouts = 10;

  /// 마이페이지 닉네임 변경 수수료 (DIA).
  static const nicknameChangeFeeDia = 100;

  static const dailyCapKm = 5.0;
  static const dailyCapSrvTokens = 50;
  static const srvTokensPerKm = 10;

  /// Same truncation as server `int(distance_km * SRV_TOKENS_PER_KM)`.
  static int effortValueTokens(double distanceKm) {
    if (!distanceKm.isFinite || distanceKm <= 0) return 0;
    return (distanceKm * srvTokensPerKm).toInt();
  }

  /// 만보기 채굴 — 0.1km당 1 SHARE, 보폭 추정.
  static const pedometerCoinIntervalKm = 0.1;
  static const pedometerSharePerCoin = 1;
  static const pedometerStrideMeters = 0.75;

  /// 혼자 뛰기/걷기 출석 인정 최소 거리.
  static const streakMinKm = 1.0;
  static const streakBonusDays = 7;
  static const streakBonusDia = 10;

  /// 러닝화 수명 경보 — 500km의 80%.
  static const shoeMileageWarnKm = 400.0;
  static const defaultPreferredRunHour = 19;

  static const diamondRefundPolicy =
      '구매 후 7일 이내, 100% 미사용 분에 한해 환불 가능';
}
