import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../l10n/remaining_surface.dart';
import 'world_tour_coordinator.dart';
import 'world_tour_format.dart';
import 'world_tour_landmarks.dart';
import 'world_tour_providers.dart';

/// The mission a run was started for. Only the id travels with the run; the
/// landmark id lets the run screen name it before the server list arrives.
class WorldTourRunArgs {
  const WorldTourRunArgs({required this.missionId, required this.landmarkId});

  final String missionId;
  final String landmarkId;
}

/// What the arrival screen shows.
class WorldTourArrivalArgs {
  const WorldTourArrivalArgs({
    required this.missionId,
    required this.landmarkId,
    required this.distanceKm,
    required this.durationSeconds,
    this.stampId,
  });

  final String missionId;
  final String landmarkId;
  final double distanceKm;
  final int durationSeconds;
  final String? stampId;
}

/// The end of one World Tour run: link it, then tell the runner.
class WorldTourRunEnd {
  const WorldTourRunEnd({
    required this.args,
    required this.outcome,
    required this.distanceKm,
    required this.durationSeconds,
  });

  final WorldTourRunArgs args;
  final WorldTourOutcome outcome;
  final double distanceKm;
  final int durationSeconds;

  /// Called after the run was validated. A rejected run is not sent to the
  /// server at all: it would only be refused. A run whose verdict is still
  /// pending is sent, and kept for a retry if the server is not done yet.
  static Future<WorldTourRunEnd> settle({
    required WidgetRef ref,
    required WorldTourRunArgs args,
    required String uid,
    required String activityId,
    required bool verified,
    required bool pending,
    required double distanceKm,
    required int durationSeconds,
  }) async {
    final WorldTourOutcome outcome;
    if (!verified && !pending) {
      outcome = const WorldTourNotCounted('run_not_verified');
    } else {
      outcome = await ref.read(worldTourCoordinatorProvider).attachAfterRun(
            uid: uid,
            missionId: args.missionId,
            activityId: activityId,
          );
      if (outcome is WorldTourAttached) {
        ref.invalidate(worldTourMeProvider);
      }
    }
    return WorldTourRunEnd(
      args: args,
      outcome: outcome,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
    );
  }

  /// Show the result. Navigator and messenger are taken before the run screen
  /// is replaced, so this is safe to call right after the navigation.
  void announce({
    required GoRouter router,
    required ScaffoldMessengerState messenger,
  }) {
    final landmark = WorldTourLandmark.of(args.landmarkId);
    final name = landmark.shortName(null);
    final o = outcome;
    switch (o) {
      case WorldTourAttached(:final result):
        if (result.newlyCompleted) {
          router.push(
            RouteNames.worldTourArrival,
            extra: WorldTourArrivalArgs(
              missionId: args.missionId,
              landmarkId: args.landmarkId,
              distanceKm: distanceKm,
              durationSeconds: durationSeconds,
              stampId: result.stampId,
            ),
          );
        } else if (!result.completed) {
          _snack(
            messenger,
            RemainingSurface.trNow(
              'wt.run.left_toast',
              '\$name까지 \$km km 남았어요',
              {'name': name, 'km': formatTourKm(result.remainingKm)},
            ),
          );
        }
      case WorldTourNotCounted():
        _snack(
          messenger,
          RemainingSurface.trNow(
            'wt.not_counted',
            '이번 기록은 여행 거리에 반영되지 않았어요',
          ),
        );
      case WorldTourRetryLater():
        _snack(
          messenger,
          RemainingSurface.trNow(
            'wt.retry_later',
            '여행 거리는 잠시 후 다시 반영할게요',
          ),
        );
    }
  }

  static void _snack(ScaffoldMessengerState messenger, String text) {
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }
}
