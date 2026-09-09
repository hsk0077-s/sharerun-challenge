/// 앱 전역 UI 문자열.
///
/// Intl 패키지 도입 전까지 하드코딩 문자열을 이곳에 모읍니다.
abstract final class AppStrings {
  // ── Login (Screen 1) ──────────────────────────────────────────────
  static const loginLogoMark = 'SRC';
  static const loginTitle = '셰어 런 챌린지 (SRC)';
  static const loginSubtitle = '세계를 향한 나눔의 질주';

  static const loginGoogle = 'Google로 계속하기';
  static const loginApple = 'Apple로 계속하기';
  static const loginNaver = 'Naver로 계속하기';
  static const loginKakao = 'Kakao로 계속하기';

  static const loginReferralLabel = '추천 코드가 있으신가요?';
  static const loginReferralHint = '추천 코드를 입력하세요...';

  static const loginGuest = '게스트(테스트)로 시작하기';
  static const loginGuestLoading = '게스트 로그인 중...';
  static const loginGuestNote = '게스트 모드는 워치 연동·Health Connect 테스트용 임시 계정입니다.';

  static String loginComingSoon(String provider) => '$provider 로그인은 준비 중입니다.';
  static String loginSaveFailed(Object error) => '로그인 저장 실패: $error';

  // ── Terms Agreement (Screen 2) ────────────────────────────────────
  static const termsTitle =
      '환영합니다!\n시작 전 약관 동의가\n필요합니다.';
  static const termsSubtitle =
      '안전하고 공정한 SRC 생태계를 위해 필수\n항목에 동의해 주세요.';

  static const termsAllAgree = '[전체 동의] 셰어런챌린지 이용약관';
  static const termsRequiredService = '[필수] 셰어런챌린지 서비스 이용약관';
  static const termsRequiredPrivacy = '[필수] 개인정보 수집 및 이용 동의';
  static const termsRequiredLocation = '[필수] 위치기반서비스 이용약관 동의';
  static const termsOptionalHealth =
      '[선택] 건강정보(심박수) 수집 및\n이용 동의';

  static const termsContinue = '동의하고 시작하기';

  // ── Smart Watch Sync (Screen 3) ───────────────────────────────────
  static const watchSyncSkip = '건너뛰기';
  static const watchSyncTitle =
      '정확한 기록 측정을 위해\n스마트워치를 연결해 주세요.';
  static const watchSyncSubtitle =
      'Jena AI 검증을 위해 심박수와 걸음 수 데이터가 필요합니다.';
  static const watchSyncApple = 'Apple 건강 연동하기';
  static const watchSyncGoogle = 'Google Health Connect 연동하기';
  static const watchSyncExternalDevices =
      '가민, 순토, 코로스 등 외부 전문 기기를 사용하시나요?';
  static const watchSyncComplete = '연동 완료하고 시작하기';

  // ── Device Connection (unified) ───────────────────────────────────
  static const deviceConnectionTitle = '스마트워치 · 건강 데이터 연동';
  static const deviceConnectionStatusTitle = '현재 연결된 기기';
  static const deviceConnectionNone = '연결된 기기가 없습니다';
  static const deviceConnectionNativeTitle = '네이티브 헬스 연동';
  static const deviceConnectionExternalTitle = '외부 전문 기기 연동';
  static const deviceConnectionConnect = '기기 연결';
  static const deviceConnectionDisconnect = '연동 해제';
  static const deviceConnectionSingleActiveNote =
      'Share Run Challenge는 동시에 하나의 운동 기기만 활성 연결 상태로 유지합니다.';
  static const deviceConnectionConsentCta = '건강정보 동의하고 연동 시작';

  // ── Garmin OAuth (Screen 4) ───────────────────────────────────────
  static const garminAuthTitle = 'Garmin Connect 연동';
  static const garminAuthSubtitle = '안전한 OAuth 2.0 공식 로그인 페이지입니다.';
  static const garminEmailHint = '이메일 아이디';
  static const garminPasswordHint = '비밀번호';
  static const garminSignInAuthorize = 'Sign In & Authorize';
  static const garminSignInAuthorizeKo = '(로그인 및 권한 허용)';
  static const garminCancelAndReturn = '연동을 취소하고 앱으로 돌아가기';

