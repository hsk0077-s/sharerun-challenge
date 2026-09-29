import 'package:flutter/material.dart';

import '../strings/app_strings.dart';
import '../theme/app_shapes.dart';
import '../theme/app_text_styles.dart';

/// 로그인 상단 — 스플래시·로비와 같은 `sharerun_logo.png` + 타이틀/서브타이틀.
class SRCLogoHeader extends StatelessWidget {
  const SRCLogoHeader({super.key});

  /// 로비 헤더·스플래시와 동일한 네온 러너 마크.
  static const assetPath = 'assets/images/sharerun_logo.png';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = screenWidth * AppShapes.loginLogoWidthFactor;

    return Padding(
      padding: const EdgeInsets.only(top: AppShapes.loginHeaderTopPadding),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'ShareRun',
              errorBuilder: (_, __, ___) => Icon(
                Icons.favorite,
                size: logoSize * 0.45,
                color: const Color(0xFF76C8A7),
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
