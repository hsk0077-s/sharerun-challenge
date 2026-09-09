import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// SRC 로그인·온보딩 등에서 사용하는 상단 민트 → 하단 화이트 그라데이션 배경.
class SRCGradientBackground extends StatelessWidget {
  const SRCGradientBackground({
    required this.child,
    super.key,
    this.gradient = AppColors.loginBackgroundGradient,
  });

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