  // ── Main Dashboard (Screen 5) ─────────────────────────────────────
  static const dashboardNickname = '달리기부자45';
  static const dashboardGoldBadge = '골드';
  static const dashboardMyWallet = '나의 지갑';
  static const dashboardShareBalance = '보유 SHARE: 90,000 (≈ 90,000 KRW)';
  static const dashboardDiamondBalance = '💎 보유 다이아몬드: 5개';
  static const dashboardValueBalance = '🌱 보유 밸류(VALUE): 5,200';
  static String dashboardShareBalanceOf(String amount, String krw) =>
      '보유 SHARE: $amount (≈ $krw KRW)';
  static String dashboardDiamondBalanceOf(int count) =>
      '💎 보유 다이아몬드: $count개';
  static String dashboardValueBalanceOf(String amount) =>
      '🌱 보유 밸류(VALUE): $amount';
  static const dashboardGradeRunLabel = '등급 심사 달리기:';
  static const dashboardGradeRunProgress = '3/5회 완료 >';
  static const dashboardDailyMissionCapsule = '📍 오늘의 미션 확인하기 >';
  static const dashboardStampMapTooltip = '오늘의 미션 · 스탬프 투어';
  static const dashboardOngoingChallenges = '진행 중인 챌린지';
  static const dashboardChallenge1Title = '초보 1km 챌린지 🏆';
  static const dashboardChallenge1Sub = 'Entry 료: 10만 SHARE';
  static const dashboardChallenge2Title = '중급 3km 챌린지 (골드 방)';
  static const dashboardChallenge2Sub = 'BEP: 283/400';
  static const dashboardViewRoom = '방 상세 보기';
  static const dashboardNavHome = '홈';
  static const dashboardNavStore = '상점';
  static const dashboardNavWallet = '지갑';
  static const dashboardNavChallenge = '챌린지';
  static const dashboardNavCrew = '크루';
  static const dashboardNavMyPage = '마이페이지';

  static const myWalletCharge = '충전하기';
  static const myWalletUse = '사용하기';
  static const myWalletRecentTransactions = '최근 거래 내역';
  static const myWalletTxChallengeReward = '3km 챌린지 완주 보상';
  static const myWalletTxChallengeDate = '2023.10.26';
  static const myWalletTxChallengeAmount = '+500 SHARE';
  static const myWalletTxChallengeStatus = '기부 완료';
  static const myWalletTxUnicef = '유니세프 기부';
  static const myWalletTxUnicefDate = '2023.10.25';
  static const myWalletTxUnicefAmount = '-100 VALUE';
  static const myWalletTxUnicefStatus = '챌린지 참가';

  static String myWalletShareLabel(String amount) => '보유 SHARE: $amount';
  static String myWalletShareKrw(String krw) => '(~ $krw KRW)';
  static String myWalletDiamondLabel(int count) => '보유 다이아몬드: $count개';
  static String myWalletValueLabel(String amount) => '보유 밸류(VALUE): $amount';
  static String myWalletGradeProgress(int done, int total) =>
      '등급 심사 달리기: $done/$total회 완료 >';
  /// 레거시 alias (구 4탭 '하트' 라벨).
  static const dashboardNavHeart = dashboardNavChallenge;

  /// 메인 탭 루트 더블 백 종료 안내.
  static const exitGuardMessage =
      '나눔의 질주를 잠시 쉬어가시겠습니까? 한 번 더 누르시면 종료됩니다.';

  // ── Level Test Running (Screen 6) ─────────────────────────────────
  static const levelTestTitle = '혼자 뛰기 챌린지 (등급 심사)';
  static const levelTestSubtitle =
      '5회 혼자 달리기를 완주하면 등급 심사가 완료됩니다.';
  static const levelTestStatDistance = '현재 거리';
  static const levelTestStatDistanceValue = '3.52 KM';
  static const levelTestStatTime = '경과 시간';
  static const levelTestStatTimeValue = '18:14';
  static const levelTestStatPace = '현재 페이스';
  static const levelTestStatPaceValue = '5:10 /KM';
  static const levelTestChallengeProgress =
      '챌린지 진행 상황: 3/5회 완료 (3.52/5.00 KM)';
  static const levelTestGhostPace = '[고스트 페이스]';
  static const levelTestMyLocation = '[나(현재 위치)]';
  static const levelTestStartRun = '4회차 달리기 시작하기';

