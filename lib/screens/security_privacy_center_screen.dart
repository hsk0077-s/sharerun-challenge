import 'package:flutter/material.dart';

import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'appeal_center_screen.dart';
import 'fair_earning_policy_screen.dart';

/// 보안·프라이버시 센터. 지금은 정책 안내와 기록 소명으로 가는 입구다.
/// 새 기능은 하위 PR에서 한 줄씩 늘린다.
class SecurityPrivacyCenterScreen extends StatelessWidget {
  const SecurityPrivacyCenterScreen({super.key});

  static const policyTileKey = Key('security-center-fair-earning');
  static const appealTileKey = Key('security-center-appeal');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '보안·프라이버시 센터',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '적립 규칙과 기록 이의 신청을 한곳에서 확인해요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          Material(
            color: AppColors.surfaceWhite,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: AppColors.tealAccent.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                _CenterTile(
                  tileKey: policyTileKey,
                  icon: Icons.verified_outlined,
                  title: '공정한 적립 정책',
                  subtitle: '검증 기준 · 하루 한도 · 기부 규칙',
                  onTap: () => AppRouteNav.push<void>(
                    context,
                    RouteNames.fairEarningPolicy,
                    materialBuilder: (_) => const FairEarningPolicyScreen(),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _CenterTile(
                  tileKey: appealTileKey,
                  icon: Icons.support_agent_outlined,
                  title: '기록 소명 및 고객센터',
                  subtitle: '검증 결과에 이의가 있을 때',
                  onTap: () => AppRouteNav.push<void>(
                    context,
                    RouteNames.appeal,
                    materialBuilder: (_) => const AppealCenterScreen(),
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

class _CenterTile extends StatelessWidget {
  const _CenterTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      leading: Icon(icon, color: AppColors.tealAccent),
      title: Text(
        title,
        style: AppTextStyles.agreementLabel.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textGreyLight,
      ),
      onTap: onTap,
    );
  }
}
