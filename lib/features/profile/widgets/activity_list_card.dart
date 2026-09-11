import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/route_names.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/theme/theme.dart';
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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    return SrcSurfaceCard(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md,
        14,
        tokens.spacing.md,
        tokens.spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '러닝 로그',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: tokens.colors.ink,
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          if (activities.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spacing.xxs + 2),
              child: Text(
                '최근 러닝 기록이 없습니다',
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.colors.muted,
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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sm),
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
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: tokens.colors.muted,
                      ),
                    ),
                    if (pace != null) ...[
                      SizedBox(height: tokens.spacing.xxs / 2),
                      Text(
                        pace,
                        style: textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${activity.distanceKm.toStringAsFixed(1)} km',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: tokens.colors.accent,
                ),
              ),
            ],
          ),
          if (pending) ...[
            SizedBox(height: tokens.spacing.xs),
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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: tokens.colors.warning.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(tokens.radii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radii.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.xs,
            vertical: 5,
          ),
          child: Text(
            '⚠️ 기록 보류 - 소명하기 〉',
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tokens.colors.warning,
            ),
          ),
        ),
      ),
    );
  }
}