  // ── Challenge Lobby (Screen 7) ────────────────────────────────────
  static const lobbyCreateRoom = '+ 방 개설하기';
  static const lobbyTitle = '챌린지 로비';
  static const lobbySubtitle =
      '전 세계 러너들과 함께 달리고 가치를 증명하세요.';
  static const lobbyRoom1Title = '중급 3km 골드 챌린지 🏆';
  static const lobbyRoom1Sub = '참가자 12/20 · BEP: 283/400';
  static const lobbyRoom2Title = '크루 대항 주말 10K 매치 🔥';
  static const lobbyRoom2Sub = '참가 크루 8팀 · 주말 오전 09:00 시작';
  static const lobbyRoom3Title = '초보 1km 챌린지 (입장 제한)';
  static const lobbyRoom3Sub = 'Entry 료: 10만 SHARE · 실버 등급 이상 필요';
  static const lobbyEnterRoom = '입장하기';
  static const lobbyGradeBlocked = '하위 등급 차단';

  // ── Create Challenge Room (Screen 8) ──────────────────────────────
  static const createRoomScreenTitle = '챌린지 방 개설하기';
  static const createRoomScreenSubtitle =
      '전 세계 러너들과 경쟁할 룰을 직접 설정하세요.';
  static const createRoomTitleSection = '방 제목 설정';
  static const createRoomTitleHint = '어떤 목표로 달리시나요?';
  static const createRoomTitlePlaceholder = '예) 주말 10K 크루 대항전 🔥';
  static const createRoomTitleRequired = '방 제목을 입력해 주세요.';
  static const createRoomDistanceSection = '목표 거리 선택';
  static const createRoomDistanceHint = '목표 거리를 선택해 주세요.';
  static const createRoomEntryFeeSection = '대회 참가비 (SHARE)';
  static const createRoomFeeWarningRed =
      '* 결제하신 참가비는 플랫폼 대회 참여권 및 운영비로 귀속되며, ';
  static const createRoomFeeWarningGrey =
      '유저 간 상금 재원(N빵)으로 사용되지 않습니다.';
  static const createRoomPayAndCreateSuffix = 'SHARE 결제하고 방 개설하기';
  static const createRoomInsufficientShare =
      '가용 SHARE 잔액이 부족합니다. 충전 후 다시 시도해 주세요.';
  static const shareInsufficientTitle = 'SHARE 잔액 부족';
  static const shareInsufficientBody =
      '보유하신 SHARE가 부족합니다. 충전소로 이동하시겠습니까?';
  static const shareInsufficientNo = '아니오';
  static const shareInsufficientYes = '예';

  // ── External Payment (Screen 14) ──────────────────────────────────
  static const externalPaymentTitle = 'SHARE (쿠폰) 충전';
  static const externalPaymentSubtitle =
      '안전한 외부 결제(PG) 네트워크에 연결되었습니다.';
  static const externalPaymentMethodCard = '신용/체크카드';
  static const externalPaymentMethodToss = '토스페이';
  static const externalPaymentMethodNaver = '네이버페이';
  static const externalPaymentMethodTransfer = '계좌이체';
  static const externalPaymentNoticePrefix = '본 결제는 ';
  static const externalPaymentNoticeHighlight = '실제 야외 물리적 활동(오프라인 러닝)';
  static const externalPaymentNoticeSuffix = ' 참여를 위한 참가권 구매입니다.';
  static const externalPaymentRefundNote =
      '* 미사용 쿠폰에 한해 언제든 100% 수수료 없이 환불 가능합니다.';
  static const externalPaymentSecurePaySuffix = '원 안전 결제하기';

