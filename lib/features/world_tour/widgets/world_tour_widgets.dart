import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/route_names.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../../profile/user_profile_notifier.dart';
import '../../profile/widgets/gender_profile_avatar.dart';
import '../world_tour_coordinator.dart';
import '../world_tour_format.dart';
import '../world_tour_landmarks.dart';
import '../world_tour_models.dart';
import '../world_tour_providers.dart';
import '../world_tour_run_end.dart';

/// Small reminder that the distance is a make-believe trip.
class WorldTourVirtualNote extends StatelessWidget {
  const WorldTourVirtualNote({super.key, this.color});

  static const noteKey = Key('world-tour-virtual-note');

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Text(
      RemainingSurface.tr(context, 'wt.virtual', '가상 여행 거리'),
      key: noteKey,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color ?? tokens.colors.muted,
          ),
    );
  }
}

/// The man or woman avatar the traveller picked. Falls back to the male
/// picture exactly like the home screen.
class WorldTourAvatar extends ConsumerWidget {
  const WorldTourAvatar({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gender = ref.watch(userGenderProvider);
    final tokens = context.srcTokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.colors.surface,
        border: Border.all(color: tokens.colors.accent, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          GenderAvatarAssets.pathFor(gender),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            size: size * 0.6,
            color: tokens.colors.muted,
          ),
        ),
      ),
    );
  }
}

/// One row of the mission list.
class WorldTourMissionCard extends StatelessWidget {
  const WorldTourMissionCard({
    required this.mission,
    required this.recommended,
    required this.onTap,
    super.key,
  });

  final WorldTourMission mission;
  final bool recommended;
  final VoidCallback onTap;

  static Key cardKey(String missionId) => Key('world-tour-card-$missionId');
  static const recommendedKey = Key('world-tour-recommended');
  static const doneKey = Key('world-tour-done');

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final landmark = WorldTourLandmark.of(mission.landmarkId);
    final name = landmark.name(context, fallback: mission.title);
    return SrcSurfaceCard(
      key: cardKey(mission.missionId),
      onTap: onTap,
      padding: EdgeInsets.all(tokens.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              WorldTourLandmarkArt(
                landmark: landmark,
                height: 110,
                dimmed: mission.completed,
              ),
              if (recommended && !mission.completed)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _Badge(
                    key: recommendedKey,
                    label: RemainingSurface.tr(context, 'wt.recommend', '추천'),
                    color: tokens.colors.primary,
                    textColor: tokens.colors.onPrimary,
                  ),
                ),
              if (mission.completed)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _Badge(
                    key: doneKey,
                    label: RemainingSurface.tr(context, 'wt.done', '완주'),
                    color: tokens.colors.success,
                    textColor: Colors.white,
                    icon: Icons.check_circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: tokens.spacing.xxs),
          Text(
            RemainingSurface.tr(
              context,
              'wt.goal',
              '목표 \$km km',
              {'km': formatTourKm(mission.targetKm)},
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
          ),
          SizedBox(height: tokens.spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mission.completed ? 1 : mission.fraction,
              minHeight: 8,
              color: tokens.colors.primary,
              backgroundColor: tokens.colors.outline.withValues(alpha: 0.4),
            ),
          ),
          SizedBox(height: tokens.spacing.xxs),
          Text(
            '${formatTourKm(mission.completed ? mission.targetKm : mission.progressKm)}'
            ' / ${formatTourKm(mission.targetKm)} km',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// The single trip line on the run screen: "에펠탑까지 0.35km 남음". It is a
/// display of this run only; the server's attach answer is what counts.
class WorldTourRunChip extends ConsumerWidget {
  const WorldTourRunChip({required this.args, required this.runKm, super.key});

  static const chipKey = Key('world-tour-run-chip');

  final WorldTourRunArgs args;
  final double runKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final landmark = WorldTourLandmark.of(args.landmarkId);
    final name = landmark.shortName(context);
    final mission = ref.watch(worldTourMeProvider).maybeWhen(
          data: (me) => me.mission(args.missionId),
          orElse: () => null,
        );

    final String text;
    if (mission == null) {
      // The server list has not arrived: do not guess how far along the
      // traveller already is.
      text = RemainingSurface.tr(
        context,
        'wt.run.traveling',
        '\$name 여행 중 · 이번 \$km km',
        {'name': name, 'km': formatTourKm(runKm)},
      );
    } else {
      final left = mission.remainingKm - runKm;
      text = left > 0
          ? RemainingSurface.tr(
              context,
              'wt.run.remaining',
              '\$name까지 \$km km 남음',
              {'name': name, 'km': formatTourKm(left)},
            )
          : RemainingSurface.tr(
              context,
              'wt.run.arrived',
              '\$name 도착! 러닝을 끝내고 확인하면 스탬프를 받아요',
              {'name': name},
            );
    }

    return Container(
      key: chipKey,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.colors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.colors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(landmark.icon, size: 20, color: tokens.colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const WorldTourVirtualNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The one new door on the home screen. On open it also sends any run that
/// could not be linked last time (the server ignores repeats).
class WorldTourEntryCard extends ConsumerStatefulWidget {
  const WorldTourEntryCard({super.key});

  static const cardKey = Key('world-tour-entry');

  @override
  ConsumerState<WorldTourEntryCard> createState() => _WorldTourEntryCardState();
}

class _WorldTourEntryCardState extends ConsumerState<WorldTourEntryCard> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_retryPending);
  }

  Future<void> _retryPending() async {
    try {
      final uid = ref.read(authStateChangesProvider).value?.uid;
      if (uid == null || uid.isEmpty) return;
      final outcomes =
          await ref.read(worldTourCoordinatorProvider).retryPending(uid);
      if (!mounted) return;
      if (outcomes.any((o) => o is WorldTourAttached)) {
        ref.invalidate(worldTourMeProvider);
      }
      final finished = outcomes
          .whereType<WorldTourAttached>()
          .where((o) => o.result.newlyCompleted)
          .isNotEmpty;
      if (finished) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RemainingSurface.tr(
                context,
                'wt.entry.stamp_toast',
                '여행을 마쳤어요! 여권에서 스탬프를 확인해 보세요',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      // Entry card is a door; a failed retry must never break the home page.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      key: WorldTourEntryCard.cardKey,
      onTap: () => context.push(RouteNames.worldTour),
      padding: EdgeInsets.all(tokens.spacing.md),
      borderColor: tokens.colors.accent.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.public, color: tokens.colors.accent, size: 32),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'World Tour',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  RemainingSurface.tr(
                      context, 'wt.subtitle', '오늘은 어디로 달릴까요?'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: tokens.colors.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: tokens.colors.muted),
        ],
      ),
    );
  }
}
