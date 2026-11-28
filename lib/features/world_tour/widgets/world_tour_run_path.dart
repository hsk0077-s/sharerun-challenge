import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../world_tour_landmarks.dart';
import '../world_tour_models.dart';
import '../world_tour_run_progress.dart';

/// A straight left-to-right trip for the run that is in progress.
///
/// The left end is the start (0%). The right end is the landmark (100%).
/// The character moves only when [runKm] changes, with one short slide.
/// There is no loop and no parallax. The country picture, when one exists,
/// is a single still image under a dark gradient.
class WorldTourRunPath extends StatelessWidget {
  const WorldTourRunPath({
    required this.mission,
    required this.runKm,
    this.runnerAsset,
    super.key,
  });

  final WorldTourMission? mission;
  final double runKm;

  /// Tier animal picture. Null draws the existing runner icon.
  final String? runnerAsset;

  static const pathKey = Key('world-tour-run-path');
  static const backdropKey = Key('world-tour-run-backdrop');
  static const runnerKey = Key('world-tour-run-runner');
  static const landmarkKey = Key('world-tour-run-landmark');
  static const arrivedKey = Key('world-tour-run-arrived');

  static const _move = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final mission = this.mission;
    if (!WorldTourRunProgress.canDraw(mission)) {
      return const SizedBox.shrink();
    }
    final drawn = mission!;
    final landmark = WorldTourLandmark.of(drawn.landmarkId);
    final endAsset = landmark.artAsset(WorldTourArtScene.poster) ??
        landmark.artAsset(WorldTourArtScene.close);
    if (endAsset == null) return const SizedBox.shrink();

    final fraction = WorldTourRunProgress.fraction(
      mission: drawn,
      runKm: runKm,
    );
    final arrived = WorldTourRunProgress.arrived(
      mission: drawn,
      runKm: runKm,
    );
    final backdrop = WorldTourRunProgress.backdropAsset(drawn.landmarkId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 120.0;
        if (width <= 0 || height <= 0) return const SizedBox.shrink();

        const edge = 6.0;
        var landmarkSide = math.min(84.0, height * 0.92);
        var runnerSide = math.min(52.0, height * 0.62);
        final budget = math.max(0.0, width - edge);
        if (landmarkSide + runnerSide > budget &&
            landmarkSide + runnerSide > 0) {
          final scale = budget / (landmarkSide + runnerSide);
          landmarkSide *= scale;
          runnerSide *= scale;
        }
        final span = math.max(0.0, width - edge - landmarkSide - runnerSide);
        final left = fraction * span;
        final roadRight = edge + landmarkSide;
        final roadWidth = math.max(0.0, width - edge - roadRight);
        final fillWidth = math.max(
          0.0,
          math.min(left + runnerSide * 0.45 - edge, roadWidth),
        );
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheW = math.max(1, math.min(640, (width * dpr).round()));
        final landmarkCache = math.max(1, (landmarkSide * dpr).round());

        return ClipRRect(
          key: pathKey,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.nightCard),
                if (backdrop != null)
                  _StillBackdrop(
                    asset: backdrop,
                    cacheWidth: cacheW,
                  ),
                if (backdrop != null) const _DarkMask(),
                if (roadWidth > 1)
                  Positioned(
                    left: edge,
                    width: roadWidth,
                    top: height / 2 - 3,
                    height: 6,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.nightLine,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: _move,
                  curve: Curves.easeOutCubic,
                  left: edge,
                  width: fillWidth,
                  top: height / 2 - 3,
                  height: 6,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.nightLime,
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ),
                Positioned(
                  key: landmarkKey,
                  right: edge,
                  top: (height - landmarkSide) / 2,
                  width: landmarkSide,
                  height: landmarkSide,
                  child: _LandmarkMark(
                    asset: endAsset,
                    cacheWidth: landmarkCache,
                    arrived: arrived,
                    showLabel: landmarkSide >= 36,
                  ),
                ),
                AnimatedPositioned(
                  duration: _move,
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: (height - runnerSide) / 2,
                  width: runnerSide,
                  height: runnerSide,
                  child: _Runner(asset: runnerAsset),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One decoded frame. [Opacity] is a still value, not a ticker.
class _StillBackdrop extends StatelessWidget {
  const _StillBackdrop({required this.asset, required this.cacheWidth});

  final String asset;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset(
        asset,
        key: WorldTourRunPath.backdropKey,
        fit: BoxFit.cover,
        alignment: Alignment.centerRight,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: cacheWidth,
        opacity: const AlwaysStoppedAnimation(0.35),
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Darkens the picture so the road and the character stay readable.
/// The left is fainter. The landmark side stays a little clearer.
class _DarkMask extends StatelessWidget {
  const _DarkMask();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xE6070B09),
            Color(0x8C070B09),
          ],
        ),
      ),
    );
  }
}

class _LandmarkMark extends StatelessWidget {
  const _LandmarkMark({
    required this.asset,
    required this.cacheWidth,
    required this.arrived,
    required this.showLabel,
  });

  final String asset;
  final int cacheWidth;
  final bool arrived;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              cacheWidth: cacheWidth,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppColors.nightLine,
              ),
            ),
          ),
        ),
        if (arrived && !showLabel)
          const Positioned(
            key: WorldTourRunPath.arrivedKey,
            left: 0,
            right: 0,
            bottom: 0,
            height: 4,
            child: ColoredBox(color: AppColors.nightLime),
          ),
        if (arrived && showLabel)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              key: WorldTourRunPath.arrivedKey,
              decoration: const BoxDecoration(
                color: AppColors.nightLime,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  RemainingSurface.tr(
                    context,
                    'run_tracking.tour.arrived',
                    '도착',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.nightOnLime,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Runner extends StatelessWidget {
  const _Runner({required this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    final path = asset;
    return DecoratedBox(
      key: WorldTourRunPath.runnerKey,
      decoration: BoxDecoration(
        color: AppColors.nightBg.withValues(alpha: 0.72),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.nightLime, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: path == null
            ? const FittedBox(
                child: Icon(
                  Icons.directions_run_rounded,
                  color: AppColors.nightLime,
                ),
              )
            : Image.asset(
                path,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => const FittedBox(
                  child: Icon(
                    Icons.directions_run_rounded,
                    color: AppColors.nightLime,
                  ),
                ),
              ),
      ),
    );
  }
}