  // ── Challenge Detail (Screen 9) ───────────────────────────────────
  static const challengeDetailTitle = '3km 중급 챌린지 (골드 방)';
  static const challengeDetailEntryFee = '참가비: 30,000 SHARE';
  static const challengeDetailGoldBadge = 'Gold';
  static const challengeDetailPrize = '상금: 50만 원';
  static const challengeDetailDonation = '기부금: 유니세프 기부 50만 원';
  static const challengeDetailDistance = '거리: 3km';
  static const challengeDetailTimeRemaining = '남은 시간: 2일 14시간';
  static const challengeDetailRecruitment =
      '모집 인원: 290 / 400명 (최소 BEP: 283명)';
  static const challengeDetailDonationTarget =
      '타겟 기부처: 유니세프(결식아동)';
  static const challengeDetailValueTip =
      '과금 없이 목표 달성 시: +500 밸류(VALUE) 토큰 지급';
  static const challengeDetailCprTickets = '심폐소생권 보유: 0/3';
  static const challengeDetailJoin = '대회 참가';

  // ── Live Running (Screen 10) ────────────────────────────────────────
  static const liveRunningRoomTitle = '3km 중급 챌린지방';
  static const liveRunningGps = 'GPS';
  static const liveRunningStatDistance = '현재 거리';
  static const liveRunningStatDistanceValue = '1.8 km';
  static const liveRunningStatTime = '경과 시간';
  static const liveRunningStatTimeValue = '08:35';
  static const liveRunningStatPace = '현재 페이스';
  static const liveRunningStatPaceValue = '4:45 /km';
  static const liveRunningYouLabel = '나 (You)';
  static const liveRunningGhostPace = '고스트 페이스';
  static const liveRunningEffortTip =
      '순수 노력 목표: 완주 시 밸류 토큰 +100';
  static const liveRunningFinish = '종료 / 저장';
  static const liveRunningSubmissionsLeft = '제출 기회: 2/3회 남음';

  // ── Run Result (Screen 11) ──────────────────────────────────────────
  static const runResultTitle = '축하합니다!\n완주 성공 🎉';
  static const runResultFinalTimeLabel = '최종 시간:';
  static const runResultFinalTimeValue = '52:14';
  static const runResultAvgPaceLabel = '평균 페이스:';
  static const runResultAvgPaceValue = '6:15 /KM';
  static const runResultShareAmount = '+200';
  static const runResultShareEarned = 'SHARE 획득';
  static const runResultValueReward =
      '목표 달성! 순수 노력 보상 +100 밸류(VALUE) 획득';
  static const runResultDonate = '❤️ 기부처에 내 이름으로 기부하기';
  static const runResultShare = '🔗 기록 SNS 공유하기';

  // ── My Page (Screen 12) ───────────────────────────────────────────
  static const myPageTitle = '마이페이지';
  static const myPageSettings = '설정';
  static const myPageSubscriptionManage = '구독 관리';
  static const myPageNickname = '러너상기';
  static const myPageGoldGrade = '골드 등급';
  static const myPageStreak = '🔥 현재 연속 출석(Streak): 12일';
  static const myPageMonthlyDistanceLabel = '이번 달 총 거리:';
  static const myPageMonthlyDistanceValue = '42.5 KM';
  static const myPageAvgPaceLabel = '평균 페이스:';
  static const myPageAvgPaceValue = '5:40 /KM';

