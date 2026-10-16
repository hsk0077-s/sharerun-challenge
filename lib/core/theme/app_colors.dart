import 'package:flutter/material.dart';

/// SRC 앱 전역 컬러 팔레트 (single source of truth).
///
/// Visual language: **1 primary (mint) + 1 accent (teal) + neutrals**,
/// plus donation gold for emotional moments. Hex values come from the
/// existing SRC brand already used by [SrcTheme] — do not add a second
/// mint/teal. Later screens should prefer `context.srcTokens.colors`
/// or [ColorScheme]; keep this class for named extras (social, Garmin).
///
/// 시각 언어: 프라이머리 민트 1 + 액센트 틸 1 + 뉴트럴. 기부 감정은 골드.
abstract final class AppColors {
  // Night — 검정 바탕 + 라임 (새 디자인). [SrcTheme.night]에서만 쓴다.
  static const nightBg = Color(0xFF070B09);
  static const nightCard = Color(0xFF101813);
  static const nightLine = Color(0xFF1F2B24);
  static const nightInk = Color(0xFFE8EFE6);
  static const nightMuted = Color(0xFF93A299);
  static const nightLime = Color(0xFFD4FF4A);
  static const nightOnLime = Color(0xFF0A1410);
  static const nightGold = Color(0xFFE8B84B);
  static const nightDanger = Color(0xFFFF6B6B);

  // Brand — primary
  static const primaryMint = nightLime;
  static const primaryMintDark = Color(0xFFB4E03A);
  static const primaryMintLight = Color(0xFFE2FF86);

  /// Role alias for [primaryMint].
  static const Color primary = primaryMint;

  /// 설정·웰니스 UI 포인트 (티얼 액센트).
  static const tealAccent = nightLime;

  /// Role alias for [tealAccent] (the single accent).
  static const Color accent = tealAccent;

  /// 하단 투과 펄스 광원 (하이엔드 웰니스 캔버스).
  static const pulseCyan = Color(0xFF00F0FF);

  /// 홈·마이페이지 다크 실버 캔버스.
  static const luxuryCanvas = Color(0xFF1A1D22);
  static const luxurySilver = Color(0xFF2C3138);
  static const luxurySilverMid = Color(0xFF24282F);
  static const luxuryOnCanvas = Color(0xFFF4F7FA);

  /// 글래스 카드 필 (불투명도 85%).
  static const glassFill = Color(0xD9101813);
  static const glassRim = Color(0x8C1F2B24);

  /// 고스트 페이스 마커 (반투명 보라).
  static const ghostPacePurple = Color(0xFF7E57C2);

  /// src-10 라이브 러닝 다크 배경.
  static const liveRunningBackground = Color(0xFF1E1E1E);
  static const liveMapBackground = Color(0xFF2A2A2A);

  /// 설정 화면 은은한 그레이 백그라운드.
  static const settingsBackground = nightBg;

  // Background gradient — 상단 연민트 → 하단 흰색
  static const bgGradientStart = Color(0xFF0B120E);
  static const bgGradientMid = nightBg;
  static const bgGradientEnd = nightBg;

  // Social login
  static const googleWhite = Color(0xFFFFFFFF);
  static const naverGreen = Color(0xFF03C75A);
  static const kakaoYellow = Color(0xFFFEE500);

  /// 브랜드 버튼(카카오·구글·애플) 위의 글자색. 앱 글자색(밝은 회색)과 별개로 고정이다.
  static const brandInk = Color(0xFF191919);

  // Text
  static const textBlack = nightInk;
  static const textGrey = nightMuted;
  static const textGreyLight = Color(0xFF6F7F76);
  static const textWhite = Color(0xFFFFFFFF);

  // Surfaces & borders
  static const surfaceWhite = nightCard;
  static const borderLight = nightLine;
  static const borderGrey = Color(0xFF2E3C34);

  /// 약관 동의 박스 배경
  static const agreementBoxFill = Color(0xFF14201A);

