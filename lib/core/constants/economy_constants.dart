abstract final class EconomyConstants {
  static const signupRewardSrv = 100;
  static const trialRunsRequired = 5;
  static const trialCompletionRewardSrv = 500;
  static const referralRewardSrv = 300;
  static const maxReferralPayouts = 10;

  /// 마이페이지 닉네임 변경 수수료 (DIA).
  static const nicknameChangeFeeDia = 100;

  static const dailyCapKm = 5.0;
  static const dailyCapSrvTokens = 50;
  static const srvTokensPerKm = 10;

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
