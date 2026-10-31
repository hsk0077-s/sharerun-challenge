import '../../l10n/remaining_surface.dart';

/// 앱 전역 UI 문자열.
///
/// Intl 패키지 도입 전까지 하드코딩 문자열을 이곳에 모읍니다.
abstract final class AppStrings {
  // ── Login (Screen 1) ──────────────────────────────────────────────
  static const loginLogoMark = '쉐어런';
  static const loginTitle = '쉐어런';
  static String get loginSubtitle => RemainingSurface.trNow('app.loginSubtitle', '세계를 향한 나눔의 질주');

  static String get loginGoogle => RemainingSurface.trNow('app.loginGoogle', 'Google로 계속하기');
  static const loginApple = 'Apple로 계속하기';
  static String get loginNaver => RemainingSurface.trNow('app.loginNaver', 'Naver로 계속하기');
  static String get loginKakao => RemainingSurface.trNow('app.loginKakao', 'Kakao로 계속하기');

  static String get loginReferralLabel => RemainingSurface.trNow('app.loginReferralLabel', '추천 코드가 있으신가요?');
  static String get loginReferralHint => RemainingSurface.trNow('app.loginReferralHint', '추천 코드를 입력하세요...');
  static String get referralRedeemEntry => RemainingSurface.trNow('app.referralRedeemEntry', '초대 코드 입력');
  static String get referralRedeemSubmit => RemainingSurface.trNow('app.referralRedeemSubmit', '등록');
  static String get referralRedeemSuccess => RemainingSurface.trNow('app.referralRedeemSuccess', '10,000 SHARE 지급');
  static String get referralRedeemInvalid => RemainingSurface.trNow('app.referralRedeemInvalid', '없는 초대 코드예요');
  static String get referralRedeemSelf => RemainingSurface.trNow('app.referralRedeemSelf', '본인 코드는 입력할 수 없어요');
  static String get referralRedeemAlready => RemainingSurface.trNow('app.referralRedeemAlready', '이미 초대 코드를 입력했어요');
  static String get referralRedeemExpired => RemainingSurface.trNow('app.referralRedeemExpired', '가입 후 7일이 지나 입력할 수 없어요');
  static String get referralRedeemFailed => RemainingSurface.trNow('app.referralRedeemFailed', '초대 코드를 등록하지 못했어요');
  static String get referralRedeemDone => RemainingSurface.trNow('app.referralRedeemDone', '초대한 친구: 입력 완료');

  static String get loginGuest => RemainingSurface.trNow('app.loginGuest', '게스트(테스트)로 시작하기');
  static String get loginGuestLoading => RemainingSurface.trNow('app.loginGuestLoading', '게스트 로그인 중...');
  static String get loginGuestNote => RemainingSurface.trNow('app.loginGuestNote', '게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.');

  static String loginComingSoon(String provider) => RemainingSurface.trNow('app.loginComingSoon', '\$provider 로그인은 준비 중입니다.', {'provider': provider});
  static String loginSaveFailed(Object error) => RemainingSurface.trNow('app.loginSaveFailed', '로그인 저장 실패: \$error', {'error': error});

  /// 확인된 이메일로 기존 계정을 찾지 못했을 때, 계정을 만들기 전에 묻는다.
  static String get existingAccountTitle => RemainingSurface.trNow('app.existingAccountTitle', '처음 가입할 때 어떤 방법을 쓰셨나요?');
  static String get existingAccountCreate => RemainingSurface.trNow('app.existingAccountCreate', '새로 시작하기');
  static String get existingAccountCreateHint => RemainingSurface.trNow('app.existingAccountCreateHint', '기억나지 않거나 처음이신가요?');
  static const existingAccountCancel = '취소';
  static String get existingAccountGoogle => RemainingSurface.trNow('app.existingAccountGoogle', '구글로 가입했어요');
  static String get existingAccountKakao => RemainingSurface.trNow('app.existingAccountKakao', '카카오로 가입했어요');
  static String get existingAccountNaver => RemainingSurface.trNow('app.existingAccountNaver', '네이버로 가입했어요');
  static String get existingAccountApple => RemainingSurface.trNow('app.existingAccountApple', '애플로 가입했어요');
  static String get existingAccountNotFound => RemainingSurface.trNow('app.existingAccountNotFound', '그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.');
  static String get existingAccountEmpty => existingAccountNotFound;
  static String get linkConfirmYes => RemainingSurface.trNow('app.linkConfirmYes', '네, 연결할게요');
  static String get linkConfirmNo => RemainingSurface.trNow('app.linkConfirmNo', '아니에요, 다시 고를게요');

  static String subjectParticle(String word) =>
      _hangulParticle(word, withBatchim: '이', without: '가');

  static String objectParticle(String word) =>
      _hangulParticle(word, withBatchim: '을', without: '를');

  static String _hangulParticle(
    String word, {
    required String withBatchim,
    required String without,
  }) {
    if (word.isEmpty) return withBatchim;
    final code = word.runes.last;
    if (code < 0xAC00 || code > 0xD7A3) return without;
    final hasBatchim = (code - 0xAC00) % 28 != 0;
    return hasBatchim ? withBatchim : without;
  }

  static String existingAccountBody(String provider) =>
      RemainingSurface.trNow('app.existingAccountBody', '그 방법으로 로그인하면 지금 \$provider\${subjectParticle(provider)} 그 계정에 연결돼요. 닉네임과 재화도 그대로예요.', {'provider': provider, 'subjectParticle(provider)': subjectParticle(provider)});

  static String linkConfirmTitle(String method) =>
      RemainingSurface.trNow('app.linkConfirmTitle', '이 계정에 \$method\${objectParticle(method)} 연결할까요?', {'method': method, 'objectParticle(method)': objectParticle(method)});

  static String linkConfirmBody({
    required String nickname,
    required int shareBalance,
  }) =>
      RemainingSurface.trNow('login.body.9', '닉네임 \$nickname\nSHARE \${groupedDigits(shareBalance)}', {'nickname': nickname, 'groupedDigits(shareBalance)': groupedDigits(shareBalance)});

  static String linkAttached(String method) =>
      RemainingSurface.trNow('app.linkAttached', '\$method\${subjectParticle(method)} 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.', {'method': method, 'subjectParticle(method)': subjectParticle(method)});

