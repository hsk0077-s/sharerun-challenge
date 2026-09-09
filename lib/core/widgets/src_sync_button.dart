import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_text_styles.dart';

/// 건강 연동용 아웃라인 버튼 (흰 배경 + 회색 테두리).
class SRCSyncButton extends StatelessWidget {
  const SRCSyncButton({
    required this.label,
    required this.leading,
    required this.onPressed,
    super.key,
    this.connected = false,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppShapes.buttonHeight,
      child: Material(
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.inputRadius),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: AppShapes.buttonIconLeftPadding,
                child: leading,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (connected)
                const Positioned(
                  right: 16,
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.tealAccent,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Apple 건강 아이콘 (빨간 하트).
class AppleHealthIcon extends StatelessWidget {
  const AppleHealthIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.favorite_rounded,
      color: Color(0xFFFF3B30),
      size: 22,
    );
  }
}

/// Google Health Connect 아이콘 (다색 하트 근사).
class GoogleHealthConnectIcon extends StatelessWidget {
  const GoogleHealthConnectIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 20,
            color: AppColors.primaryMint.withValues(alpha: 0.85),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.favorite_rounded,
              size: 11,
              color: AppColors.naverGreen.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
