import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pedometer/kst_calendar.dart';

/// Persisted stamp-tour progress. Landmarks survive restarts; walk mission
/// is daily (KST) and resets on a new date key.
@immutable
class StampTourProgress {
  const StampTourProgress({
    required this.visitedLandmarkIds,
    required this.rewardedLandmarkIds,
    required this.walkMissionCompleted,
    required this.walkDistanceKm,
    required this.walkRewardClaimed,
    required this.walkDateKey,
  });

  final Set<String> visitedLandmarkIds;

  /// Official landmark IDs queued for DIA. Not a minted-wallet receipt —
  /// `UserRepository.addDiamondBalance` is a server-owned no-op.
  final Set<String> rewardedLandmarkIds;
  final bool walkMissionCompleted;
  final double walkDistanceKm;
  final bool walkRewardClaimed;
  final String walkDateKey;

  factory StampTourProgress.empty({String? dateKey}) {
    return StampTourProgress(
      visitedLandmarkIds: const {},
      rewardedLandmarkIds: const {},
      walkMissionCompleted: false,
      walkDistanceKm: 0,
      walkRewardClaimed: false,
      walkDateKey: dateKey ?? KstCalendar.dateKey(),
    );
  }

  /// Landmark stamps persist; today's 1km walk resets after KST midnight.
  StampTourProgress forDate(String todayKey) {
    if (walkDateKey == todayKey) return this;
    return StampTourProgress(
      visitedLandmarkIds: visitedLandmarkIds,
      rewardedLandmarkIds: rewardedLandmarkIds,
      walkMissionCompleted: false,
      walkDistanceKm: 0,
      walkRewardClaimed: false,
      walkDateKey: todayKey,
    );
  }

  StampTourProgress copyWith({
    Set<String>? visitedLandmarkIds,
    Set<String>? rewardedLandmarkIds,
    bool? walkMissionCompleted,
    double? walkDistanceKm,
    bool? walkRewardClaimed,
    String? walkDateKey,
  }) {
    return StampTourProgress(
      visitedLandmarkIds: visitedLandmarkIds ?? this.visitedLandmarkIds,
      rewardedLandmarkIds: rewardedLandmarkIds ?? this.rewardedLandmarkIds,
      walkMissionCompleted: walkMissionCompleted ?? this.walkMissionCompleted,
      walkDistanceKm: walkDistanceKm ?? this.walkDistanceKm,
      walkRewardClaimed: walkRewardClaimed ?? this.walkRewardClaimed,
      walkDateKey: walkDateKey ?? this.walkDateKey,
    );
  }
}

class StampTourProgressStore {
  const StampTourProgressStore();

  static const visitedKey = 'src.stamp.visited_ids';
  static const rewardedKey = 'src.stamp.rewarded_ids';
  static const walkDoneKey = 'src.stamp.walk_done';
  static const walkKmKey = 'src.stamp.walk_km';
  static const walkClaimedKey = 'src.stamp.walk_claimed';
  static const walkDateKey = 'src.stamp.walk_date';

  Future<StampTourProgress> read({String? todayKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = todayKey ?? KstCalendar.dateKey();
    final stored = StampTourProgress(
      visitedLandmarkIds: _ids(prefs.getStringList(visitedKey)),
      rewardedLandmarkIds: _ids(prefs.getStringList(rewardedKey)),
      walkMissionCompleted: prefs.getBool(walkDoneKey) ?? false,
      walkDistanceKm: prefs.getDouble(walkKmKey) ?? 0,
      walkRewardClaimed: prefs.getBool(walkClaimedKey) ?? false,
      walkDateKey: prefs.getString(walkDateKey) ?? '',
    );
    return stored.forDate(today);
  }

  Future<void> write(StampTourProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      visitedKey,
      progress.visitedLandmarkIds.toList()..sort(),
    );
    await prefs.setStringList(
      rewardedKey,
      progress.rewardedLandmarkIds.toList()..sort(),
    );
    await prefs.setBool(walkDoneKey, progress.walkMissionCompleted);
    await prefs.setDouble(walkKmKey, progress.walkDistanceKm);
    await prefs.setBool(walkClaimedKey, progress.walkRewardClaimed);
    await prefs.setString(walkDateKey, progress.walkDateKey);
  }

  static Set<String> _ids(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const {};
    return raw.where((id) => id.trim().isNotEmpty).toSet();
  }
}
