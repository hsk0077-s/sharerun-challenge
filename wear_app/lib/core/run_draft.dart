import 'dart:convert';

import 'sync_queue.dart';
import 'watch_platform.dart';

/// 달리는 중에 몇 초마다 저장해 두는 임시 기록.
///
/// 시계 앱이 달리는 도중 죽거나 화면이 꺼져도, 다시 켰을 때
/// 여기까지의 거리·시간·경로로 달리기를 이어 간다. 정상 종료하면 지운다.
class RunDraft {
  const RunDraft({
    required this.activityId,
    required this.startedAt,
    required this.savedAt,
    required this.movingSeconds,
    required this.distanceKm,
    this.steps = 0,
    this.heartRates = const [],
    this.route = const [],
    this.paceSamples = const [],
  });

  final String activityId;
  final DateTime startedAt;

  /// 마지막으로 저장한 시각. 되살린 기록의 끝 시각으로 쓴다.
  final DateTime savedAt;
  final int movingSeconds;
  final double distanceKm;
  final int steps;
  final List<int> heartRates;
  final List<GpsFix> route;
  final List<Map<String, Object>> paceSamples;

  Map<String, Object?> toJson() => {
        'activityId': activityId,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'savedAt': savedAt.toUtc().toIso8601String(),
        'movingSeconds': movingSeconds,
        'distanceKm': distanceKm,
        'steps': steps,
        'heartRates': heartRates,
        'route': [for (final fix in route) fix.toJson()],
        'paceSamples': paceSamples,
      };

  String encode() => jsonEncode(toJson());

  /// 깨졌거나 모르는 모양이면 null.
  static RunDraft? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, Object?>();
      final queueRun = PendingRun.fromJson({
        'activityId': map['activityId'],
        'distanceKm': map['distanceKm'],
        'durationSeconds': map['movingSeconds'],
        'heartRates': map['heartRates'] ?? const [],
        'startedAt': map['startedAt'],
        'endedAt': map['savedAt'],
        'totalSteps': map['steps'] ?? 0,
        'gpsRoute': map['route'] ?? const [],
        'paceSamples': map['paceSamples'] ?? const [],
      });
      return RunDraft(
        activityId: queueRun.activityId,
        startedAt: queueRun.startedAt,
        savedAt: queueRun.endedAt,
        movingSeconds: queueRun.durationSeconds,
        distanceKm: queueRun.distanceKm,
        steps: queueRun.totalSteps,
        heartRates: queueRun.heartRates,
        route: queueRun.gpsRoute,
        paceSamples: queueRun.paceSamples,
      );
    } catch (_) {
      return null;
    }
  }

  /// 올릴 기록으로 바꾼다. 거리·시간이 없으면 null(올릴 게 없다).
  PendingRun? toPendingRun() => buildPendingRun(
        activityId: activityId,
        distanceKm: distanceKm,
        movingTime: Duration(seconds: movingSeconds),
        heartRates: heartRates,
        startedAt: startedAt,
        endedAt: savedAt.isAfter(startedAt) ? savedAt : startedAt.add(Duration(seconds: movingSeconds)),
        totalSteps: steps,
        gpsRoute: route,
        paceSamples: paceSamples,
      );
}
