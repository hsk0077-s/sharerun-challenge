import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/route_names.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/activity_model.dart';
import '../../../screens/appeal_center_screen.dart';

void openAppealCenter(
  BuildContext context, {
  required String activityId,
}) {
  final extra = <String, String>{'activityId': activityId};
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    try {
      context.pushNamed(RouteNames.appealCenter, extra: extra);
      return;
    } catch (_) {
      context.push(RouteNames.appeal, extra: extra);
      return;
    }
  }
  AppRouteNav.push<void>(
    context,
    RouteNames.appeal,
    extra: extra,
    materialBuilder: (_) => AppealCenterScreen(activityId: activityId),
  );
}

/// 마이페이지 캘린더 하단 러닝 로그. Jena Pending만 소명 배지를 붙인다.
class ActivityListCard extends ConsumerWidget {
  const ActivityListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(recentActivitiesProvider).value ?? const [];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '러닝 로그',
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '최근 러닝 기록이 없습니다',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            )
          else
            ...activities.take(8).map(
                  (activity) => _ActivityLogTile(activity: activity),
                ),
        ],
      ),
    );
  }
}

class _ActivityLogTile extends StatelessWidget {
  const _ActivityLogTile({required this.activity});

  final ActivityModel activity;

  @override
  Widget build(BuildContext context) {
    final pending = activity.needsJenaAppeal;
    final date = _dateLabel(activity.completedAt);
    final pace = activity.formattedPace;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date.isEmpty ? '기록' : date,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    if (pace != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        pace,
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${activity.distanceKm.toStringAsFixed(1)} km',
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _JenaHoldBadge(
                onTap: () => openAppealCenter(
                  context,
                  activityId: activity.id,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _dateLabel(DateTime? at) {
    if (at == null) return '';
    final m = at.month.toString().padLeft(2, '0');
    final d = at.day.toString().padLeft(2, '0');
    return '${at.year}.$m.$d';
  }
}

class _JenaHoldBadge extends StatelessWidget {
  const _JenaHoldBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningFill,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            '⚠️ 기록 보류 - 소명하기 〉',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warningOrange,
            ),
          ),
        ),
      ),
    );
  }
}
