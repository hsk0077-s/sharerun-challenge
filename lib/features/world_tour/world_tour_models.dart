/// World Tour data as the server reports it. The app never computes progress
/// on its own: a mission advances only by the server's attach answer.
class WorldTourMission {
  const WorldTourMission({
    required this.missionId,
    required this.title,
    required this.countryCode,
    required this.landmarkId,
    required this.targetKm,
    required this.order,
    required this.progressKm,
    required this.completed,
    this.stampId,
    this.completedAt,
  });

  final String missionId;

  /// Server (Korean) title. Screens show the translated landmark name instead
  /// and use this only for a landmark the app has no name for.
  final String title;
  final String countryCode;
  final String landmarkId;
  final double targetKm;
  final int order;
  final double progressKm;
  final bool completed;
  final String? stampId;
  final DateTime? completedAt;

  double get remainingKm => (targetKm - progressKm).clamp(0, targetKm);

  /// 0..1 for a bar.
  double get fraction =>
      targetKm <= 0 ? 0 : (progressKm / targetKm).clamp(0.0, 1.0);

  bool get started => progressKm > 0;

  factory WorldTourMission.fromJson(Map<String, dynamic> json) {
    return WorldTourMission(
      missionId: json['mission_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      landmarkId: json['landmark_id'] as String? ?? '',
      targetKm: _num(json['target_km']),
      order: (json['order'] as num?)?.toInt() ?? 0,
      progressKm: _num(json['progress_km']),
      completed: json['state'] == 'completed',
      stampId: json['stamp_id'] as String?,
      completedAt: _time(json['completed_at']),
    );
  }
}

class WorldTourStamp {
  const WorldTourStamp({
    required this.missionId,
    required this.stampId,
    required this.landmarkId,
    this.completedAt,
  });

  final String missionId;
  final String stampId;
  final String landmarkId;
  final DateTime? completedAt;

  factory WorldTourStamp.fromJson(Map<String, dynamic> json) {
    return WorldTourStamp(
      missionId: json['mission_id'] as String? ?? '',
      stampId: json['stamp_id'] as String? ?? '',
      landmarkId: json['landmark_id'] as String? ?? '',
      completedAt: _time(json['completed_at']),
    );
  }
}

class WorldTourMe {
  const WorldTourMe({
    required this.missions,
    required this.passport,
    required this.completedCount,
    required this.totalCount,
  });

  final List<WorldTourMission> missions;
  final List<WorldTourStamp> passport;
  final int completedCount;
  final int totalCount;

  bool get hasAnyProgress => missions.any((m) => m.started || m.completed);

  WorldTourMission? mission(String missionId) {
    for (final m in missions) {
      if (m.missionId == missionId) return m;
    }
    return null;
  }

  /// First mission, in order, that is not finished. Null when all are done.
  WorldTourMission? get firstOpen {
    for (final m in missions) {
      if (!m.completed) return m;
    }
    return null;
  }

  /// The mission to suggest first. A new traveller is sent to the first one.
  WorldTourMission? get recommended => firstOpen;

  /// The next open mission after [missionId], else the first open one.
  WorldTourMission? nextAfter(String missionId) {
    var seen = false;
    for (final m in missions) {
      if (m.missionId == missionId) {
        seen = true;
        continue;
      }
      if (seen && !m.completed) return m;
    }
    for (final m in missions) {
      if (m.missionId != missionId && !m.completed) return m;
    }
    return null;
  }

  factory WorldTourMe.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(Object? raw) => [
          for (final item in raw is List ? raw : const [])
            if (item is Map) Map<String, dynamic>.from(item),
        ];
    final missions = rows(json['missions']).map(WorldTourMission.fromJson).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return WorldTourMe(
      missions: missions,
      passport: rows(json['passport']).map(WorldTourStamp.fromJson).toList(),
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? missions.length,
    );
  }
}

class WorldTourAttachResult {
  const WorldTourAttachResult({
    required this.missionId,
    required this.activityId,
    required this.countedKm,
    required this.progressKm,
    required this.targetKm,
    required this.completed,
    required this.alreadyAttached,
    required this.newlyCompleted,
    this.stampId,
  });

  final String missionId;
  final String activityId;
  final double countedKm;
  final double progressKm;
  final double targetKm;
  final bool completed;
  final bool alreadyAttached;
  final bool newlyCompleted;
  final String? stampId;

  double get remainingKm => (targetKm - progressKm).clamp(0, targetKm);

  factory WorldTourAttachResult.fromJson(Map<String, dynamic> json) {
    return WorldTourAttachResult(
      missionId: json['mission_id'] as String? ?? '',
      activityId: json['activity_id'] as String? ?? '',
      countedKm: _num(json['counted_km']),
      progressKm: _num(json['progress_km']),
      targetKm: _num(json['target_km']),
      completed: json['state'] == 'completed',
      alreadyAttached: json['already_attached'] == true,
      newlyCompleted: json['newly_completed'] == true,
      stampId: json['stamp_id'] as String?,
    );
  }
}

double _num(Object? value) => value is num ? value.toDouble() : 0.0;

DateTime? _time(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
