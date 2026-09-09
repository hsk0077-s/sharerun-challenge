import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_text_styles.dart';
import 'src_checkbox.dart';

/// [전체 동의] / [선택] 항목용 민트 배경 박스.
class SRCAgreementBox extends StatelessWidget {
  const SRCAgreementBox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.checkboxOnRight = false,
    this.trailing,
    this.labelStyle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool checkboxOnRight;
  final Widget? trailing;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final checkbox = SRCCheckbox(value: value, onChanged: onChanged);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.agreementBoxFill,
        borderRadius: BorderRadius.circular(AppShapes.agreementBoxRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!checkboxOnRight) ...[
            checkbox,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? AppTextStyles.agreementAllLabel,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (checkboxOnRight) ...[
            const SizedBox(width: 12),
            checkbox,
          ],
        ],
      ),
    );
  }
}

/// [필수] 개별 약관 행 — 체크박스 좌측.
class SRCAgreementRow extends StatelessWidget {
  const SRCAgreementRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SRCCheckbox(value: value, onChanged: onChanged),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: AppTextStyles.agreementLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 심박수 아이콘 (선택 약관 우측).
class HealthPulseIcon extends StatelessWidget {
  const HealthPulseIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceWhite.withValues(alpha: 0.85),
      ),
      child: Icon(
        Icons.monitor_heart_outlined,
        size: 20,
        color: AppColors.textGrey.withValues(alpha: 0.7),
      ),
    );
  }
}