  /// 비활성 버튼 배경
  static const buttonDisabled = Color(0xFF2A3630);

  /// Garmin OAuth 로그인 버튼
  static const garminAuthButton = Color(0xFF333D47);

  /// 외부 PG 결제 CTA 버튼
  static const paymentButtonBlue = Color(0xFF3182F6);

  /// 토스페이 브랜드 블루
  static const tossBlue = Color(0xFF3182F6);

  /// 골드 등급 뱃지 배경
  static const goldBadge = Color(0xFFFDE047);

  /// 25티어 메달 틴트 (Chibi 아바타 / 뱃지 UI)
  static const tierMedalBronze = Color(0xFFCD7F32);
  static const tierMedalSilver = Color(0xFFC0C0C0);
  static const tierMedalGold = goldBadge;
  static const tierMedalDiamond = Color(0xFF7DD3FC);
  static const tierMedalMaster = Color(0xFFA78BFA);

  /// 지갑 카드 배경
  static const walletCardFill = nightCard;

  /// My Wallet 화면 — 분석된 DS 토큰
  static const myWalletBackground = nightBg;
  static const myWalletMint = nightLime;
  static const myWalletInk = nightInk;
  static const myWalletMuted = nightMuted;
  static const myWalletDiamond = Color(0xFF7DD3FC);
  static const myWalletProgressOrange = Color(0xFFFF8A3D);

  /// 등급 진행 바 시작색
  static const progressYellow = Color(0xFFFFD54F);

  // Semantic
  static const error = nightDanger;
  static const success = Color(0xFF6BD68A);

  /// Jena 보류 경고 — 파스텔 오렌지 테두리/포인트.
  static const warning = nightGold;

  /// Jena 보류 카드 글래스 필.
  static const warningFill = Color(0xFF2A2412);

  /// 러닝화 마일리지 경고 / 프로그레스 그라데이션 끝색
  static const warningOrange = Color(0xFFFF5722);

  /// Nike B2B 스폰서 브랜드 컬러
  static const nikeBlack = Color(0xFF111111);
  static const voltYellow = Color(0xFFCEFF00);

  /// 개인 스폰서십(천사) 모달 배경 — 피치 → 화이트
  static const sponsorBgGradientStart = Color(0xFF1C140E);
  static const sponsorBgGradientMid = Color(0xFF110D0A);
  static const sponsorBgGradientEnd = nightBg;
  static const angelGold = Color(0xFFE8B84B);

  static const sponsorBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sponsorBgGradientStart, sponsorBgGradientMid, sponsorBgGradientEnd],
    stops: [0.0, 0.42, 1.0],
  );

  /// 홈·마이페이지 다크 실버 수직 그라데이션 (하단 시안 펄스는 위젯에서 합성).
  static const luxuryCanvasGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [luxuryCanvas, luxurySilverMid, luxurySilver],
    stops: [0.0, 0.55, 1.0],
  );

  /// 로그인 배경용 수직 그라데이션.
  static const loginBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgGradientStart, bgGradientMid, bgGradientEnd],
    stops: [0.0, 0.42, 1.0],
  );

  // ---------------------------------------------------------------------------
  // Compatibility aliases — former `lib/app/theme` Black-Neon leftovers.
  // Hex now matches SrcTheme. Remaining screens (shop, crew, join/detail)
  // should stop using neonLime / cardBlack names in later visual slices.
  // ---------------------------------------------------------------------------
  static const Color bgWhite = surfaceWhite;
  static const Color primaryTeal = tealAccent;
  static const Color oledBlack = surfaceWhite;
  static const Color surfaceBlack = bgGradientEnd;
  static const Color cardBlack = surfaceWhite;
  static const Color neonLime = primaryMint;
  static const Color electricBlue = tealAccent;
  static const Color dangerRed = error;
  static const Color textPrimary = textBlack;
  static const Color textSecondary = textGrey;
}
