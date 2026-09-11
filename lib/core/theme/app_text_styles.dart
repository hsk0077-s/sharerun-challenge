import 'package:flutter/material.dart';

import 'app_colors.dart';

/// SRC 앱 전역 타이포그래피.
///
/// Scale (display → overline) is the Phase 2 source of truth.
/// Named styles (`header1`, `caption`, …) stay for existing screens.
/// New UI should use [Theme.of(context).textTheme] or the scale names.
abstract final class AppTextStyles {
  static const String fontFamily = 'Pretendard';
  static const String _fontFamily = fontFamily;

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

  // --- Type scale (Phase 2+). Sizes align with existing named styles. ---

  /// 26 / w700 — same as [termsTitle].
  static const display = termsTitle;

  /// 24 / w700 — same as [header1].
  static const headline = header1;

  /// 22 / w700 — section titles.
  static const title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textBlack,
    height: 1.3,
  );

  /// 18 / w700 — card titles.
  static const titleSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textBlack,
    height: 1.3,
  );

  /// 11 / w500 — overline / nav labels.
  static const overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textGrey,
    height: 1.2,
  );
}
