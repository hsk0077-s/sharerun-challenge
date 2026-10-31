import 'dart:convert';

import 'watch_platform.dart';

/// 워치에는 자이로 안정도 점수가 없다. 서버 필수 필드를 채우는 임시 값이며,
/// 서버가 "워치 단독 기록"을 별도로 다루게 되면(README "서버 쪽 남은 일") 없앤다.
/// 케이던스는 보내지 않는다. 서버가 `watch_used`와 `total_steps`로 평균을 계산한다.
const kUnknownGyroScore = 0.5;

/// 워치가 만든 기록을 서버에 올리기 전까지 담아 두는 대기열.
///
/// 서버가 같은 `activity_id`를 한 번만 인정하므로(재전송해도 중복 지급 없음),
/// 워치는 기록마다 한 번 만든 id를 끝까지 바꾸지 않는다.
/// 워치는 6자리 코드로 계정에 연결한 뒤(`WatchAccount`) 직접 올린다. 올리지 못한
/// 기록은 이 대기열에 남아 다음 기회에 다시 올라간다.
class PendingRun {
  PendingRun({
    required this.activityId,
    required this.distanceKm,
    required this.durationSeconds,
    required this.heartRates,
    required this.startedAt,
    required this.endedAt,
    this.totalSteps = 0,
    this.gpsRoute = const [],
    this.paceSamples = const [],
  });

  final String activityId;
  final double distanceKm;
  final int durationSeconds;
  final List<int> heartRates;
  final DateTime startedAt;
  final DateTime endedAt;

  /// 센서가 센 걸음 수. 0이면 못 쟀다는 뜻이라 보내지 않는다.
  final int totalSteps;
  final List<GpsFix> gpsRoute;
  final List<Map<String, Object>> paceSamples;

  /// 서버 `POST /actions/runs/validate` 본문과 같은 필드 이름.
  /// 측정된 GPS와 50m마다의 페이스가 있으면 그대로 올린다.
  Map<String, Object?> toValidateRunBody({String? deviceId}) => {
        'activity_id': activityId,
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
        'heart_rates': heartRates,
        'cadence_spm': const <int>[],
        'gyro_stability_score': kUnknownGyroScore,
        'gps_route': [for (final fix in gpsRoute) fix.toJson()],
        // PaceSamplePayload rejects secondsPerKm above 7200, and a 422
        // removes the run from this queue. Clamp instead of dropping it.
        'pace_samples': [
          for (final sample in paceSamples)
            {
              'secondsPerKm': _paceSeconds(sample['secondsPerKm']),
              'recordedAt': sample['recordedAt'],
            },
        ],
        // 서버는 워치 기록의 시작·끝 시각이 있어야 받는다(미래·너무 오래된 시각은 거부).
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        if (totalSteps > 0) 'total_steps': totalSteps,
        if (deviceId != null) 'device_id': deviceId,
        'device_info': {'watch_used': true, 'heart_rate_used': heartRates.isNotEmpty},
      };

  Map<String, Object?> toJson() => {
        'activityId': activityId,
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
        'heartRates': heartRates,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
        'totalSteps': totalSteps,
        'gpsRoute': [for (final fix in gpsRoute) fix.toJson()],
        'paceSamples': paceSamples,
      };

  factory PendingRun.fromJson(Map<String, Object?> json) => PendingRun(
        activityId: json['activityId']! as String,
        distanceKm: (json['distanceKm']! as num).toDouble(),
        durationSeconds: (json['durationSeconds']! as num).toInt(),
        heartRates: [for (final v in json['heartRates']! as List) (v as num).toInt()],
        startedAt: DateTime.parse(json['startedAt']! as String),
        endedAt: DateTime.parse(json['endedAt']! as String),
        totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
        gpsRoute: _fixes(json['gpsRoute']),
        paceSamples: _paces(json['paceSamples']),
      );

