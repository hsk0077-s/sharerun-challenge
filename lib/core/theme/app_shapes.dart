import 'package:flutter/material.dart';

import 'app_colors.dart';

/// SRC 앱 전역 Shape 상수.
abstract final class AppShapes {
  /// 소셜 로그인 버튼 — 스타디움 형태 (완전 둥근 캡슐)
  static const double buttonRadius = 30;

  /// 텍스트 입력 필드
  static const double inputRadius = 8;

  /// 카드 / 패널
  static const double cardRadius = 12;

  /// 소셜 로그인 버튼 높이
  static const double buttonHeight = 54;

  /// 입력 필드 높이
  static const double inputHeight = 48;

  /// 입력 필드 테두리 두께
  static const double inputBorderWidth = 1;

  /// 로그인 화면 콘텐츠 너비 비율
  static const double loginContentWidthFactor = 0.9;

  /// 로그인 화면 상단 여백 (화면 높이 대비, 목업 ~7%)
  static const double loginTopInsetFactor = 0.07;

  /// 소셜 버튼 수직 간격
  static const double loginButtonSpacing = 14;

  /// 소셜 버튼 ↔ 추천코드 섹션 간격
  static const double loginReferralTopGap = 36;

  /// 로그인 헤더 로고 너비 (목업: 버튼 대비 크게, 화면 너비의 ~62%)
  static const double loginLogoWidthFactor = 0.62;

  /// src_logo_mark.png 비율 (높이 ÷ 너비)
  static const double loginLogoMarkAspectRatio = 368 / 1024;

  /// 로그인 헤더 상단 패딩 (목업 기준)
  static const double loginHeaderTopPadding = 28.0;

  /// 로고 ↔ 한글 타이틀 간격
  static const double loginLogoToTitleGap = 16.0;

  /// 메인 타이틀 ↔ 서브타이틀 간격
  static const double loginTitleToSubtitleGap = 8;

  /// 추천코드 라벨 ↔ 입력창 간격
  static const double loginLabelToInputGap = 6;

  /// 소셜 버튼 아이콘 좌측 패딩
  static const double buttonIconLeftPadding = 24;

  /// Google 버튼 테두리 두께
  static const double googleButtonBorderWidth = 1;

  /// 약관 동의 박스 모서리
  static const double agreementBoxRadius = 12;

  /// 약관 화면 좌우 패딩
  static const double termsHorizontalPadding = 20;

  /// OAuth 카드 모서리
  static const double oauthCardRadius = 16;

  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(buttonRadius);

  static BorderRadius get inputBorderRadius =>
      BorderRadius.circular(inputRadius);

  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(cardRadius);

  static RoundedRectangleBorder get buttonShape => RoundedRectangleBorder(
        borderRadius: buttonBorderRadius,
      );

  static OutlineInputBorder get inputBorder => OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: const BorderSide(
          color: AppColors.borderLight,
          width: inputBorderWidth,
        ),
      );

  static OutlineInputBorder get inputFocusedBorder => OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: const BorderSide(
          color: AppColors.primaryMint,
          width: 1.5,
        ),
      );
}
