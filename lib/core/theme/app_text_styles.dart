import 'package:flutter/material.dart';

import 'app_colors.dart';

/// SRC 앱 전역 타이포그래피.
///
/// [Theme.of(context).textTheme]과 함께 사용하거나,
/// 독립적으로 직접 참조할 수 있습니다.
abstract final class AppTextStyles {
  static const String _fontFamily = 'Pretendard';

  /// 로고 상단 "SRC" 텍스트
  static const logoMark = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
    color: AppColors.primaryMint,
    height: 1.0,
  );

  /// 메인 타이틀 — "쉐어 런 챌린지 (SRC)"
  static const header1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textBlack,
    height: 1.3,
  );

  /// 서브 타이틀 — "세계를 향한 나눔의 질주"
  static const subtitle1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    color: AppColors.textGrey,
    height: 1.4,
  );

  /// 소셜 로그인 버튼 텍스트
  static const buttonText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.2,
  );

  /// 입력 필드 라벨 — "추천 코드가 있으신가요?"
  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textGrey,
    height: 1.4,
  );

  /// 입력 필드 placeholder / 입력 텍스트
  static const inputText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textBlack,
    height: 1.4,
  );

  static const inputHint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textGreyLight,
    height: 1.4,
  );

  /// 약관 화면 메인 타이틀
  static const termsTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textBlack,
    height: 1.35,
  );

  /// 약관 화면 서브 타이틀
  static const termsSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: AppColors.textGrey,
    height: 1.45,
  );

  /// 약관 항목 라벨
  static const agreementLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: AppColors.textBlack,
    height: 1.4,
  );

  /// [전체 동의] 강조 라벨
  static const agreementAllLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.textBlack,
    height: 1.3,
  );

  /// 보조 링크 (게스트 로그인 등)
  static const link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.primaryMint,
    height: 1.4,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primaryMint,
  );
}
