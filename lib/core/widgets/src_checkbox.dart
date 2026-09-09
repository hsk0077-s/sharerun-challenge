import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// SRC 디자인 시스템 민트 체크박스.
class SRCCheckbox extends StatelessWidget {
  const SRCCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
    this.size = 24,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? AppColors.primaryMint : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: AppColors.primaryMint,
            width: value ? 0 : 1.5,
          ),
        ),
        child: value
            ? Icon(
                Icons.check_rounded,
                size: size * 0.72,
                color: AppColors.textWhite,
              )
            : null,
      ),
    );
  }
}
