import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';

/// SRC 브랜드 로고 이미지.
class SRCLogo extends StatelessWidget {
  const SRCLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  /// 로그인 목업 상단 — SRC + 하트 (투명 배경 PNG, 원본 비율 유지).
  const SRCLogo.loginHeader({
    super.key,
    required double screenWidth,
  })  : width = screenWidth * AppShapes.loginLogoWidthFactor,
        height = null,
        fit = BoxFit.fitWidth;

  /// 전체 로고 (SRC + 하트 + ShareRunChallenge).
  static const fullAssetPath = 'assets/images/src_logo.jpeg';

  /// 로그인 헤더용 마크 (SRC + 하트, 투명 배경).
  static const markAssetPath = 'assets/images/src_logo_mark.png';

  final double? width;
  final double? height;
  final BoxFit fit;

  bool get _isLoginHeader => height == null && fit == BoxFit.fitWidth;

  @override
  Widget build(BuildContext context) {
    final path = _isLoginHeader ? markAssetPath : fullAssetPath;

    if (_isLoginHeader && width != null) {
      // 너비만 고정 → 높이는 에셋 비율(368:1024)에 따라 자동 산출.
      return SizedBox(
        width: width,
        child: Image.asset(
          path,
          width: width,
          fit: BoxFit.fitWidth,
          filterQuality: FilterQuality.high,
          semanticLabel: 'SRC logo',
          errorBuilder: _errorBuilder,
        ),
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: 'SRC logo',
      errorBuilder: _errorBuilder,
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final fallbackHeight = width != null
        ? width! * AppShapes.loginLogoMarkAspectRatio
        : height;
    return SizedBox(
      width: width,
      height: fallbackHeight,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.primaryMint,
      ),
    );
  }
}