  // ── Store & Funding (Screen 13) ───────────────────────────────────
  static const storeTitle = '상점 & 기부 펀딩';
  static const storeShareBalance = '90,000';
  static const storeDiamondBalance = '5';
  static const storeValueBalance = '5,200';
  static const storeFundingTitle =
      '🌍 땀방울로 만드는 기적,\n유니세프 결식아동 펀딩';
  static const storeFundingProgress = '85% 달성';
  static const storeDonateButton = '500 밸류(VALUE) 기부하기';
  static const storeFunctionalItems = '기능성 아이템';
  static const storeItemCpr = '기록 심폐소생권';
  static const storeItemSafeGuard = '세이프 가드';
  static const storeItemStarBoost = '스타 부스트';
  static const storeItemSharePack = 'SHARE 팩';
  static const storeBuyDia = '30 DIA 구매';
  static const storeChargeCta = 'SHARE 충전';
  static const storeValueDetailTitle = 'VALUE 토큰 상세';
  static const storeValueExternalTransfer = '외부 지갑 전송 (보안 승인)';
  static const storeValueTransferConfirmTitle = '특금법 보안 승인';
  static const storeValueTransferCancel = '취소';
  static const storeValueTransferApprove = '이해하고 전송 화면으로';
  static const walletHistoryShortcutTooltip = '재화 히스토리';
  static const iapBillingTitle = 'SHARE (참가 쿠폰) 충전소';
  static const iapBillingSubtitle = '구글 플레이 공식 보안 결제를 적용합니다.';

  // ── Pro Tools (Screen 15) ─────────────────────────────────────────
  static const proToolsTitle = '러닝 기어 & 프로 툴';
  static const proToolsSubtitle =
      '장비의 수명을 관리하고 AI 리포트로 성장하세요.';
  static const proToolsRegisteredShoe = '등록된 러닝화: 나이키 베이퍼플라이 3';
  static const proToolsMileageStats = '420km / 500km (84%)';
  static const proToolsCushionWarning =
      '쿠션 수명이 80km 남았습니다.\n부상 방지를 위해 교체 시기가 다가옵니다.';
  static const proToolsMenuPaceCalc = '목표 거리에 따른 페이스 계산기 (VDOT)';
  static const proToolsMenuAiReport = 'AI 심층 러닝 리포트 (구간별 페이스 분석)';
  static const proToolsMenuCrewRanking = '소속 크루(Crew) 출석률 랭킹 보드';

  // ── Brand Sponsor (Screen 16) ─────────────────────────────────────
  static const brandSponsorScreenTitle = '브랜드 스폰서 챌린지';
  static const lobbySponsorRoomTitle = '나이키 브랜드 스폰서 방';
  static const lobbySponsorRoomSub =
      '무료 참가 · 스폰서 100% 대납 · 8,500명 참여 중';
  static const brandSponsorTicker =
      '✨ 나이키 코리아가 이번 대회의 러너들을 전면 후원합니다! ✨';
  static const brandSponsorChallengeTitle = 'Nike 주말 5km 특별 챌린지';
  static const brandSponsorEntryFee = '참가비: 0 SHARE (스폰서 100% 대납)';
  static const brandSponsorWinReward =
      '우승 보상: 나이키 자사몰 30% 할인 쿠폰 + 500';
  static const brandSponsorDonationPledge =
      '기부 공약: 1등 우승자와 이름으로 유니세프 500만 원 기부';
  static const brandSponsorBenevolentFailure =
      '자비로운 실패: 미션에 실패하더라도 우승자와 공동 명의로 유니세프에 기부가 진행됩니다.';
  static const brandSponsorDisclaimer =
      '* 세부 처리상 기부금 세액공제 혜택은 후원 기업에게 귀속됩니다.';
  static const brandSponsorStatus =
      '남은 시간 및 모집 인원(예: 8,500명 참여 중)';
  static const brandSponsorJoinCta = '스폰서 후원받고 무료 참가하기';

  // ── Personal Sponsor (Screen 17) ──────────────────────────────────
  static const personalSponsorTitle = '러너 후원하기 (스폰서십)';
  static const personalSponsorBadgeHint =
      '후원 시 프로필에 천사 뱃지가 영구 노출됩니다';
  static const personalSponsorAmount = '50,000 SHARE';
  static const personalSponsorMonthlyToggle =
      "월간 '셰어 멤버십'으로 매월 정기 후원하기";
  static const personalSponsorPurposeLabel =
      '후원금의 사용 목적을 직접 선택해 주세요.';
  static const personalSponsorPrizeTitle = '[순수 상금 지원]';
  static const personalSponsorPrizeDesc =
      '후원금이 1등 러너에게 순수 상금 보너스로 직접 지급됩니다.';
  static const personalSponsorDonationTitle = '[우승자 명의 기부]';
  static const personalSponsorDonationDesc =
      '후원금이 1등 러너의 이름으로 유니세프에 기부됩니다.';
  static const personalSponsorActive = 'ACTIVE';
  static const personalSponsorCta = '50,000 SHARE 후원하고 천사 되기';
  static const myPageAngelSponsor = '천사 후원';

