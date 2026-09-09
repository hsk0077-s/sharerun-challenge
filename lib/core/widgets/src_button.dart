import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_text_styles.dart';

/// 소셜 로그인 및 공통 액션 버튼 변형.
enum SRCButtonVariant {
  google,
  apple,
  naver,
  kakao,
  primary,
  outline,
}

/// SRC 디자인 시스템 공통 버튼.
///
/// 소셜 로그인(Google / Naver / Kakao)과 일반 액션 버튼에 사용합니다.
class SRCButton extends StatelessWidget {
  const SRCButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = SRCButtonVariant.primary,
    this.leading,
    this.enabled = true,
    this.isLoading = false,
  });

  const SRCButton.google({
    required this.label,
    required this.onPressed,
    super.key,
    this.leading,
    this.enabled = true,
    this.isLoading = false,
  }) : variant = SRCButtonVariant.google;

  const SRCButton.apple({
    required this.label,
    required this.onPressed,
    super.key,
    this.leading,
    this.enabled = true,
    this.isLoading = false,
  }) : variant = SRCButtonVariant.apple;

  const SRCButton.naver({
    required this.label,
    required this.onPressed,
    super.key,
    this.leading,
    this.enabled = true,
    this.isLoading = false,
  }) : variant = SRCButtonVariant.naver;

  const SRCButton.kakao({
    required this.label,
    required this.onPressed,
    super.key,
    this.leading,
    this.enabled = true,
    this.isLoading = false,
  }) : variant = SRCButtonVariant.kakao;

  final String label;
  final VoidCallback? onPressed;
  final SRCButtonVariant variant;
  final Widget? leading;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();
    final canTap = enabled && !isLoading && onPressed != null;
    final displayStyle = !canTap && variant == SRCButtonVariant.primary
        ? const _ButtonStyle(
            backgroundColor: AppColors.buttonDisabled,
            foregroundColor: AppColors.textWhite,
          )
        : style;

    return SizedBox(
      width: double.infinity,
      height: AppShapes.buttonHeight,
      child: Material(
        color: displayStyle.backgroundColor,
        shape: AppShapes.buttonShape.copyWith(
          side: displayStyle.borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canTap ? onPressed : null,
          child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: displayStyle.foregroundColor,
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        if (leading != null)
                          Positioned(
                            left: AppShapes.buttonIconLeftPadding,
                            child: leading!,
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: leading != null ? 48 : 20,
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.buttonText.copyWith(
                              color: displayStyle.foregroundColor,
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  _ButtonStyle _resolveStyle() {
    return switch (variant) {
      SRCButtonVariant.google => const _ButtonStyle(
          backgroundColor: AppColors.googleWhite,
          foregroundColor: AppColors.textBlack,
          borderSide: BorderSide(
            color: AppColors.borderLight,
            width: AppShapes.googleButtonBorderWidth,
          ),
        ),
      SRCButtonVariant.apple => const _ButtonStyle(
          backgroundColor: AppColors.textBlack,
          foregroundColor: AppColors.textWhite,
        ),
      SRCButtonVariant.naver => const _ButtonStyle(
          backgroundColor: AppColors.naverGreen,
          foregroundColor: AppColors.textWhite,
        ),
      SRCButtonVariant.kakao => const _ButtonStyle(
          backgroundColor: AppColors.kakaoYellow,
          foregroundColor: AppColors.textBlack,
        ),
      SRCButtonVariant.primary => const _ButtonStyle(
          backgroundColor: AppColors.primaryMint,
          foregroundColor: AppColors.textWhite,
        ),
      SRCButtonVariant.outline => const _ButtonStyle(
          backgroundColor: AppColors.surfaceWhite,
          foregroundColor: AppColors.primaryMint,
          borderSide: BorderSide(color: AppColors.primaryMint),
        ),
    };
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderSide = BorderSide.none,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide borderSide;
}
