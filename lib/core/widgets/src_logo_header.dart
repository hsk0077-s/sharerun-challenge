import 'package:flutter/material.dart';

import '../strings/app_strings.dart';
import '../theme/app_shapes.dart';
import '../theme/app_text_styles.dart';

/// 로그인 목업 상단 — 저장된 `src_logo.jpeg`(SRC+하트) + 타이틀/서브타이틀.
/// 좌우 흰 여백·하단 ShareRunChallenge 영문은 크롭으로 제외합니다.
class SRCLogoHeader extends StatelessWidget {
  const SRCLogoHeader({super.key});

  static const assetPath = 'assets/images/src_logo.jpeg';

  /// 원본 1024×559 — 잉크 영역(~50%)만 보이도록 좌우 여백 제거.
  static const double _widthCropFactor = 0.52;

  /// 상단 SRC+하트만 노출 (하단 영문 로고 텍스트 제외).
  static const double _visibleHeightFactor = 0.62;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final visibleWidth = screenWidth * AppShapes.loginLogoWidthFactor;
    final imageWidth = visibleWidth / _widthCropFactor;

    return Padding(
      padding: const EdgeInsets.only(top: AppShapes.loginHeaderTopPadding),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                widthFactor: _widthCropFactor,
                heightFactor: _visibleHeightFactor,
                child: Image.asset(
                  assetPath,
                  width: imageWidth,
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'SRC logo',
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.favorite,
                    size: visibleWidth * 0.45,
                    color: const Color(0xFF76C8A7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppShapes.loginLogoToTitleGap),
            const Text(
              AppStrings.loginTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.header1,
            ),
            const SizedBox(height: AppShapes.loginTitleToSubtitleGap),
            const Text(
              AppStrings.loginSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle1,
            ),
          ],
        ),
      ),
    );
  }
}