  // ── Running Crew (Screen 18) ──────────────────────────────────────
  static const runningCrewTitle = '러닝 크루 (Crew)';
  static const runningCrewMyCrewName = '서울 나이트 러너스 🌙';
  static const runningCrewMyCrewStats =
      '소속 크루원: 45/50명 | 누적 달성 거리: 3,240km';
  static const runningCrewCreateButton =
      '[50,000 SHARE 결제하고 새 크루(방장) 창설하기]';
  static const runningCrewRankingTitle = '이번 주 전국 크루 랭킹';
  static const runningCrewRank1Label = '1위';
  static const runningCrewRank1Name = '강남 스피드 클럽';
  static const runningCrewRank1Distance = '1,200km';
  static const runningCrewRank2Label = '2위';
  static const runningCrewRank2Name = '부산 오션 러너스';
  static const runningCrewRank2Distance = '980km';
  static const runningCrewRank5Label = '5위';
  static const runningCrewProgressLabel = '이번 주 크루 대항전 10K 완주율';
  static const runningCrewProgressValue = '80%';
  static const runningCrewEnterRoom = '크루 대항 챌린지 룸 입장하기';

  // ── Crew Manager (Screen 19) ──────────────────────────────────────
  static const crewManagerTitle = '크루 관리 (방장 전용)';
  static const crewManagerCrewName = '서울 나이트 러너스';
  static const crewManagerPushNotice = '전체 공지 푸시 발송 (무료)';
  static const crewManagerPremiumSection = '프리미엄 설정';
  static const crewManagerProfileLabel = '크루 프로필';
  static const crewManagerProfileChange = '이름/엠블럼 변경 (100 DIA)';
  static const crewManagerGiftSection = '크루원 혜택 하사(선물)';
  static const crewManagerGiftCpr =
      '🎁 심폐소생권/세이프가드 전체 선물 (DIA)';
  static const crewManagerGiftDeposit =
      '🛡️ 크루 대항전 예치금 방장 대납 (DIA/SHARE)';
  static const crewManagerGiftAngelBadge = 'Angel Badge 획득하세요';
  static const crewManagerShareWarning = 'SHARE 결제 시 주의하세요';
  static const crewManagerGiftPass =
      '🎉 크루 전용 챌린지 패스 & 스킨 구매 (DIA)';
  static const crewManagerMemberSection = '소속 팀원 관리 (50 / 50명)';
  static const crewManagerExpandMembers = '+10명 인원 한도 확장하기 (300 DIA)';
  static const crewManagerAppointVice = '부방장 임명';
  static const crewManagerForceKick = '강제 퇴출';
  static const crewManagerSave = '관리 설정 저장하기';
  static const crewManagerMember1 = '김나운';
  static const crewManagerMember2 = '이승우';
  static const crewManagerMember3 = '최서연';

  // ── Item Inventory (Screen 20) ──────────────────────────────────────
  static const itemInventoryTitle = '내 아이템 보관함';
  static const itemInventoryCprTitle = '기록 심폐소생권';
  static const itemInventoryCprQuantity = '보유량: 3/3';
  static const itemInventorySafeGuardTitle = '세이프 가드';
  static const itemInventorySafeGuardQuantity = '보유량: 1/1';
  static const itemInventoryUse = '사용하기';

  // ── Refund (Screen 21) ────────────────────────────────────────────
  static const refundTitle = '결제 취소 및 환불';
  static const refundGuaranteeTitle = '안전 환불 보장';
  static const refundPolicy1 =
      '- 전자상거래법에 의거, 결제 후 7일 이내 미사용 재화는 수수료 없이 100% 현금 환불됩니다.';
  static const refundPolicy2 = '- 대회 모집 인원(BEP) 미달 시 전액 원복됩니다.';
  static const refundTargetItem = '[ 50,000 SHARE (미사용) ]';
  static const refundPaymentDate = 'Payment Date: 2026.06.25';
  static const refundTotalAmount = '총 환불 예정 금액: 50,000 KRW';
  static const refundCancelCta = '수수료 없이 결제 취소하기 (현금 환불)';