  static List<GpsFix> _fixes(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          GpsFix(
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
            recordedAt: item['recordedAt'] as String,
          ),
    ];
  }

  static int _paceSeconds(Object? raw) {
    final value = raw is num ? raw.toInt() : 0;
    if (value < 0) return 0;
    if (value > 7200) return 7200;
    return value;
  }

  static List<Map<String, Object>> _paces(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          {
            'secondsPerKm': (item['secondsPerKm'] as num).toInt(),
            'recordedAt': item['recordedAt'] as String,
          },
    ];
  }
}

/// 하루 걸음 수 한 건. 서버 `POST /actions/daily-steps` 본문과 같은 필드 이름.
class PendingSteps {
  const PendingSteps({required this.dayKey, required this.steps});

  final String dayKey;
  final int steps;

  Map<String, Object?> toBody() =>
      {'day_key': dayKey, 'steps': steps, 'source': 'sensor'};
}

/// 기록을 id로 한 번만 담고, 최대 개수를 넘으면 가장 오래된 것부터 뺀다.
class SyncQueue {
  SyncQueue({this.maxRuns = 50});

  final int maxRuns;
  final _runs = <PendingRun>[];
  var _flushing = false;

  List<PendingRun> get runs => List.unmodifiable(_runs);
  int get length => _runs.length;

  /// 같은 대기열을 두 번 동시에 올리지 못하게 잠근다.
  /// 앱이 업로드를 겹치면 같은 `activity_id`가 두 번 나간다.
  bool tryBeginFlush() {
    if (_flushing) return false;
    _flushing = true;
    return true;
  }

  void endFlush() {
    _flushing = false;
  }

  /// 새로 담았으면 true, 같은 id가 이미 있으면 false.
  bool add(PendingRun run) {
    if (_runs.any((r) => r.activityId == run.activityId)) return false;
    _runs.add(run);
    while (_runs.length > maxRuns) {
      _runs.removeAt(0);
    }
    return true;
  }

  /// 휴대폰이 서버에서 확정(성공 또는 이미 처리됨)한 기록을 뺀다.
  void acknowledge(String activityId) =>
      _runs.removeWhere((r) => r.activityId == activityId);

  String encode() => jsonEncode([for (final r in _runs) r.toJson()]);

  static SyncQueue decode(String raw, {int maxRuns = 50}) {
    final queue = SyncQueue(maxRuns: maxRuns);
    try {
      for (final item in jsonDecode(raw) as List) {
        queue.add(PendingRun.fromJson((item as Map).cast<String, Object?>()));
      }
    } catch (_) {
      // 깨진 저장값은 비워서 시작한다. 이미 올라간 기록은 서버 쪽에 남아 있다.
    }
    return queue;
  }
}

/// 한 번의 달리기에서 기록을 만든다. 거리·시간이 없으면 null(올릴 게 없다).
PendingRun? buildPendingRun({
  required String activityId,
  required double distanceKm,
  required Duration movingTime,
  required List<int> heartRates,
  required DateTime startedAt,
  required DateTime endedAt,
  int totalSteps = 0,
  List<GpsFix> gpsRoute = const [],
  List<Map<String, Object>> paceSamples = const [],
}) {
  if (distanceKm <= 0 || movingTime.inSeconds <= 0) return null;
  return PendingRun(
    activityId: activityId,
    distanceKm: double.parse(distanceKm.toStringAsFixed(3)),
    durationSeconds: movingTime.inSeconds,
    heartRates: heartRates.length > 50000 ? heartRates.sublist(0, 50000) : heartRates,
    startedAt: startedAt,
    endedAt: endedAt,
    totalSteps: totalSteps < 0 ? 0 : totalSteps,
    gpsRoute: gpsRoute.length > 400 ? gpsRoute.sublist(gpsRoute.length - 400) : gpsRoute,
    paceSamples: paceSamples.length > 2000
        ? paceSamples.sublist(paceSamples.length - 2000)
        : paceSamples,
  );
}
