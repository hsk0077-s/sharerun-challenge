import 'package:flutter/material.dart';

/// SRC 앱 전역 컬러 팔레트.
///
/// 로그인 화면 및 이후 28개 화면에서 공통으로 사용합니다.
abstract final class AppColors {
  // Brand
  static const primaryMint = Color(0xFF76C8A7);
  static const primaryMintDark = Color(0xFF5BB896);
  static const primaryMintLight = Color(0xFF88D1B1);

  /// 설정·웰니스 UI 포인트 (티얼 액센트).
  static const tealAccent = Color(0xFF11B79C);

  /// 하단 투과 펄스 광원 (하이엔드 웰니스 캔버스).
  static const pulseCyan = Color(0xFF00F0FF);

  /// 홈·마이페이지 다크 실버 캔버스.
  static const luxuryCanvas = Color(0xFF1A1D22);
  static const luxurySilver = Color(0xFF2C3138);
  static const luxurySilverMid = Color(0xFF24282F);
  static const luxuryOnCanvas = Color(0xFFF4F7FA);

  /// 글래스 카드 필 (불투명도 85%).
  static const glassFill = Color(0xD9FFFFFF);
  static const glassRim = Color(0x8CFFFFFF);

  /// 고스트 페이스 마커 (반투명 보라).
  static const ghostPacePurple = Color(0xFF7E57C2);

  /// src-10 라이브 러닝 다크 배경.
  static const liveRunningBackground = Color(0xFF1E1E1E);
  static const liveMapBackground = Color(0xFF2A2A2A);

  /// 설정 화면 은은한 그레이 백그라운드.
  static const settingsBackground = Color(0xFFF2F3F5);

  // Background gradient — 상단 연민트 → 하단 흰색
  static const bgGradientStart = Color(0xFFE8F5E9);
  static const bgGradientMid = Color(0xFFF5FBF7);
  static const bgGradientEnd = Color(0xFFFFFFFF);

  // Social login
  static const googleWhite = Color(0xFFFFFFFF);
  static const naverGreen = Color(0xFF03C75A);
  static const kakaoYellow = Color(0xFFFEE500);

  // Text
  static const textBlack = Color(0xFF000000);
  static const textGrey = Color(0xFF757575);
  static const textGreyLight = Color(0xFF9E9E9E);
  static const textWhite = Color(0xFFFFFFFF);

  // Surfaces & borders
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE0E0E0);
  static const borderGrey = Color(0xFFBDBDBD);

  /// 약관 동의 박스 배경
  static const agreementBoxFill = Color(0xFFE8F7F2);

  /// 비활성 버튼 배경
  static const buttonDisabled = Color(0xFFBDBDBD);

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
  static const walletCardFill = Color(0xFFF0FAF9);

  /// My Wallet 화면 — 분석된 DS 토큰
  static const myWalletBackground = Color(0xFFF0F9F6);
  static const myWalletMint = Color(0xFF00C896);
  static const myWalletInk = Color(0xFF2D2D2D);
  static const myWalletMuted = Color(0xFFA5A5A5);
  static const myWalletDiamond = Color(0xFF3B82F6);
  static const myWalletProgressOrange = Color(0xFFFF8A3D);

  /// 등급 진행 바 시작색
  static const progressYellow = Color(0xFFFFD54F);

  // Semantic
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF43A047);

  /// Jena 보류 경고 — 파스텔 오렌지 테두리/포인트.
  static const warning = Color(0xFFFFB74D);

  /// Jena 보류 카드 글래스 필.
  static const warningFill = Color(0xFFFFF6E8);

  /// 러닝화 마일리지 경고 / 프로그레스 그라데이션 끝색
  static const warningOrange = Color(0xFFFF5722);

  /// Nike B2B 스폰서 브랜드 컬러
  static const nikeBlack = Color(0xFF111111);
  static const voltYellow = Color(0xFFCEFF00);

  /// 개인 스폰서십(천사) 모달 배경 — 피치 → 화이트
  static const sponsorBgGradientStart = Color(0xFFFFE8DC);
  static const sponsorBgGradientMid = Color(0xFFFFF5F0);
  static const sponsorBgGradientEnd = Color(0xFFFFFFFF);
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
}
