import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/legal_constants.dart';

/// Pinpoint opt-in card — visually and legally separated from general ToS.
class HealthDataConsentCard extends StatelessWidget {
  const HealthDataConsentCard({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? AppColors.neonLime.withValues(alpha: 0.45)
              : AppColors.dangerRed.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: value ? AppColors.neonLime : AppColors.dangerRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LegalConstants.healthDataConsentTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '이용약관과 별도 · 선택 동의',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            LegalConstants.healthDataConsentSummary,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            LegalConstants.ephemeralSensorPolicy,
            style: TextStyle(
              color: AppColors.electricBlue.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: value,
            onChanged: enabled ? (checked) => onChanged(checked ?? false) : null,
            title: Text(LegalConstants.healthDataConsentLabel),
            subtitle: const Text('체크해야 워치 연동·심박 검증이 활성화됩니다.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
