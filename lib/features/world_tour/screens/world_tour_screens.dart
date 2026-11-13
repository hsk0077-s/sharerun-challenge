import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/route_names.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../../run_tracking/utils/run_start_preflight.dart';
import '../widgets/world_tour_widgets.dart';
import '../world_tour_format.dart';
import '../world_tour_landmarks.dart';
import '../world_tour_models.dart';
import '../world_tour_providers.dart';
import '../world_tour_run_end.dart';

/// Shown when the server list cannot be read. No made-up numbers.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RemainingSurface.tr(
                  context, 'wt.load_failed', '여행 정보를 불러오지 못했어요.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('world-tour-retry'),
              onPressed: onRetry,
              child:
                  Text(RemainingSurface.tr(context, 'wt.retry', '다시 시도')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mission list. A first-time traveller is pointed at the first mission.
class WorldTourListScreen extends ConsumerWidget {
  const WorldTourListScreen({super.key});

  static const passportKey = Key('world-tour-passport-button');
  static const listKey = Key('world-tour-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final me = ref.watch(worldTourMeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Tour'),
        actions: [
          IconButton(
            key: passportKey,
            tooltip: RemainingSurface.tr(context, 'wt.passport.title', '여권'),
            icon: const Icon(Icons.book_outlined),
            onPressed: () => context.push(RouteNames.worldTourPassport),
          ),
        ],
      ),
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            _LoadFailed(onRetry: () => ref.invalidate(worldTourMeProvider)),
        data: (data) {
          final recommendedId =
              data.hasAnyProgress ? null : data.recommended?.missionId;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(worldTourMeProvider);
              await ref.read(worldTourMeProvider.future);
            },
            child: ListView(
              key: listKey,
              padding: EdgeInsets.all(tokens.spacing.page),
              children: [
                Text(
                  RemainingSurface.tr(
                      context, 'wt.subtitle', '오늘은 어디로 달릴까요?'),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: tokens.spacing.xxs),
                const WorldTourVirtualNote(),
                SizedBox(height: tokens.spacing.md),
                for (final mission in data.missions) ...[
                  WorldTourMissionCard(
                    mission: mission,
                    recommended: mission.missionId == recommendedId,
                    onTap: () => context
                        .push(RouteNames.worldTourMission(mission.missionId)),
                  ),
                  SizedBox(height: tokens.spacing.sm),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One mission: a short story and the start button. The button opens the
/// ordinary GPS run screen and only hands it the chosen mission.
class WorldTourDetailScreen extends ConsumerWidget {
  const WorldTourDetailScreen({required this.missionId, super.key});

  final String missionId;

  static const startKey = Key('world-tour-start');
  static const doneNoteKey = Key('world-tour-done-note');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final me = ref.watch(worldTourMeProvider);
    // Watched so the profile (health consent) is already loaded when the
    // start button is pressed.
    final profile = ref.watch(activeUserProfileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('World Tour')),
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            _LoadFailed(onRetry: () => ref.invalidate(worldTourMeProvider)),
        data: (data) {
          final mission = data.mission(missionId);
          if (mission == null) {
            return _LoadFailed(
              onRetry: () => ref.invalidate(worldTourMeProvider),
            );
          }
          final landmark = WorldTourLandmark.of(mission.landmarkId);
          final story = landmark.story(context);
          final headings = [
            RemainingSurface.tr(context, 'wt.story.start', '출발'),
            RemainingSurface.tr(context, 'wt.story.mid', '중간'),
            RemainingSurface.tr(context, 'wt.story.arrive', '도착'),
          ];
          return Column(
            children: [
              Expanded(
                child: ListView(
            padding: EdgeInsets.all(tokens.spacing.page),
            children: [
              WorldTourLandmarkArt(
                landmark: landmark,
                height: 180,
                dimmed: mission.completed,
              ),
              SizedBox(height: tokens.spacing.sm),
              Text(
                landmark.name(context, fallback: mission.title),
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: tokens.spacing.xxs),
              Text(
                RemainingSurface.tr(
                  context,
                  'wt.goal',
                  '목표 \$km km',
                  {'km': formatTourKm(mission.targetKm)},
                ),
                style: textTheme.bodyMedium?.copyWith(color: tokens.colors.muted),
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
                style: textTheme.labelMedium,
              ),
              SizedBox(height: tokens.spacing.xxs),
              const WorldTourVirtualNote(),
              SizedBox(height: tokens.spacing.md),
              for (var i = 0; i < story.length && i < headings.length; i++) ...[
                Text(
                  headings[i],
                  style: textTheme.labelLarge?.copyWith(
                    color: tokens.colors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs),
                Text(story[i], style: textTheme.bodyLarge),
                SizedBox(height: tokens.spacing.sm),
              ],
              if (mission.completed)
                Text(
                  RemainingSurface.tr(
                    context,
                    'wt.detail.done_note',
                    '이미 도착한 여행이에요. 다른 곳으로 떠나 볼까요?',
                  ),
                  key: doneNoteKey,
                  style: textTheme.bodyMedium,
                ),
            ],
                ),
              ),
              // Pinned, so the start button is always in reach.
              if (!mission.completed)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spacing.page,
                      tokens.spacing.xs,
                      tokens.spacing.page,
                      tokens.spacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: startKey,
                        onPressed: () => startRunWithPreflight(
                          context: context,
                          profile: profile,
                          extra: WorldTourRunArgs(
                            missionId: mission.missionId,
                            landmarkId: mission.landmarkId,
                          ),
                        ),
                        child: Text(
                          RemainingSurface.tr(
                              context, 'wt.detail.start', '여행 출발하기'),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Passport: one slot per mission. Stamps come from the server list only.
class WorldTourPassportScreen extends ConsumerWidget {
  const WorldTourPassportScreen({super.key});

  static const countKey = Key('world-tour-passport-count');
  static Key slotKey(String missionId) => Key('world-tour-slot-$missionId');
  static Key stampedKey(String missionId) => Key('world-tour-stamped-$missionId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final me = ref.watch(worldTourMeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(RemainingSurface.tr(context, 'wt.passport.title', '여권')),
      ),
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            _LoadFailed(onRetry: () => ref.invalidate(worldTourMeProvider)),
        data: (data) {
          return ListView(
            padding: EdgeInsets.all(tokens.spacing.page),
            children: [
              Text(
                RemainingSurface.tr(
                  context,
                  'wt.passport.count',
                  '\$done/\$total개국',
                  {'done': data.completedCount, 'total': data.totalCount},
                ),
                key: countKey,
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: tokens.spacing.xxs),
              if (data.completedCount == 0)
                Text(
                  RemainingSurface.tr(
                    context,
                    'wt.passport.hint',
                    '여행을 마치면 스탬프가 찍혀요',
                  ),
                  style:
                      textTheme.bodyMedium?.copyWith(color: tokens.colors.muted),
                ),
              const WorldTourVirtualNote(),
              SizedBox(height: tokens.spacing.md),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: tokens.spacing.sm,
                crossAxisSpacing: tokens.spacing.sm,
                childAspectRatio: 0.82,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final mission in data.missions)
                    _StampSlot(mission: mission),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StampSlot extends StatelessWidget {
  const _StampSlot({required this.mission});

  final WorldTourMission mission;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final landmark = WorldTourLandmark.of(mission.landmarkId);
    final stamped = mission.completed;
    return SrcSurfaceCard(
      key: WorldTourPassportScreen.slotKey(mission.missionId),
      padding: EdgeInsets.all(tokens.spacing.sm),
      borderColor: stamped
          ? tokens.colors.success.withValues(alpha: 0.6)
          : tokens.colors.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                WorldTourLandmarkArt(
                  landmark: landmark,
                  height: double.infinity,
                  dimmed: !stamped,
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: stamped
                      ? Icon(
                          Icons.verified,
                          key: WorldTourPassportScreen.stampedKey(
                              mission.missionId),
                          color: Colors.white,
                          size: 30,
                        )
                      : const Icon(Icons.lock_outline,
                          color: Colors.white70, size: 24),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            landmark.name(context, fallback: mission.title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
