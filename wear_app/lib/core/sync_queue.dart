import 'dart:convert';

/// 워치에는 자이로 안정도 점수가 없다. 서버 필수 필드를 채우는 임시 값이며,
/// 서버가 "워치 단독 기록"을 별도로 다루게 되면(README "서버 쪽 남은 일") 없앤다.
const kUnknownGyroScore = 0.5;

/// 워치가 휴대폰/서버 없이 만든 기록을 담아 두는 대기열.
///
/// 서버가 같은 `activity_id`를 한 번만 인정하므로(재전송해도 중복 지급 없음),
/// 워치는 기록마다 한 번 만든 id를 끝까지 바꾸지 않는다.
/// 워치 자신은 Firebase 토큰을 들고 있지 않다. 이 대기열의 내용은 휴대폰 앱이
/// 받아서 로그인된 계정으로 서버에 올린다.
class PendingRun {
  PendingRun({
    required this.activityId,
    required this.distanceKm,
    required this.durationSeconds,
    required this.heartRates,
    required this.startedAt,
    required this.endedAt,
  });

  final String activityId;
  final double distanceKm;
  final int durationSeconds;
  final List<int> heartRates;
  final DateTime startedAt;
  final DateTime endedAt;

  /// 서버 `POST /actions/validate-run` 본문과 같은 필드 이름.
  /// 워치 단독 기록에는 GPS 경로·케이던스가 없으면 비워 둔다(서버가 근거 부족으로 판단).
  Map<String, Object?> toValidateRunBody({String? deviceId}) => {
        'activity_id': activityId,
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
        'heart_rates': heartRates,
        'cadence_spm': const <int>[],
        'gyro_stability_score': kUnknownGyroScore,
        'gps_route': const <Object>[],
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
      };

  factory PendingRun.fromJson(Map<String, Object?> json) => PendingRun(
        activityId: json['activityId']! as String,
        distanceKm: (json['distanceKm']! as num).toDouble(),
        durationSeconds: (json['durationSeconds']! as num).toInt(),
        heartRates: [for (final v in json['heartRates']! as List) (v as num).toInt()],
        startedAt: DateTime.parse(json['startedAt']! as String),
        endedAt: DateTime.parse(json['endedAt']! as String),
      );
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

  List<PendingRun> get runs => List.unmodifiable(_runs);
  int get length => _runs.length;

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
}) {
  if (distanceKm <= 0 || movingTime.inSeconds <= 0) return null;
  return PendingRun(
    activityId: activityId,
    distanceKm: double.parse(distanceKm.toStringAsFixed(3)),
    durationSeconds: movingTime.inSeconds,
    heartRates: heartRates.length > 50000 ? heartRates.sublist(0, 50000) : heartRates,
    startedAt: startedAt,
    endedAt: endedAt,
  );
}
