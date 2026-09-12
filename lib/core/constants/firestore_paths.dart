abstract final class FirestorePaths {
  static const users = 'users';
  static const tournaments = 'tournaments';
  static const activities = 'activities';
  static const diamondBoxes = 'diamondBoxes';
  static const crewRankings = 'crewRankings';
  static const crews = 'crews';
  static const paymentIntents = 'paymentIntents';
  static const walletTransactions = 'walletTransactions';
  static const appeals = 'appeals';
  static const purchases = 'purchases';
  static const stampLandmarks = 'stampLandmarks';

  /// Remote official stamp-tour catalog. Ops replace this doc instead of
  /// shipping a new client. Shape: `{ landmarks: [ {id, name, lat, lng} ] }`.
  static const stampTourConfig = 'config/stamp_tour';

  static String user(String uid) => '$users/$uid';

  /// 클라이언트 결제/소모 장부. 앱 재설치 후 로그인 시 히스토리 복원용.
  static String userWalletTransactions(String uid) =>
      '${user(uid)}/wallet_transactions';

  /// 시스템·Jena 소명 알림. 앱 재설치 후 로그인 시 복원용.
  static String userNotifications(String uid) =>
      '${user(uid)}/notifications';

  static String userRetentionPushes(String uid) =>
      '${user(uid)}/retentionPushes';

  static String tournament(String tournamentId) {
    return '$tournaments/$tournamentId';
  }

  static String tournamentParticipant(String tournamentId, String uid) {
    return '${tournament(tournamentId)}/participants/$uid';
  }

  static String activity(String activityId) {
    return '$activities/$activityId';
  }

  /// 온보딩 워치 토큰 핸드오프 문서 (원본 HR/케이던스는 기록하지 않음).
  static String userWatchLink(String uid) => '$activities/watch-link-$uid';

  static String userCollectedDiamondBox(String uid, String boxId) {
    return '$users/$uid/collectedDiamondBoxes/$boxId';
  }

  static String appeal(String appealId) => '$appeals/$appealId';

  static String purchase(String purchaseId) => '$purchases/$purchaseId';
}