  static String groupedDigits(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  // ── Terms Agreement (Screen 2) ────────────────────────────────────
  static String get termsTitle => RemainingSurface.trNow('app.termsTitle', '환영합니다!\n시작 전 약관 동의가\n필요합니다.');
  static String get termsSubtitle => RemainingSurface.trNow('app.termsSubtitle', '안전하고 공정한 쉐어런 생태계를 위해 필수\n항목에 동의해 주세요.');

  static String get termsAllAgree => RemainingSurface.trNow('app.termsAllAgree', '[전체 동의] 쉐어런챌린지 이용약관');
  static String get termsRequiredService => RemainingSurface.trNow('app.termsRequiredService', '[필수] 쉐어런챌린지 서비스 이용약관');
  static String get termsRequiredPrivacy => RemainingSurface.trNow('app.termsRequiredPrivacy', '[필수] 개인정보 수집 및 이용 동의');
  static String get termsRequiredLocation => RemainingSurface.trNow('app.termsRequiredLocation', '[필수] 위치기반서비스 이용약관 동의');
  static String get termsRequiredAge14 => RemainingSurface.trNow('app.termsRequiredAge14', '[필수] 만 14세 이상입니다');
  static String get termsOptionalHealth => RemainingSurface.trNow('app.termsOptionalHealth', '[선택] 건강정보(심박수) 수집 및\n이용 동의');

  static const termsContinue = '동의하고 시작하기';

  // ── Smart Watch Sync (Screen 3) ───────────────────────────────────
  static String get watchSyncSkip => RemainingSurface.trNow('app.watchSyncSkip', '건너뛰기');
  static String get watchSyncTitle => RemainingSurface.trNow('app.watchSyncTitle', '정확한 기록 측정을 위해\n스마트워치를 연결해 주세요.');
  static String get watchSyncSubtitle => RemainingSurface.trNow('app.watchSyncSubtitle', '러닝 검증을 위해 심박수와 걸음 수 데이터가 필요합니다.');
  static String get watchSyncApple => RemainingSurface.trNow('app.watchSyncApple', 'Apple 건강 연동하기');
  static String get watchSyncGoogle => RemainingSurface.trNow('app.watchSyncGoogle', 'Google Health Connect 연동하기');
  static String get watchSyncExternalDevices => RemainingSurface.trNow('app.watchSyncExternalDevices', '가민, 순토, 코로스 등 외부 전문 기기를 사용하시나요?');
  static String get watchSyncComplete => RemainingSurface.trNow('app.watchSyncComplete', '연동 완료하고 시작하기');

  // ── Device Connection (unified) ───────────────────────────────────
  static const deviceConnectionTitle = '스마트워치 · 건강 데이터 연동';
  static String get deviceConnectionStatusTitle => RemainingSurface.trNow('app.deviceConnectionStatusTitle', '현재 연결된 기기');
  static String get deviceConnectionNone => RemainingSurface.trNow('app.deviceConnectionNone', '연결된 기기가 없습니다');
  static String get deviceConnectionNativeTitle => RemainingSurface.trNow('app.deviceConnectionNativeTitle', '네이티브 헬스 연동');
  static String get deviceConnectionExternalTitle => RemainingSurface.trNow('app.deviceConnectionExternalTitle', '외부 전문 기기 연동');
  static String get deviceConnectionConnect => RemainingSurface.trNow('app.deviceConnectionConnect', '기기 연결');
  static const deviceConnectionDisconnect = '연동 해제';
  static String get deviceConnectionSingleActiveNote => RemainingSurface.trNow('app.deviceConnectionSingleActiveNote', '쉐어런은 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.');
  static String get deviceConnectionGoogleCaption => RemainingSurface.trNow('app.deviceConnectionGoogleCaption', '(갤럭시 워치, 샤오미 미밴드, 어메이즈핏, 가민, 핏빗 등)');
  static const wearableGuideEntry = '내 워치·스마트밴드 연결 방법 찾기';
  static const wearableGuideSearchHint = '브랜드 검색 (예: 샤오미, 가민, 핏빗)';
  static const wearableGuideEmpty = '일치하는 브랜드가 없어요. 다른 이름으로 검색해 보세요.';
  static const wearableGuideCtaAndroid = 'Health Connect 연결하기';
  static const wearableGuideCtaIos = 'Apple 건강 연결하기';
  static String get healthConnectNoSamplesTip => RemainingSurface.trNow('app.healthConnectNoSamplesTip', '권한은 연결되었어요. 밴드/워치 앱 안에서 Health Connect 데이터 쓰기 스위치가 켜져 있는지 확인해 주세요. 스마트밴드 기록은 밴드 앱 동기화 후 반영됩니다.');
  static const deviceConnectionConsentCta = '건강정보 동의하고 연동 시작';
  static const bleHrSectionTitle = '실시간 블루투스 심박 센서 (BLE) 직접 연결';
  static String get bleHrSectionSubtitle => RemainingSurface.trNow('app.bleHrSectionSubtitle', 'Health Connect 지연 없이 달리는 동안 실시간 심박수(0x180D)를 바로 받습니다.');
  static String get bleHrGuideTitle => RemainingSurface.trNow('app.bleHrGuideTitle', '내 기기별로 이렇게 하세요');
  static List<(String, String)> get bleHrGuideItems => <(String, String)>[
    (
      RemainingSurface.trNow('app.bleHrGuideItems', '가민(Garmin)'),
      RemainingSurface.trNow(
        'app.bleHrGuideItems.2',
        '시계 설정 → 센서 및 액세서리 → 손목 심박수 → "심박수 전송" 켜기',
      ),
    ),
    (
      RemainingSurface.trNow('app.bleHrGuideItems.3', '샤오미 · 어메이즈핏'),
      RemainingSurface.trNow(
        'app.bleHrGuideItems.4',
        '운동·심박수 설정 → "심박수 공유/전송" 켜기',
      ),
    ),
    (
      RemainingSurface.trNow('app.bleHrGuideItems.5', '가슴·암밴드 센서'),
      RemainingSurface.trNow(
        'app.bleHrGuideItems.6',
        '착용한 뒤 아래 [센서 찾기] 누르기 (Polar, Wahoo, Coospo, Magene)',
      ),
    ),
    (
      RemainingSurface.trNow('app.bleHrGuideItems.7', '갤럭시 워치 · 애플워치'),
      RemainingSurface.trNow(
        'app.bleHrGuideItems.8',
        '이 방식이 아니에요. 위의 Health Connect / Apple 건강으로 연결하세요',
      ),
    ),
  ];
  static const bleHrScanButton = '센서 찾기';
  static String get bleHrScanningLabel => RemainingSurface.trNow('app.bleHrScanningLabel', '근처 심박 센서 찾는 중...');
  static String get bleHrStopScanButton => RemainingSurface.trNow('app.bleHrStopScanButton', '스캔 중지');
  static String get bleHrDisconnectButton => RemainingSurface.trNow('app.bleHrDisconnectButton', '연결 해제');
  static String get bleHrConnectButton => RemainingSurface.trNow('app.bleHrConnectButton', '연결');

  // ── Garmin OAuth (Screen 4) ───────────────────────────────────────
  static String get garminAuthTitle => RemainingSurface.trNow('app.garminAuthTitle', 'Garmin Connect 연동');
  static String get garminAuthSubtitle => RemainingSurface.trNow('app.garminAuthSubtitle', '안전한 OAuth 2.0 공식 로그인 페이지입니다.');
  static String get garminEmailHint => RemainingSurface.trNow('app.garminEmailHint', '이메일 아이디');
  static String get garminPasswordHint => RemainingSurface.trNow('app.garminPasswordHint', '비밀번호');
  static String get garminSignInAuthorize => RemainingSurface.trNow('app.garminSignInAuthorize', '로그인하고 권한 허용');
  static String get garminSignInAuthorizeKo => RemainingSurface.trNow('app.garminSignInAuthorizeKo', '(로그인 및 권한 허용)');
  static String get garminCancelAndReturn => RemainingSurface.trNow('app.garminCancelAndReturn', '연동을 취소하고 앱으로 돌아가기');

  // ── Main Dashboard (Screen 5) ─────────────────────────────────────
  static const dashboardNickname = '달리기부자45';
  static const dashboardGoldBadge = '골드';
  static const dashboardMyWallet = '내 지갑';
  static String get walletUnconfirmedNote => RemainingSurface.trNow('app.walletUnconfirmedNote', '서버에서 확인하는 중이에요. 지금 보이는 값은 마지막으로 확인된 값이에요.');
  static String get dashboardShareBalance => RemainingSurface.trNow('app.dashboardShareBalance', '보유 SHARE: 90,000');
  static String get dashboardDiamondBalance => RemainingSurface.trNow('app.dashboardDiamondBalance', '💎 보유 다이아몬드: 5개');
  static String get dashboardValueBalance => RemainingSurface.trNow('app.dashboardValueBalance', '🌱 보유 밸류(VALUE): 5,200');
  static String dashboardShareBalanceOf(String amount) => RemainingSurface.trNow('app.dashboardShareBalanceOf', '보유 SHARE: \$amount', {'amount': amount});
  static String dashboardDiamondBalanceOf(int count) =>
      RemainingSurface.trNow('app.dashboardDiamondBalanceOf', '💎 보유 다이아몬드: \$count개', {'count': count});
  static String dashboardValueBalanceOf(String amount) =>
      RemainingSurface.trNow('app.dashboardValueBalanceOf', '🌱 보유 밸류(VALUE): \$amount', {'amount': amount});
  static String get dashboardGradeRunLabel => RemainingSurface.trNow('app.dashboardGradeRunLabel', '등급 배정 달리기:');
  static String get dashboardGradeRunProgress => RemainingSurface.trNow('app.dashboardGradeRunProgress', '2/3회 완료 >');
  static String get dashboardDailyMissionCapsule => RemainingSurface.trNow('app.dashboardDailyMissionCapsule', '📍 오늘의 미션 확인하기 >');
  static String get dashboardStampMapTooltip => RemainingSurface.trNow('app.dashboardStampMapTooltip', '오늘의 미션 · 스탬프 투어');
  static String get dashboardOngoingChallenges => RemainingSurface.trNow('app.dashboardOngoingChallenges', '진행 중인 챌린지');
  static String get dashboardChallenge1Title => RemainingSurface.trNow('app.dashboardChallenge1Title', '초보 1km 챌린지 🏆');
  static String get dashboardChallenge1Sub => RemainingSurface.trNow('app.dashboardChallenge1Sub', '참가비: 600 SHARE');
  static String get dashboardChallenge2Title => RemainingSurface.trNow('app.dashboardChallenge2Title', '중급 3km 챌린지 (골드 대회)');
  static String get dashboardChallenge2Sub => RemainingSurface.trNow('app.dashboardChallenge2Sub', '참가비: 1,200 SHARE');
  static String get dashboardViewRoom => RemainingSurface.trNow('app.dashboardViewRoom', '대회 상세 보기');
  static const dashboardNavHome = '홈';
  static const dashboardNavStore = '상점';
  static const dashboardNavWallet = '지갑';
  static const dashboardNavChallenge = '챌린지';
  static const dashboardNavCrew = '크루';
  static const dashboardNavMyPage = '마이페이지';

  static String get myWalletCharge => RemainingSurface.trNow('app.myWalletCharge', '교환하기');
  static String get myWalletUse => RemainingSurface.trNow('app.myWalletUse', '상점 가기');
  static const myWalletChargeShare = 'SHARE';
  static String get myWalletChargeShareHint => RemainingSurface.trNow('app.myWalletChargeShareHint', '활동으로 모을 수 있어요');
  static String get myWalletChargeDia => RemainingSurface.trNow('app.myWalletChargeDia', '다이아몬드');
  static String get myWalletChargeDiaHint => RemainingSurface.trNow('app.myWalletChargeDiaHint', '교환소에서 SHARE로 바꾸거나 연속 달리기로 모을 수 있어요');
  static String get myWalletChargeValue => RemainingSurface.trNow('app.myWalletChargeValue', '밸류(VALUE)');
  static String get myWalletChargeValueHint => RemainingSurface.trNow('app.myWalletChargeValueHint', '달리기로 모을 수 있어요');
  static String get myWalletItemDuringRun => RemainingSurface.trNow('app.myWalletItemDuringRun', '달리기 중 사용 가능');
  static String get myWalletItemDuringTournament => RemainingSurface.trNow('app.myWalletItemDuringTournament', '대회에서 사용 가능');
  static String get myWalletRecentTransactions => RemainingSurface.trNow('app.myWalletRecentTransactions', '최근 거래 내역');

  static String myWalletShareLabel(String amount) => RemainingSurface.trNow('app.dashboardShareBalanceOf', '보유 SHARE: \$amount', {'amount': amount});
  static String myWalletDiamondLabel(int count) => RemainingSurface.trNow('app.myWalletDiamondLabel', '보유 다이아몬드: \$count개', {'count': count});
  static String myWalletValueLabel(String amount) => RemainingSurface.trNow('app.myWalletValueLabel', '보유 밸류(VALUE): \$amount', {'amount': amount});
  static String get myWalletInventoryTitle => RemainingSurface.trNow('app.myWalletInventoryTitle', '보유 아이템');
  static String get myWalletInventoryEmpty => RemainingSurface.trNow('app.myWalletInventoryEmpty', '아직 보유한 아이템이 없습니다.');
  static String get myWalletInventoryOpen => RemainingSurface.trNow('app.myWalletInventoryOpen', '보관함 보기');
  static String myWalletInventoryCount(int count) => RemainingSurface.trNow('app.myWalletInventoryCount', '보유 \$count', {'count': count});
  static String myWalletGradeProgress(int done, int total) =>
      RemainingSurface.trNow('app.myWalletGradeProgress', '등급 배정 달리기: \$done/\$total회 완료 >', {'done': done, 'total': total});
  /// 레거시 alias (구 4탭 '하트' 라벨).
  static const dashboardNavHeart = dashboardNavChallenge;

  /// 메인 탭 루트 더블 백 종료 안내.
  static String get exitGuardMessage => RemainingSurface.trNow('app.exitGuardMessage', '나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.');

  // ── Level Test Running (Screen 6) ─────────────────────────────────
  static String get levelTestTitle => RemainingSurface.trNow('app.levelTestTitle', '혼자 뛰기 챌린지 (등급 배정)');
  static String get levelTestSubtitle => RemainingSurface.trNow('app.levelTestSubtitle', '검증된 달리기를 서로 다른 날 3번 마치면 등급이 배정됩니다.');
  static String get levelTestStatDistance => RemainingSurface.trNow('app.levelTestStatDistance', '현재 거리');
  static const levelTestStatDistanceValue = '3.52 KM';
  static String get levelTestStatTime => RemainingSurface.trNow('app.levelTestStatTime', '경과 시간');
  static const levelTestStatTimeValue = '18:14';
  static String get levelTestStatPace => RemainingSurface.trNow('app.levelTestStatPace', '현재 페이스');
  static const levelTestStatPaceValue = '5:10 /KM';
  static String get levelTestChallengeProgress => RemainingSurface.trNow('app.levelTestChallengeProgress', '챌린지 진행 상황: 2/3회 완료 (3.52/5.00 KM)');
  static String get levelTestGhostPace => RemainingSurface.trNow('app.levelTestGhostPace', '[고스트 페이스]');
  static String get levelTestMyLocation => RemainingSurface.trNow('app.levelTestMyLocation', '[나(현재 위치)]');
  static String get levelTestStartRun => RemainingSurface.trNow('app.levelTestStartRun', '3회차 달리기 시작하기');

  // ── Challenge Lobby (Screen 7) ────────────────────────────────────
  static String get lobbyCreateRoom => RemainingSurface.trNow('app.lobbyCreateRoom', '+ 대회 열기');
  /// 앱 대표 슬로건. 시작 화면·홈이 같이 쓴다.
  static String get slogan => RemainingSurface.trNow('app.slogan', '심장이 뛰는 한,\n나눔도 달린다');
  static String get lobbyTitle => RemainingSurface.trNow('app.lobbyTitle', '챌린지 로비');
  static String get lobbySubtitle => RemainingSurface.trNow('app.lobbySubtitle', '전 세계 러너들과 함께 달리고 가치를 증명하세요.');
  static String get lobbyRoom1Title => RemainingSurface.trNow('app.lobbyRoom1Title', '중급 3km 골드 챌린지 🏆');
  static String get lobbyRoom1Sub => RemainingSurface.trNow('app.lobbyRoom1Sub', '참가자 12/20명');
  static String get lobbyRoom2Title => RemainingSurface.trNow('app.lobbyRoom2Title', '크루 대항 주말 10K 매치 🔥');
  static String get lobbyRoom2Sub => RemainingSurface.trNow('app.lobbyRoom2Sub', '참가 크루 8팀 · 주말 오전 09:00 시작');
  static String get lobbyRoom3Title => RemainingSurface.trNow('app.lobbyRoom3Title', '초보 1km 챌린지');
  static String get lobbyRoom3Sub => RemainingSurface.trNow('app.dashboardChallenge1Sub', '참가비: 600 SHARE');
  static String get lobbyEnterRoom => RemainingSurface.trNow('app.lobbyEnterRoom', '입장하기');

  // ── Create Challenge Room (Screen 8) ──────────────────────────────
  static const createRoomScreenTitle = '대회 열기';
  static String get createRoomScreenSubtitle => RemainingSurface.trNow('app.createRoomScreenSubtitle', '전 세계 러너들과 경쟁할 룰을 직접 설정하세요.');
  static String get createRoomTitleSection => RemainingSurface.trNow('app.createRoomTitleSection', '대회 제목 설정');
  static String get createRoomTitleHint => RemainingSurface.trNow('app.createRoomTitleHint', '어떤 목표로 달리시나요?');
  static String get createRoomTitlePlaceholder => RemainingSurface.trNow('app.createRoomTitlePlaceholder', '예) 주말 10K 크루 대항전 🔥');
  static String get createRoomTitleRequired => RemainingSurface.trNow('app.createRoomTitleRequired', '대회 제목을 입력해 주세요.');
  static String get createRoomDistanceSection => RemainingSurface.trNow('app.createRoomDistanceSection', '목표 거리 선택');
  static String get createRoomDistanceHint => RemainingSurface.trNow('app.createRoomDistanceHint', '목표 거리를 선택해 주세요.');
  static String get createRoomEntryFeeSection => RemainingSurface.trNow('app.createRoomEntryFeeSection', '대회 참가비 (SHARE)');
  static String get createRoomFeeWarningRed => RemainingSurface.trNow('app.createRoomFeeWarningRed', '* 결제하신 참가비는 플랫폼 대회 참여권 및 운영비로 귀속되며, ');
  static String get createRoomFeeWarningGrey => RemainingSurface.trNow('app.createRoomFeeWarningGrey', '유저 간 상금 재원(N빵)으로 사용되지 않습니다.');
  static String get createRoomPayAndCreateSuffix => RemainingSurface.trNow('app.createRoomPayAndCreateSuffix', 'SHARE 결제하고 대회 열기');
  static String get createRoomInsufficientShare => RemainingSurface.trNow('app.createRoomInsufficientShare', '가용 SHARE 잔액이 부족합니다. 걸어서 모은 뒤 다시 시도해 주세요.');
  static String get shareInsufficientTitle => RemainingSurface.trNow('app.shareInsufficientTitle', 'SHARE 잔액 부족');
  static String get shareInsufficientBody => RemainingSurface.trNow('app.shareInsufficientBody', '보유하신 SHARE가 부족합니다. 교환소로 이동하시겠습니까?');
  static String get shareInsufficientNo => RemainingSurface.trNow('app.shareInsufficientNo', '아니오');
  static String get shareInsufficientYes => RemainingSurface.trNow('app.shareInsufficientYes', '예');

  // ── External Payment (Screen 14) ──────────────────────────────────
  static const externalPaymentTitle = 'SHARE (쿠폰) 충전';
  static const externalPaymentSubtitle =
      '안전한 외부 결제(PG) 네트워크에 연결되었습니다.';
  static const externalPaymentMethodCard = '신용/체크카드';
  static const externalPaymentMethodToss = '토스페이';
  static const externalPaymentMethodNaver = '네이버페이';
  static const externalPaymentMethodTransfer = '계좌이체';
  static String get externalPaymentNoticePrefix => RemainingSurface.trNow('app.externalPaymentNoticePrefix', '본 결제는 ');
  static String get externalPaymentNoticeHighlight => RemainingSurface.trNow('app.externalPaymentNoticeHighlight', '실제 야외 물리적 활동(오프라인 러닝)');
  static String get externalPaymentNoticeSuffix => RemainingSurface.trNow('app.externalPaymentNoticeSuffix', ' 참여를 위한 참가권 구매입니다.');
  static String get externalPaymentRefundNote => RemainingSurface.trNow('app.externalPaymentRefundNote', '* 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.');
  static String get externalPaymentSecurePaySuffix => RemainingSurface.trNow('app.externalPaymentSecurePaySuffix', '원 안전 결제하기');

  // ── Challenge Detail (Screen 9) ───────────────────────────────────
  static String get challengeDetailTitle => RemainingSurface.trNow('app.challengeDetailTitle', '3km 중급 챌린지 (골드 대회)');
  static String get challengeDetailEntryFee => RemainingSurface.trNow('app.dashboardChallenge2Sub', '참가비: 1,200 SHARE');
  static const challengeDetailGoldBadge = '골드';
  static String get challengeDetailPrize => noCashPrizePool;
  static String get challengeDetailDonation => RemainingSurface.trNow('app.challengeDetailDonation', '기부: 회사(운영자) 자금으로 기부 예정');
  static String get challengeDetailDistance => RemainingSurface.trNow('app.challengeDetailDistance', '거리: 3km');
  static String get challengeDetailDonationTarget => RemainingSurface.trNow('app.challengeDetailDonationTarget', '기부처: 정해지면 알려 드려요');
  static String get challengeDetailValueTip => RemainingSurface.trNow('app.challengeDetailValueTip', '검증 완주 보상은 참가비를 VALUE로 바꾸지 않습니다.');
  static const challengeDetailCprMaxPerRace = 3;
  static String get challengeDetailCprUse => RemainingSurface.trNow('app.challengeDetailCprUse', '심폐소생권 사용');
  static String get challengeDetailCprBuyHint => RemainingSurface.trNow('app.challengeDetailCprBuyHint', '상점에서 구매');
  static const challengeDetailJoin = '대회 참가';

  // ── Live Running (Screen 10) ────────────────────────────────────────
  static String get liveRunningRoomTitle => RemainingSurface.trNow('app.liveRunningRoomTitle', '3km 중급 챌린지');
  static const liveRunningGps = 'GPS';
  static String get liveRunningStatDistance => RemainingSurface.trNow('app.levelTestStatDistance', '현재 거리');
  static const liveRunningStatDistanceValue = '1.8 km';
  static String get liveRunningStatTime => RemainingSurface.trNow('app.levelTestStatTime', '경과 시간');
  static const liveRunningStatTimeValue = '08:35';
  static String get liveRunningStatPace => RemainingSurface.trNow('app.levelTestStatPace', '현재 페이스');
  static const liveRunningStatPaceValue = '4:45 /km';
  static String get liveRunningYouLabel => RemainingSurface.trNow('app.liveRunningYouLabel', '나 (You)');
  static String get liveRunningGhostPace => RemainingSurface.trNow('app.liveRunningGhostPace', '고스트 페이스');
  static String liveRunningEffortTip(int valueTokens) =>
      RemainingSurface.trNow('app.liveRunningEffortTip', '순수 노력 목표: 완주 시 VALUE +\$valueTokens', {'valueTokens': valueTokens});
  static String get runValidationFailed => RemainingSurface.trNow('app.runValidationFailed', '기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.');
  static String get liveRunningFinish => RemainingSurface.trNow('app.liveRunningFinish', '종료 / 저장');
  static String get liveRunningSubmissionsLeft => RemainingSurface.trNow('app.liveRunningSubmissionsLeft', '제출 기회: 2/3회 남음');

  // ── Run Result (Screen 11) ──────────────────────────────────────────
  static String get runResultTitle => RemainingSurface.trNow('app.runResultTitle', '축하합니다!\n완주 성공 🎉');
  static String get runResultFinalTimeLabel => RemainingSurface.trNow('app.runResultFinalTimeLabel', '최종 시간:');
  static const runResultFinalTimeValue = '52:14';
  static String get runResultAvgPaceLabel => RemainingSurface.trNow('app.runResultAvgPaceLabel', '평균 페이스:');
  static const runResultAvgPaceValue = '6:15 /KM';
  static String runResultValueReward(int tokens) =>
      RemainingSurface.trNow('app.runResultValueReward', '서버 확인 노력 보상 +\$tokens VALUE', {'tokens': tokens});
  static String get runResultUnconfirmed => RemainingSurface.trNow('app.runResultUnconfirmed', '서버에서 확인된 기록이 없습니다.');
  static const runResultDonatePending = '준비 중';
  static String get runResultDonate => RemainingSurface.trNow('app.runResultDonate', '❤️ 이번 달리기 기부 기여 보기');
  static String get runResultShare => RemainingSurface.trNow('app.runResultShare', '🔗 기록 SNS 공유하기');

  // ── My Page (Screen 12) ───────────────────────────────────────────
  static const myPageTitle = '마이페이지';
  static const myPageSettings = '설정';

  // 승급 점수(대회 성적으로 모아 메달 한 칸씩 오른다)
  static String get promotionTitle => RemainingSurface.trNow('app.promotionTitle', '다음 메달까지');
  static String promotionProgress(int points, int step) => RemainingSurface.trNow('app.promotionProgress', '\$points / \$step점', {'points': points, 'step': step});
  static String get promotionHint => RemainingSurface.trNow('app.promotionHint', '대회에서 입상하면 점수가 쌓여요');
  static String get promotionBlockedCooldown => RemainingSurface.trNow('app.promotionBlockedCooldown', '승급은 일주일에 한 번이에요. 점수는 그대로 모여 있어요');
  static String get promotionBlockedTournaments => RemainingSurface.trNow('app.promotionBlockedTournaments', '다음 동물로 가려면 대회를 몇 번 더 완주해야 해요');
  static String get promotionBlockedPace => RemainingSurface.trNow('app.promotionBlockedPace', '다음 동물로 가려면 최근 30일 안에 더 빠른 달리기가 필요해요');
  static String get promotionBlockedSeason => RemainingSurface.trNow('app.promotionBlockedSeason', '다음 동물은 시즌 성적으로 정해져요');
  static String get myPageSubscriptionManage => RemainingSurface.trNow('app.myPageSubscriptionManage', '구독 관리');
  static String get myPageNickname => RemainingSurface.trNow('app.myPageNickname', '러너상기');
  static String get myPageGoldGrade => RemainingSurface.trNow('app.myPageGoldGrade', '골드 등급');
  static String get myPageStreak => RemainingSurface.trNow('app.myPageStreak', '🔥 현재 연속 출석(Streak): 12일');
  static String get myPageMonthlyDistanceLabel => RemainingSurface.trNow('app.myPageMonthlyDistanceLabel', '이번 달 총 거리:');
  static const myPageMonthlyDistanceValue = '42.5 KM';
  static String get myPageAvgPaceLabel => RemainingSurface.trNow('app.runResultAvgPaceLabel', '평균 페이스:');
  static const myPageAvgPaceValue = '5:40 /KM';

  // ── Store & Funding (Screen 13) ───────────────────────────────────
  static const storeTitle = '상점';
  static const storeShareBalance = '90,000';
  static const storeDiamondBalance = '5';
  static const storeValueBalance = '5,200';
  static const storeFundingTitle =
      '🌍 땀방울로 만드는 기적,\n기부 펀딩';
  static const storeFundingPreparing = '준비 중';
  static const storeFundingPreparingNote =
      '아직 열리지 않았어요. 열리면 이번 달 모인 기부금이 여기에 보여요.';
  static const storeFundingMonthLabel = '이번 달 모인 기부금';
  static const storeFundingNote =
      '운영자가 대신 내요 · 내 돈은 0원. 이용자의 기부금이 아니에요.';
  static const storeFundingAllReached = '이번 달 거리 목표를 모두 채웠어요';
  static const storeFundingCapReached =
      '이번 달 운영자 기부 예산을 모두 사용했어요. 넘는 거리는 기록으로 남아요.';
  static String get storeFunctionalItems => RemainingSurface.trNow('app.storeFunctionalItems', '기능성 아이템');
  static const storeCosmeticsTitle = '코스메틱';
  static const storeCosmeticsNote =
      '무료 DIA로 살 수 있습니다. 기록과 랭킹은 바뀌지 않습니다.';
  static const storeCosmeticOwned = '보유';
  static const storeCosmeticEquip = '장착';
  static const storeCosmeticUnequip = '해제';
  static const storeCosmeticSeasonEnded = '시즌 종료';
  static const storeCosmeticLimited = '시즌 한정';
  static const storeItemCpr = '기록 심폐소생권';
  static const storeItemSafeGuard = '세이프 가드';
  static const storeItemCoachOnePoint = '코치 원포인트권';
  static const storeItemExtraEntry = '추가 참가권';
  static const storeItemExtraEntryPack = '추가 참가권 3장';
  static const storeItemFriendGhost = '친구 고스트 페이스';
  static const storeItemFriendGhostPack = '친구 고스트 10회';
  static const storeItemCrewCheer = '크루 응원 깃발';
  static const storeItemBoostRun = '부스트 런';
  static const storeItemBoostRunNote = '하루 1회 · 15분간 걸음 SHARE 2배';
  static const storeItemStepIncubator = '만보기 부화기';
  static const storeItemStepIncubatorNote = '검증 걸음 30,000보에 민트 러닝화';
  static const storeItemRestDay = '휴식일 지정권';
  static const storeItemRestDayNote = '매주 1장 무료 · 추가는 VALUE';
  static const storeItemDonationMatch = '기부 매칭권';
  static const storeItemDonationMatchNote = '한 달에 1회 · 운영자 1,000원';
  static const storeItemStarBoost = '스타 부스트';
  static const storeItemSharePack = 'SHARE 팩';
  static String get storeBuyDia => RemainingSurface.trNow('app.storeBuyDia', '30 DIA 구매');
  static const storeChargeCta = '다이아 충전';
  static const storeValueDetailTitle = 'VALUE 상세';
  static const storeValueDetailBody =
      'VALUE는 현금으로 바꿀 수 없는 명예 재화예요. 기부처 투표, 명예의 전당, 칭호·배지 등에 쓰여요.';
  static String get walletHistoryShortcutTooltip => RemainingSurface.trNow('app.walletHistoryShortcutTooltip', '재화 히스토리');
  static String get iapBillingTitle => RemainingSurface.trNow('app.iapBillingTitle', '다이아 교환소');
  static String get iapBillingSubtitle => RemainingSurface.trNow('app.iapBillingSubtitle', '구글 플레이 공식 보안 결제를 적용합니다.');

  // ── Pro Tools (Screen 15) ─────────────────────────────────────────
  static String get proToolsTitle => RemainingSurface.trNow('app.proToolsTitle', '러닝 기어 & 프로 툴');
  static String get proToolsSubtitle => RemainingSurface.trNow('app.proToolsSubtitle', '장비의 수명을 관리하고 AI 리포트로 성장하세요.');
  static String get proToolsRegisteredShoe => RemainingSurface.trNow('app.proToolsRegisteredShoe', '등록된 러닝화: 나이키 베이퍼플라이 3');
  static const proToolsMileageStats = '420km / 500km (84%)';
  static String get proToolsCushionWarning => RemainingSurface.trNow('app.proToolsCushionWarning', '쿠션 수명이 80km 남았습니다.\n부상 방지를 위해 교체 시기가 다가옵니다.');
  static String get proToolsMenuPaceCalc => RemainingSurface.trNow('app.proToolsMenuPaceCalc', '목표 거리에 따른 페이스 계산기 (VDOT)');
  static String get proToolsMenuAiReport => RemainingSurface.trNow('app.proToolsMenuAiReport', 'AI 심층 러닝 리포트 (구간별 페이스 분석)');
  static String get proToolsMenuCrewRanking => RemainingSurface.trNow('app.proToolsMenuCrewRanking', '소속 크루(Crew) 출석률 랭킹 보드');

  // ── Brand Sponsor (Screen 16) ─────────────────────────────────────
  static String get brandSponsorScreenTitle => RemainingSurface.trNow('app.brandSponsorScreenTitle', '브랜드 스폰서 챌린지');
  static String get lobbySponsorRoomTitle => RemainingSurface.trNow('app.brandSponsorScreenTitle', '브랜드 스폰서 챌린지');
  static String get lobbySponsorRoomSub => RemainingSurface.trNow('app.lobbySponsorRoomSub', '지금 진행 중인 스폰서 챌린지가 없어요. 열리면 여기서 알려 드릴게요.');
  static const lobbySponsorPreparing = '준비 중';
  static String get brandSponsorTicker => RemainingSurface.trNow('app.brandSponsorTicker', '✨ 나이키 코리아가 이번 대회의 러너들을 전면 후원합니다! ✨');
  static String get brandSponsorChallengeTitle => RemainingSurface.trNow('app.brandSponsorChallengeTitle', 'Nike 주말 5km 특별 챌린지');
  static String get brandSponsorEntryFee => RemainingSurface.trNow('app.brandSponsorEntryFee', '참가비: 0 SHARE (스폰서 100% 대납)');
  static String get brandSponsorWinReward => RemainingSurface.trNow('app.brandSponsorWinReward', '우승 보상: 나이키 자사몰 30% 할인 쿠폰 + 500');
  static String get brandSponsorDonationPledge => RemainingSurface.trNow('app.brandSponsorDonationPledge', '기부 공약: 운영자 이름으로 500만 원 기부');
  static String get brandSponsorBenevolentFailure => RemainingSurface.trNow('app.brandSponsorBenevolentFailure', '자비로운 실패: 미션에 실패하더라도 운영자 이름으로 기부가 진행됩니다.');
  static String get brandSponsorDisclaimer => RemainingSurface.trNow('app.brandSponsorDisclaimer', '* 세부 처리상 기부금 세액공제 혜택은 후원 기업에게 귀속됩니다.');
  static String get brandSponsorStatus => RemainingSurface.trNow('app.brandSponsorStatus', '남은 시간 및 모집 인원(예: 8,500명 참여 중)');
  static String get brandSponsorJoinCta => RemainingSurface.trNow('app.brandSponsorJoinCta', '스폰서 후원받고 무료 참가하기');

  // ── Personal Sponsor (Screen 17) ──────────────────────────────────
  static String get personalSponsorTitle => RemainingSurface.trNow('app.personalSponsorTitle', '러너 후원하기 (스폰서십)');
  static String get personalSponsorBadgeHint => RemainingSurface.trNow('app.personalSponsorBadgeHint', '후원 시 프로필에 천사 뱃지가 영구 노출됩니다');
  static const personalSponsorAmount = '50,000 SHARE';
  static String get personalSponsorMonthlyToggle => RemainingSurface.trNow('app.personalSponsorMonthlyToggle', '월간 \'SHARE 멤버십\'으로 매월 정기 후원하기');
  static String get personalSponsorPurposeLabel => RemainingSurface.trNow('app.personalSponsorPurposeLabel', '후원금의 사용 목적을 직접 선택해 주세요.');
  static String get personalSponsorPrizeTitle => RemainingSurface.trNow('app.personalSponsorPrizeTitle', '[순수 상금 지원]');
  static String get personalSponsorPrizeDesc => RemainingSurface.trNow('app.personalSponsorPrizeDesc', '후원금이 1등 러너에게 순수 상금 보너스로 직접 지급됩니다.');
  static String get personalSponsorDonationTitle => RemainingSurface.trNow('app.personalSponsorDonationTitle', '[기부 후원]');
  static String get personalSponsorDonationDesc => RemainingSurface.trNow('app.personalSponsorDonationDesc', '후원은 운영자 이름으로 기부돼요. 내 기여는 앱에서 확인할 수 있어요.');
  static const personalSponsorActive = 'ACTIVE';
  static String get personalSponsorCta => RemainingSurface.trNow('app.personalSponsorCta', '50,000 SHARE 후원하고 천사 되기');
  static String get personalSponsorCelebrateTitle => RemainingSurface.trNow('app.personalSponsorCelebrateTitle', '천사 후원 완료!');
  static String get personalSponsorCelebrateHall => RemainingSurface.trNow('app.personalSponsorCelebrateHall', '명예의 전당 보기');
  static const personalSponsorCelebrateDone = '확인';
  static String get myPageAngelSponsor => RemainingSurface.trNow('app.myPageAngelSponsor', '천사 후원');
  static String get avatarCustomizeTitle => RemainingSurface.trNow('app.avatarCustomizeTitle', '아바타 커스터마이징');
  static String get avatarCustomizeHint => RemainingSurface.trNow('app.avatarCustomizeHint', '캐릭터를 고르거나 갤러리 사진을 쓰면 바로 저장됩니다');
  static String get avatarPickGallery => RemainingSurface.trNow('app.avatarPickGallery', '갤러리에서 사진 선택');
  static String get avatarGalleryDenied => RemainingSurface.trNow('app.avatarGalleryDenied', '사진 접근 권한이 필요합니다. 설정에서 허용해 주세요.');
  static String get avatarGalleryFailed => RemainingSurface.trNow('app.avatarGalleryFailed', '사진을 불러오지 못했습니다. 다시 시도해 주세요.');

  // ── Running Crew (Screen 18) ──────────────────────────────────────
  static String get runningCrewTitle => RemainingSurface.trNow('app.runningCrewTitle', '러닝 크루 (Crew)');
  static String get runningCrewHeadline => RemainingSurface.trNow('app.runningCrewHeadline', '같이 달릴\n크루 찾기');
  static String get runningCrewMyCrewName => RemainingSurface.trNow('app.runningCrewMyCrewName', '인천 논현 최강 크루');
  static const runningCrewNoCrewLabel = '크루';
  static String get runningCrewNoCrewName => RemainingSurface.trNow('app.runningCrewNoCrewName', '아직 크루가 없어요');
  static String get runningCrewNoCrewHint => RemainingSurface.trNow('app.runningCrewNoCrewHint', '크루에 들어가면 함께 달린 거리를 모아 월간 순위에 도전할 수 있어요. 크루를 만들거나 아래에서 찾아보세요.');
  static String get runningCrewMyCrewStats => RemainingSurface.trNow('app.runningCrewMyCrewStats', '소속 크루원: 45/50명 | 누적 달성 거리: 3,240km');
  static String get runningCrewCreateButton => RemainingSurface.trNow('app.runningCrewCreateButton', '[50 DIA 또는 30,000 SHARE로 새 크루 창설하기]');
  static String get runningCrewProgressLabel => RemainingSurface.trNow('app.runningCrewProgressLabel', '이번 주 크루 대항전 10K 완주율');
  static const runningCrewProgressValue = '80%';
  static String get runningCrewEnterRoom => RemainingSurface.trNow('app.runningCrewEnterRoom', '크루 룸 입장하기');

  // ── Crew Manager (Screen 19) ──────────────────────────────────────
  static String get crewManagerTitle => RemainingSurface.trNow('app.crewManagerTitle', '크루 관리 (방장 전용)');
  static String get crewManagerCrewName => RemainingSurface.trNow('app.runningCrewMyCrewName', '인천 논현 최강 크루');
  static String get crewManagerPushNotice => RemainingSurface.trNow('app.crewManagerPushNotice', '전체 공지 푸시 발송 (무료)');
  static String get crewManagerPremiumSection => RemainingSurface.trNow('app.crewManagerPremiumSection', '프리미엄 설정');
  static String get crewManagerProfileLabel => RemainingSurface.trNow('app.crewManagerProfileLabel', '크루 프로필');
  static String get crewManagerProfileChange => RemainingSurface.trNow('app.crewManagerProfileChange', '이름 변경');
  static String get crewManagerGiftSection => RemainingSurface.trNow('app.crewManagerGiftSection', '크루원 혜택 하사(선물)');
  static String get crewManagerGiftCpr => RemainingSurface.trNow('app.crewManagerGiftCpr', '🎁 심폐소생권/세이프가드 전체 선물 (DIA)');
  static String get crewManagerGiftDeposit => RemainingSurface.trNow('app.crewManagerGiftDeposit', '🛡️ 크루 대항전 예치금 방장 대납 (DIA/SHARE)');
  static String get crewManagerGiftAngelBadge => RemainingSurface.trNow('app.crewManagerGiftAngelBadge', '천사 배지를 획득하세요');
  static String get crewManagerShareWarning => RemainingSurface.trNow('app.crewManagerShareWarning', 'SHARE 결제 시 주의하세요');
  static String get crewManagerGiftPass => RemainingSurface.trNow('app.crewManagerGiftPass', '🎉 크루 전용 챌린지 패스 & 스킨 구매 (DIA)');
  static String get crewManagerMemberSection => RemainingSurface.trNow('app.crewManagerMemberSection', '소속 팀원 관리 (50 / 50명)');
  static String get crewManagerExpandMembers => RemainingSurface.trNow('app.crewManagerExpandMembers', '+10명 인원 한도 확장하기 (300 DIA)');
  static String get crewManagerAppointVice => RemainingSurface.trNow('app.crewManagerAppointVice', '부방장 임명');
  static String get crewManagerForceKick => RemainingSurface.trNow('app.crewManagerForceKick', '강제 퇴출');
  static String get crewManagerSave => RemainingSurface.trNow('app.crewManagerSave', '관리 설정 저장하기');
  static String get crewManagerMember1 => RemainingSurface.trNow('app.crewManagerMember1', '김나운');
  static String get crewManagerMember2 => RemainingSurface.trNow('app.crewManagerMember2', '이승우');
  static String get crewManagerMember3 => RemainingSurface.trNow('app.crewManagerMember3', '최서연');

  // ── Item Inventory (Screen 20) ──────────────────────────────────────
  static String get itemInventoryTitle => RemainingSurface.trNow('app.itemInventoryTitle', '내 아이템 보관함');
  static const itemInventoryCprTitle = '기록 심폐소생권';
  static const itemInventoryCoachOnePointTitle = '코치 원포인트권';
  static const itemInventoryExtraEntryTitle = '추가 참가권';
  static String get itemInventoryCoachOnePointHint => RemainingSurface.trNow('app.itemInventoryCoachOnePointHint', '러닝을 시작하면 사용됩니다. 하루 1회.');
  static String get itemInventoryExtraEntryHint => RemainingSurface.trNow('app.itemInventoryExtraEntryHint', '모집 마감·정원 초과 참가 시 사용됩니다. 하루 2회.');
  static const itemInventoryFriendGhostTitle = '친구 고스트 페이스';
  static String get itemInventoryFriendGhostHint => RemainingSurface.trNow('app.itemInventoryFriendGhostHint', '러닝 중 친구 기록과 비교합니다. 내 최고 기록은 무료입니다.');
  static const itemInventoryCrewCheerTitle = '크루 응원 깃발';
  static String get itemInventoryCrewCheerHint => RemainingSurface.trNow('app.itemInventoryCrewCheerHint', '하루 1회. 대회 SHARE 보상만 10% 늘어납니다.');
  static const itemInventoryBoostRunTitle = '부스트 런';
  static String get itemInventoryBoostRunQuantityNote => RemainingSurface.trNow('app.itemInventoryBoostRunQuantityNote', '하루 1회 · 15분간 줍는 SHARE 2배 · 추가분 +240');
  static const itemInventoryStepIncubatorTitle = '만보기 부화기';
  static const itemInventoryStepIncubatorQuantityNote =
      '검증 걸음 30,000보에 민트 러닝화';
  static const itemInventoryRestDayTitle = '휴식일 지정권';
  static String get itemInventoryRestDayNote => RemainingSurface.trNow('app.itemInventoryRestDayNote', '매주 1회 무료. 추가 보유분만 VALUE로 샀습니다. 휴식일은 출석으로 세지 않고 스트릭도 끊지 않습니다.');
  static String get itemInventoryRestDayToday => RemainingSurface.trNow('app.itemInventoryRestDayToday', '오늘 휴식');
  static String get itemInventoryRestDayYesterday => RemainingSurface.trNow('app.itemInventoryRestDayYesterday', '어제 휴식');
  static const itemInventoryDonationMatchTitle = '기부 매칭권';
  static String get itemInventoryDonationMatchNote => RemainingSurface.trNow('app.itemInventoryDonationMatchNote', '100 VALUE. 운영자 명의 1,000원이 러닝 기부 풀에 더해지고 내 이름이 함께 표시됩니다. 영수증은 없습니다.');
  static String get itemInventoryDonationMatchUse => RemainingSurface.trNow('app.itemInventoryDonationMatchUse', '매칭하기');
  static String get itemInventoryCprQuantity => RemainingSurface.trNow('app.itemInventoryCprQuantity', '보유량: 3/3');
  static const itemInventorySafeGuardTitle = '세이프 가드';
  static String get itemInventorySafeGuardQuantity => RemainingSurface.trNow('app.itemInventorySafeGuardQuantity', '보유량: 1/1');
  static String get itemInventoryUse => RemainingSurface.trNow('app.itemInventoryUse', '사용하기');

  // ── Refund (Screen 21) ────────────────────────────────────────────
  static String get refundTitle => RemainingSurface.trNow('app.refundTitle', '결제 취소 및 환불');
  static String get refundGuaranteeTitle => RemainingSurface.trNow('app.refundGuaranteeTitle', '안전 환불 보장');
  static String get refundPolicy1 => RemainingSurface.trNow('app.refundPolicy1', '- 전자상거래법에 의거, 결제 후 7일 이내 미사용 재화는 수수료 없이 100% 현금 환불됩니다.');
  static String get refundPolicy2 => RemainingSurface.trNow('app.refundPolicy2', '- 최소 인원이 모이지 않으면 참가비가 전액 돌아옵니다.');
  static String get refundTargetItem => RemainingSurface.trNow('app.refundTargetItem', '[ 50,000 SHARE (미사용) ]');
  static String get refundPaymentDate => RemainingSurface.trNow('app.refundPaymentDate', '결제일: 2026.06.25');
  static String get refundTotalAmount => RemainingSurface.trNow('app.refundTotalAmount', '총 환불 예정 금액: 50,000 KRW');
  static String get refundCancelCta => RemainingSurface.trNow('app.refundCancelCta', '수수료 없이 결제 취소하기 (현금 환불)');

  static String get winnerRewardNoConversion => RemainingSurface.trNow('app.challengeDetailValueTip', '검증 완주 보상은 참가비를 VALUE로 바꾸지 않습니다.');
  static String get noCashPrizePool => RemainingSurface.trNow('app.noCashPrizePool', '현금 상금 없음');

  // ── Stamp Tour (Screen 23) ──────────────────────────────────────────
  static String get stampTourTitle => RemainingSurface.trNow('app.stampTourTitle', '스탬프 투어 & 미션');
  static String get stampTourVisitComplete => RemainingSurface.trNow('app.stampTourVisitComplete', '방문 완료!');
  static String get stampTourLandmarkGangbyeon => RemainingSurface.trNow('app.stampTourLandmarkGangbyeon', '강변 공원');
  static String get stampTourLandmarkNamsan => RemainingSurface.trNow('app.stampTourLandmarkNamsan', '남산타워');
  static String get stampTourLandmarkModoil => RemainingSurface.trNow('app.stampTourLandmarkModoil', '모도일 공원');
  static String get stampTourMissionWalk => RemainingSurface.trNow('app.stampTourMissionWalk', '오늘 가볍게 1km 걷기');
  static String get stampTourMissionWalkReward => RemainingSurface.trNow('app.stampTourMissionWalkReward', 'DIA 지급 대기');
  static String get stampTourMissionStamp => RemainingSurface.trNow('app.stampTourMissionStamp', '우리 동네 랜드마크 스탬프 찍기 (1/3)');
  static const stampTourMissionInProgress = '진행 중';
  static String get stampTourOfficialDiaPending => RemainingSurface.trNow('app.stampTourMissionWalkReward', 'DIA 지급 대기');
  static String get stampTourStampCollected => RemainingSurface.trNow('app.stampTourStampCollected', '스탬프 완료');
  static String get dashboardStampTourCta => RemainingSurface.trNow('app.dashboardStampTourCta', '스탬프 투어 확인하기');

  // ── Battle Pass (Screen 24) ─────────────────────────────────────────
  static const battlePassTitle = '배틀런 패스 (Season 1)';
  static String get battlePassPremiumActive => RemainingSurface.trNow('app.battlePassPremiumActive', '👑 프리미엄 패스 활성화 중');
  static String get battlePassCurrentLevel => RemainingSurface.trNow('app.battlePassCurrentLevel', '현재 레벨: Lv. 15');
  static const battlePassProgressLabel = '80%';
  static const battlePassFreeReward = '패스 보상';
  static const battlePassPremiumReward = '패스+ 보상';
  static const battlePassOwned = '배틀런 패스 보유';
  static const battlePassPlusOwned = '패스+ 보유';
  static const battlePassNone = '유료 DIA로만 구매';
  static const battlePassCosmeticNote =
      '프레임·스킨·배지입니다. 순위, 기록, DIA는 바뀌지 않습니다.';
  static const battlePassInventoryNote = '꾸미기 보상. 순위와 기록은 그대로입니다.';
  static String get lobbyBattlePassCta => RemainingSurface.trNow('app.lobbyBattlePassCta', '시즌 1 배틀런 패스 확인');

  // ── Subscription Management (Screen 25) ───────────────────────────
  static String get subscriptionTitle => RemainingSurface.trNow('app.myPageSubscriptionManage', '구독 관리');

  // ── Hall of Fame (Screen 26) ──────────────────────────────────────
  static String get hallOfFameTitle => RemainingSurface.trNow('app.hallOfFameTitle', '명예의 전당 (Hall of Fame)');
  static String get hallOfFameLeaderTitle => RemainingSurface.trNow('app.hallOfFameLeaderTitle', '👑 이달의 소셜 임팩트 리더');
  static const hallOfFameSpecialSbt = 'SPECIAL SBT';
  static String get hallOfFameLeaderName => RemainingSurface.trNow('app.hallOfFameLeaderName', '서울 나이트 러너스 방장님');
  static String get hallOfFameLeaderDonation => RemainingSurface.trNow('app.hallOfFameLeaderDonation', '누적 기부: 5,000,000 VALUE');
  static String get hallOfFameRank2Label => RemainingSurface.trNow('app.hallOfFameRank2Label', '2등');
  static String get hallOfFameRank2Subtitle => RemainingSurface.trNow('app.hallOfFameRank2Subtitle', '연속 50일 완주자');
  static String get hallOfFameRank2Badge => RemainingSurface.trNow('app.hallOfFameRank2Badge', '🔥 불꽃 SBT 뱃지');
  static const hallOfFameRank2Value = '3,200,000 VALUE';
  static String get hallOfFameRank3Label => RemainingSurface.trNow('app.hallOfFameRank3Label', '3등');
  static String get hallOfFameRank3Subtitle => RemainingSurface.trNow('app.hallOfFameRank3Subtitle', '최다 크루원 후원자');
  static String get hallOfFameRank3Badge => RemainingSurface.trNow('app.hallOfFameRank3Badge', '🛡️ 방패 SBT 뱃지');
  static const hallOfFameRank3Value = '2,800,000 VALUE';
  static String get hallOfFameDonateCta => RemainingSurface.trNow('app.hallOfFameDonateCta', '나도 기부하고 명예의 전당 오르기 💎');
  static String get hallOfFameDonateHistoryTitle => RemainingSurface.trNow('app.hallOfFameDonateHistoryTitle', '명예의 전당 기부 완료 🕊️');
  static String get storeDonateHistoryTitle => RemainingSurface.trNow('app.storeDonateHistoryTitle', '기부 펀딩 참여 🕊️');
  static String get runningCrewHallOfFame => RemainingSurface.trNow('app.runningCrewHallOfFame', '👑 명예의 전당');

  // ── Appeal / Customer Service (Screen 27) ────────────────────────
  static const appealTitle = '기록 소명 및 고객센터';
  static String get appealWarningTitle => RemainingSurface.trNow('app.appealWarningTitle', '기록 검증 보류 안내');
  static String get appealWarningBody => RemainingSurface.trNow('app.appealWarningBody', '최근 제출하신 [중급 3km 챌린지] 기록이 비정상적인 GPS/심박수 패턴으로 인해 보류 처리되었습니다. 억울한 경우 아래 폼을 통해 소명 자료를 제출해 주세요.');
  static String get appealFormTitle => RemainingSurface.trNow('app.appealFormTitle', '소명 자료 첨부 폼');
  static String get appealReasonGps => RemainingSurface.trNow('app.appealReasonGps', '단순 GPS 수신 불량 / 음영 지역');
  static String get appealReasonWatchSensor => RemainingSurface.trNow('app.appealReasonWatchSensor', '스마트워치 센서 일시적 접촉 불량');
  static String get appealReasonExternalMismatch => RemainingSurface.trNow('app.appealReasonExternalMismatch', '외부 러닝 앱 기록 불일치');
  static String get appealReasonOther => RemainingSurface.trNow('app.appealReasonOther', '기타 사유 직접 입력');
  static List<String> get appealReasonOptions => <String>[
    appealReasonGps,
    appealReasonWatchSensor,
    appealReasonExternalMismatch,
    appealReasonOther,
  ];
  static String get appealUploadLabel => RemainingSurface.trNow('app.appealUploadLabel', '[ 📷 + 외부 앱 기록 및 로그 업로드 ]');
  static String get appealDetailHint => RemainingSurface.trNow('app.appealDetailHint', '상세 사유를 입력해 주세요.');
  static String get appealSubmitCta => RemainingSurface.trNow('app.appealSubmitCta', '소명 자료 제출하기 (관리자 검토)');
  static String get appealProofRequiredSnack => RemainingSurface.trNow('app.appealProofRequiredSnack', '증빙용 가민/외부 러닝기록 사진을 최소 1개 이상 업로드해야 합니다');
  static String get appealSubmitSuccessTitle => RemainingSurface.trNow('app.appealSubmitSuccessTitle', '소명 자료 제출 완료');
  static String get appealSubmitSuccessBody => RemainingSurface.trNow('app.appealSubmitSuccessBody', '관리자 검토 대기(under_review) 상태로 접수되었습니다. 심사 결과는 알림으로 안내됩니다.');
  static const dashboardVerificationHoldBanner = '기록 검증 보류';

  // ── Notification Center (Screen 28) ──────────────────────────────
  static String get notificationCenterTitle => RemainingSurface.trNow('app.notificationCenterTitle', '알림 및 내역 (History)');
  static String get notificationTabSystem => RemainingSurface.trNow('app.notificationTabSystem', '시스템 알림');
  static String get notificationTabPayment => RemainingSurface.trNow('app.notificationTabPayment', '결제/히스토리');
  static String get notification1Title => RemainingSurface.trNow('app.notification1Title', '러닝 검증 완료!');
  static String get notification1BodyPrefix => RemainingSurface.trNow('app.notification1BodyPrefix', '중급 3km 챌린지 기록이 승인되어 ');
  static String get notification1Highlight => RemainingSurface.trNow('app.notification1Highlight', '100 밸류 토큰(VALUE)');
  static String get notification1BodySuffix => RemainingSurface.trNow('app.notification1BodySuffix', '이 지갑으로 자동 입금되었습니다.');
  static String get notification1Time => RemainingSurface.trNow('app.notification1Time', '방금 전');
  static String get notification2Title => RemainingSurface.trNow('app.notification2Title', '크루 방장님의 하사품');
  static String get notification2BodyPrefix => RemainingSurface.trNow('app.notification2BodyPrefix', '서울 나이트 러너스 방장님이 ');
  static String get notification2Highlight => RemainingSurface.trNow('app.notification2Highlight', '\'기록 심폐소생권\'');
  static String get notification2BodySuffix => RemainingSurface.trNow('app.notification2BodySuffix', '을 선물했습니다!');
  static String get notification2Time => RemainingSurface.trNow('app.notification2Time', '2시간 전');
  static String get notification3Title => RemainingSurface.trNow('app.notification3Title', '결제 취소 완료');
  static String get notification3Body => RemainingSurface.trNow('app.notification3Body', '대회 무산으로 인해 50,000 SHARE 현금 환불이 정상 처리되었습니다.');
  static String get notification3Time => RemainingSurface.trNow('app.notification3Time', '어제');
  static String get notificationPaymentEmpty => RemainingSurface.trNow('app.notificationPaymentEmpty', '거래 및 결제 내역이 존재하지 않습니다. 🪙');
  static String get notificationPaymentReceipt => RemainingSurface.trNow('app.notificationPaymentReceipt', '안전 결제 영수증 완료 🪙');
  static String get notificationPaymentUnknown => RemainingSurface.trNow('app.notificationPaymentUnknown', '알 수 없는 거래');
  static String get notificationPaymentJustNow => RemainingSurface.trNow('app.notification1Time', '방금 전');
  static String get notificationSystemEmpty => RemainingSurface.trNow('app.notificationSystemEmpty', '도달한 새로운 알림이 없습니다. 🔔');
  static String get notificationSystemFallbackTitle => RemainingSurface.trNow('app.notificationSystemFallbackTitle', '알림');

  // ── Voice coaching (Phase 3a) ─────────────────────────────────────
  static String get voiceCoachingTitle => RemainingSurface.trNow('app.voiceCoachingTitle', '보이스 코칭');
  static String get voiceCoachingSubtitle => RemainingSurface.trNow('app.voiceCoachingSubtitle', '워킹·러닝 중 짧은 응원 멘트를 음성으로 들려줍니다');
  static String get voiceCoachingWalkOn => RemainingSurface.trNow('app.voiceCoachingWalkOn', '보이스 코칭 켜져 있음');
  static String get voiceCoachingWalkOff => RemainingSurface.trNow('app.voiceCoachingWalkOff', '보이스 코칭이 꺼져 있습니다');
  static String get voiceCoachingEnable => RemainingSurface.trNow('app.voiceCoachingEnable', '코칭 켜기');
  static String get voiceCoachingDisable => RemainingSurface.trNow('app.voiceCoachingDisable', '코칭 끄기');
  static String get voiceCoachingOnTooltip => RemainingSurface.trNow('app.voiceCoachingOnTooltip', '보이스 코칭 끄기');
  static String get voiceCoachingOffTooltip => RemainingSurface.trNow('app.voiceCoachingOffTooltip', '보이스 코칭 켜기');
}