  // ── Web3 Wallet (Screen 22) ─────────────────────────────────────────
  static const web3WalletTitle = '지갑 연결 및 토큰 전송';
  static const web3WalletConnected = 'MetaMask 지갑 연동 완료';
  static const web3WalletAddress = '0x1A2b...3C4d';
  static const web3WalletCopy = '복사';
  static const web3WalletValueBalance = '보유 밸류(VALUE): 5,200';
  static const web3WalletTransferAmount = '5,000 VALUE';
  static const web3WalletMax = 'MAX(최대)';
  static const web3WalletGasFee = '전송 수수료(가스비): 10 VALUE';
  static const web3WalletVaspWarning =
      '특정금융정보법(VASP)에 따라 앱 내 현금 환전은 지원하지 않으며, 외부 개인 지갑으로만 전송 가능합니다.';
  static const web3WalletTransferCta = '내 Web3 지갑으로 전송하기 (Transfer)';

  // ── Stamp Tour (Screen 23) ──────────────────────────────────────────
  static const stampTourTitle = '스탬프 투어 & 미션';
  static const stampTourVisitComplete = '방문 완료!';
  static const stampTourLandmarkGangbyeon = '강변 공원';
  static const stampTourLandmarkNamsan = '남산타워';
  static const stampTourLandmarkModoil = '모도일 공원';
  static const stampTourMissionWalk = '오늘 가볍게 1km 걷기';
  static const stampTourMissionWalkReward = '1 획득 완료';
  static const stampTourMissionStamp = '우리 동네 랜드마크 스탬프 찍기 (1/3)';
  static const stampTourMissionInProgress = '진행 중';
  static const dashboardStampTourCta = '스탬프 투어 확인하기';

  // ── Battle Pass (Screen 24) ─────────────────────────────────────────
  static const battlePassTitle = '배틀런 패스 (Season 1)';
  static const battlePassPremiumActive = '👑 프리미엄 패스 활성화 중';
  static const battlePassCurrentLevel = '현재 레벨: Lv. 15';
  static const battlePassProgressLabel = '80%';
  static const battlePassFreeReward = '무료 보상';
  static const battlePassPremiumReward = '프리미엄 보상';
  static const battlePassFreeShare = '100 SHARE';
  static const battlePassPremiumDia = '3 다이아몬드';
  static const lobbyBattlePassCta = '시즌 1 배틀런 패스 확인';

  // ── Subscription Management (Screen 25) ───────────────────────────
  static const subscriptionTitle = '구독 및 정기 후원 관리';
  static const subscriptionDonationTitle = '글로벌 결식아동 정기 후원';
  static const subscriptionDonationStatus =
      '매월 10,000 SHARE 자동 후원 중\n(다음 결제일: 2026.07.15)';
  static const subscriptionPremiumTitle = 'SRC 프리미엄 멤버십';
  static const subscriptionPremiumBenefit1 = '모든 전면 광고 제거';
  static const subscriptionPremiumBenefit2 = 'AI 심층 분석 리포트 무제한';
  static const subscriptionPremiumPrice = '월 4,900원 (첫 달 무료 시작하기)';
  static const subscriptionPaymentMethodCta =
      '정기 결제 수단 변경하기 (카드/계좌)';

