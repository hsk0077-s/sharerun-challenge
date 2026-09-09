abstract final class RouteNames {
  static const login = '/login';
  static const home = '/home';
  static const onboarding = '/onboarding';
  static const termsAgreement = '/terms-agreement';
  static const smartWatchSync = '/smart-watch-sync';

  /// 온보딩 단계 alias — [SrcOnboardingController] 선언적 라우팅.
  static const onboardingSocialSignup = login;
  static const onboardingSensitiveConsent = termsAgreement;
  static const onboardingDeviceSync = smartWatchSync;
  /// 3.5 Soft-prompt는 별도 path 없이 [smartWatchSync] 위 바텀시트로 표시.
  static const onboardingPushSoftPrompt = smartWatchSync;
  static const garminAuth = '/garmin-auth';
  /// src-3 스마트워치 연동 가이드 — [smartWatchSync] alias.
  static const watchConnection = smartWatchSync;
  /// src-4 외부 기기 OAuth 웹뷰 — [garminAuth] alias.
  static const externalOauthWebview = garminAuth;
  static const mainDashboard = '/main-dashboard';
  /// Legacy alias — always resolves to [preliminaryEval] (src-6 등급 심사).
  static const levelTestRunning = '/preliminary-eval';
  /// Solo / tiering run screen (alias of [preliminaryEval]).
  static const soloRun = levelTestRunning;
  static const challengeLobby = '/challenge-lobby';
  static const createChallengeRoom = '/create-challenge-room';
  static const challengeDetail = '/challenge-detail';
  static const liveRunning = '/live-running';
  /// 실전 라이브 러닝 트래커 (Jena 검증 파이프라인).
  static const inChallenge = '/in-challenge';
  static const runResult = '/run-result';
  static const onboardingMyPage = '/onboarding-my-page';
  static const onboardingStoreFunding = '/onboarding-store-funding';
  static const tournament = '/tournament';

  /// Beginner 1km room (dashboard "초보 1km 챌린지").
  static const beginner1kmRoomId = 'beginner-1km-room';

  /// Intermediate 3km room (dashboard "중급 3km 챌린지").
  static const intermediate3kmRoomId = 'intermediate-3km-room';

  static String challengeDetailForRoom(String roomId) {
    return '$challengeDetail?roomId=${Uri.encodeComponent(roomId)}';
  }

  static String tournamentDetail(String tournamentId) {
    return '$tournament?tournamentId=${Uri.encodeComponent(tournamentId)}';
  }

  static String tournamentRoomDetail(String tournamentId) {
    return '/tournaments/$tournamentId';
  }

  static const myTournaments = '/my-tournaments';
  static const mapCrew = '/map-crew';
  static const wallet = '/wallet';
  /// 나의 지갑 상세 (홈 카드 / 만보기 지갑 아이콘).
  static const myWallet = '/my-wallet';
  static const String myWalletName = 'myWallet';
  static const myPage = '/my-page';
  static const profile = myPage;

  /// 마이페이지 종합 설정 (src-12 하위).
  static const settings = '/settings';
  /// 설정 > 이용약관·개인정보 처리방침 웹뷰.
  static const settingsLegal = '/settings-legal';

  /// Tab 2 — 상점/기부 펀딩 (src-13). [store]는 동일 경로 alias.
  static const shop = '/shop';
  static const store = shop;
  /// 상점 포커스 쿼리 — DIA 아이템 / VALUE 기부 펀딩.
  static const storeFocusItems = 'items';
  static const storeFocusDonate = 'donate';

  static String storeWithFocus(String focus) {
    return '$store?focus=${Uri.encodeComponent(focus)}';
  }

  /// Tab 4 — 러닝크루 (src-18). [crews]는 동일 경로 alias.
  static const crew = '/crew';
  static const crews = crew;

  static const runTracking = '/run-tracking';
  static const paymentWebView = '/payment-webview';
  /// 대회 스폰서 결제. [SponsorPaymentArgs] extra 필수. src-17과 혼동 금지.
  static const sponsorPayment = '/sponsor-payment';
  static const watchSettings = '/watch-settings';
  static const healthDataConsent = '/health-data-consent';
  static const winnerDemo = '/winner-demo';
  /// Named GoRouter name: `preliminaryEval` / path: `/preliminary-eval`.
  static const preliminaryEval = '/preliminary-eval';
  static const preliminaryEvalName = 'preliminaryEval';
  static const onboardingPreliminaryEval = preliminaryEval;
  /// src-6 혼자 뛰기 / 등급 심사 alias.
  static const preliminaryRun = preliminaryEval;
  /// 스펙명 — [preliminaryEval]과 동일.
  static const preliminaryRuns = preliminaryEval;
  static const preliminaryRunsName = preliminaryEvalName;

  /// src-10 개인 자유 달리기 GPS 트래킹. 예비 심사 [soloRun]과 분리.
  static const soloRunTracking = '/solo-run-tracking';
  static const soloRunTrackingName = 'soloRunTracking';
  static const freeRun = soloRunTracking;

  /// 캐주얼 만보기 채굴. GPS/Jena 없이 걸음·거리만 사용.
  static const String soloPedometer = 'soloPedometer';
  static const soloPedometerPath = '/solo-pedometer';

  // ── 17장 시나리오 하위 경로 ──
  static const notificationCenter = '/notification-center';
  /// 알림센터 alias (src-28).
  static const notifications = notificationCenter;
  /// 재화 채굴·획득·소모 히스토리 — 알림센터 결제/히스토리 탭.
  static const walletHistory = '/wallet-history';
  static const notificationTabPayment = 'payment';
  static const externalPayment = '/external-payment';
  /// src-14 Google Play 인앱 충전소. 웹뷰 PG는 폐기하고 이 경로로 통일.
  static const inAppBilling = '/in-app-billing';
  /// 달팽이→치타 25티어 도감 (마이페이지 캐릭터/티어 진입).
  static const tierBook = '/tier-book';
  static const snailToCheetahBook = tierBook;
  /// 천사 도감 named route — [pushNamed]용. path는 [angelBookPath].
  static const String angelBook = 'angelBook';
  static const angelBookPath = '/angel-book';
  static const itemInventory = '/item-inventory';
  static const battlePass = '/battle-pass';
  static const subscriptionManagement = '/subscription-management';
  static const brandSponsor = '/brand-sponsor';
  /// src-17 개인스폰서 목적형 후원결제. 천사 연대기 CTA는 이 경로로 직행한다.
  static const personalSponsor = '/personal-sponsor';
  static const crewManager = '/crew-manager';
  static const refund = '/refund';
  static const web3Wallet = '/web3-wallet';
  static const stampTour = '/stamp-tour';
  static const hallOfFame = '/hall-of-fame';
  static const appeal = '/appeal';
  /// src-27 기록 소명 및 고객센터 named route. path는 [appeal].
  static const String appealCenter = 'appealCenter';
  /// 마일리지/프로 툴 (src-15).
  static const proTools = '/pro-tools';
  /// Alias — 러닝 기어 & 프로 툴 진입점.
  static const runningGearProTools = proTools;

  static String externalPaymentWithAmount(int amountWon) {
    return '$externalPayment?amount=${Uri.encodeComponent('$amountWon')}';
  }
}
