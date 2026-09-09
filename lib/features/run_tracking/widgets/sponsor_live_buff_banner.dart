import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/sponsor_live_buff_model.dart';

class SponsorLiveBuffBanner extends StatelessWidget {
  const SponsorLiveBuffBanner({
    required this.buff,
    super.key,
  });

  final SponsorLiveBuffModel buff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricBlue.withValues(alpha: 0.25),
            AppColors.neonLime.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonLime.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: AppColors.neonLime, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '스폰서 라이브 버프',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.neonLime,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  buff.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