  // ── Hall of Fame (Screen 26) ──────────────────────────────────────
  static const hallOfFameTitle = '명예의 전당 (Hall of Fame)';
  static const hallOfFameLeaderTitle = '👑 이달의 소셜 임팩트 리더';
  static const hallOfFameSpecialSbt = 'SPECIAL SBT';
  static const hallOfFameLeaderName = '서울 나이트 러너스 방장님';
  static const hallOfFameLeaderDonation = '누적 기부: 5,000,000 VALUE';
  static const hallOfFameRank2Label = '2등';
  static const hallOfFameRank2Subtitle = '연속 50일 완주자';
  static const hallOfFameRank2Badge = '🔥 불꽃 SBT 뱃지';
  static const hallOfFameRank2Value = '3,200,000 VALUE';
  static const hallOfFameRank3Label = '3등';
  static const hallOfFameRank3Subtitle = '최다 크루원 후원자';
  static const hallOfFameRank3Badge = '🛡️ 방패 SBT 뱃지';
  static const hallOfFameRank3Value = '2,800,000 VALUE';
  static const hallOfFameDonateCta = '나도 기부하고 명예의 전당 오르기 💎';
  static const runningCrewHallOfFame = '👑 명예의 전당';

  // ── Appeal / Customer Service (Screen 27) ────────────────────────
  static const appealTitle = '기록 소명 및 고객센터';
  static const appealWarningTitle = 'Jena AI 기록 검증 보류 안내';
  static const appealWarningBody =
      '최근 제출하신 [중급 3km 챌린지] 기록이 비정상적인 GPS/심박수 패턴으로 인해 보류 처리되었습니다. 억울한 경우 아래 폼을 통해 소명 자료를 제출해 주세요.';
  static const appealFormTitle = '소명 자료 첨부 폼';
  static const appealReasonGps = '단순 GPS 수신 불량 / 음영 지역';
  static const appealReasonWatchSensor = '스마트워치 센서 일시적 접촉 불량';
  static const appealReasonExternalMismatch = '외부 러닝 앱 기록 불일치';
  static const appealReasonOther = '기타 사유 직접 입력';
  static const appealReasonOptions = <String>[
    appealReasonGps,
    appealReasonWatchSensor,
    appealReasonExternalMismatch,
    appealReasonOther,
  ];
  static const appealUploadLabel = '[ 📷 + 외부 앱 기록 및 로그 업로드 ]';
  static const appealDetailHint = '상세 사유를 입력해 주세요.';
  static const appealSubmitCta = '소명 자료 제출하기 (관리자 검토)';
  static const appealProofRequiredSnack =
      '증빙용 가민/외부 러닝기록 사진을 최소 1개 이상 업로드해야 합니다';
  static const appealSubmitSuccessTitle = '소명 자료 제출 완료';
  static const appealSubmitSuccessBody =
      '관리자 검토 대기(under_review) 상태로 접수되었습니다. 심사 결과는 알림으로 안내됩니다.';
  static const dashboardVerificationHoldBanner = '기록 검증 보류';

  // ── Notification Center (Screen 28) ──────────────────────────────
  static const notificationCenterTitle = '알림 및 내역 (History)';
  static const notificationTabSystem = '시스템 알림';
  static const notificationTabPayment = '결제/히스토리';
  static const notification1Title = 'Jena AI 검증 완료!';
  static const notification1BodyPrefix =
      '중급 3km 챌린지 기록이 승인되어 ';
  static const notification1Highlight = '100 밸류 토큰(VALUE)';
  static const notification1BodySuffix = '이 지갑으로 자동 입금되었습니다.';
  static const notification1Time = '방금 전';
  static const notification2Title = '크루 방장님의 하사품';
  static const notification2BodyPrefix = '서울 나이트 러너스 방장님이 ';
  static const notification2Highlight = '\'기록 심폐소생권\'';
  static const notification2BodySuffix = '을 선물했습니다!';
  static const notification2Time = '2시간 전';
  static const notification3Title = '결제 취소 완료';
  static const notification3Body =
      '대회 무산으로 인해 50,000 SHARE 현금 환불이 정상 처리되었습니다.';
  static const notification3Time = '어제';
  static const notificationPaymentEmpty = '거래 및 결제 내역이 존재하지 않습니다. 🪙';
  static const notificationPaymentReceipt = '안전 결제 영수증 완료 🪙';
  static const notificationPaymentUnknown = '알 수 없는 거래';
  static const notificationPaymentJustNow = '방금 전';
  static const notificationSystemEmpty = '도달한 새로운 알림이 없습니다. 🔔';
  static const notificationSystemFallbackTitle = '알림';
}
