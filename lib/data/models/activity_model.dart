enum ActivityValidationStatus {
  pending,
  underReview,
  verified,
  rejected,
}

/// Jena AI 러닝 로그 판정 — 어뷰징 차단 1차 게이트.
enum ActivityStatus {
  passed,
  pending,
  failed,
}

extension ActivityStatusCode on ActivityStatus {
  String get code => switch (this) {
        ActivityStatus.passed => 'passed',
        ActivityStatus.pending => 'pending',
        ActivityStatus.failed => 'failed',
      };

  ActivityValidationStatus get asValidationStatus => switch (this) {
        ActivityStatus.passed => ActivityValidationStatus.verified,
        ActivityStatus.pending => ActivityValidationStatus.pending,
        ActivityStatus.failed => ActivityValidationStatus.rejected,
      };

  static ActivityStatus fromCode(String? code) {
    return switch (code) {
      'passed' => ActivityStatus.passed,
      'failed' => ActivityStatus.failed,
      'pending' => ActivityStatus.pending,
      _ => ActivityStatus.pending,
    };
  }
}

class ActivityModel {
  const ActivityModel({
    required this.id,
    required this.userId,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averagePaceSecondsPerKm,
    required this.completedAt,
    required this.validationStatus,
    required this.jenaReason,
  });

  final String id;
  final String userId;
  final double distanceKm;
  final int? durationSeconds;
  final double? averagePaceSecondsPerKm;
  final DateTime? completedAt;
  final ActivityValidationStatus validationStatus;
  final String? jenaReason;

  /// Jena 검증 상태 — Passed / Pending / Failed.
  ActivityStatus get jenaStatus => switch (validationStatus) {
        ActivityValidationStatus.verified => ActivityStatus.passed,
        ActivityValidationStatus.rejected => ActivityStatus.failed,
        ActivityValidationStatus.pending ||
        ActivityValidationStatus.underReview =>
          ActivityStatus.pending,
      };

  /// 미소명 보류. 소명 제출([underReview])은 제외한다.
  bool get needsJenaAppeal =>
      validationStatus == ActivityValidationStatus.pending;

  ActivityModel copyWith({
    String? id,
    String? userId,
    double? distanceKm,
    int? durationSeconds,
    double? averagePaceSecondsPerKm,
    DateTime? completedAt,
    ActivityValidationStatus? validationStatus,
    String? jenaReason,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      averagePaceSecondsPerKm:
          averagePaceSecondsPerKm ?? this.averagePaceSecondsPerKm,
      completedAt: completedAt ?? this.completedAt,
      validationStatus: validationStatus ?? this.validationStatus,
      jenaReason: jenaReason ?? this.jenaReason,
    );
  }

  /// 테스트용 — 가장 최근 1건을 Jena Pending으로 강제한다.
  static List<ActivityModel> withLatestForcedPending(
    List<ActivityModel> activities,
  ) {
    if (activities.isEmpty) return activities;
    var latestIndex = 0;
    DateTime? latestAt = activities.first.completedAt;
    for (var i = 1; i < activities.length; i++) {
      final at = activities[i].completedAt;
      if (at == null) continue;
      if (latestAt == null || at.isAfter(latestAt)) {
        latestAt = at;
        latestIndex = i;
      }
    }
    final latest = activities[latestIndex];
    if (latest.needsJenaAppeal) return activities;
    final next = [...activities];
    next[latestIndex] = latest.copyWith(
      validationStatus: ActivityValidationStatus.pending,
      jenaReason: 'pending',
    );
    return next;
  }

  static String? idFromRouteExtra(Object? extra) {
    if (extra is Map) {
      final raw = extra['activityId'];
      if (raw == null) return null;
      final id = raw.toString().trim();
      return id.isEmpty ? null : id;
    }
    if (extra is String) {
      final id = extra.trim();
      return id.isEmpty ? null : id;
    }
    return null;
  }

  String? get formattedPace {
    final pace = averagePaceSecondsPerKm;
    if (pace == null || pace <= 0) {
      return null;
    }
    final minutes = pace ~/ 60;
    final seconds = (pace % 60).round().clamp(0, 59);
    return '$minutes:${seconds.toString().padLeft(2, '0')} min/km';
  }
}
