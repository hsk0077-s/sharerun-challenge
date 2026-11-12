import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A finished run that is not yet linked to its mission. Kept on the device
/// only until the server confirms (or refuses) the link. The server is
/// idempotent per run, so sending the same entry again is safe.
class WorldTourPendingRun {
  const WorldTourPendingRun({
    required this.uid,
    required this.missionId,
    required this.activityId,
    required this.savedAt,
    this.attempts = 0,
  });

  final String uid;
  final String missionId;
  final String activityId;
  final DateTime savedAt;
  final int attempts;

  WorldTourPendingRun tried() => WorldTourPendingRun(
        uid: uid,
        missionId: missionId,
        activityId: activityId,
        savedAt: savedAt,
        attempts: attempts + 1,
      );

  Map<String, Object?> toJson() => {
        'uid': uid,
        'missionId': missionId,
        'activityId': activityId,
        'savedAt': savedAt.toIso8601String(),
        'attempts': attempts,
      };

  static WorldTourPendingRun? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final uid = raw['uid'];
    final mission = raw['missionId'];
    final activity = raw['activityId'];
    final saved = DateTime.tryParse('${raw['savedAt']}');
    if (uid is! String || mission is! String || activity is! String) return null;
    if (uid.isEmpty || mission.isEmpty || activity.isEmpty || saved == null) {
      return null;
    }
    return WorldTourPendingRun(
      uid: uid,
      missionId: mission,
      activityId: activity,
      savedAt: saved,
      attempts: (raw['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorldTourPendingStore {
  WorldTourPendingStore({
    this.maxAge = const Duration(days: 7),
    this.maxEntries = 20,
    this.maxAttempts = 40,
  });

  static const prefsKey = 'world_tour_pending_runs_v1';

  final Duration maxAge;
  final int maxEntries;
  final int maxAttempts;

  Future<List<WorldTourPendingRun>> load({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    return [
      for (final item in decoded)
        if (WorldTourPendingRun.fromJson(item) case final run?)
          if (run.savedAt.isAfter(cutoff) && run.attempts < maxAttempts) run,
    ];
  }

  Future<void> _save(List<WorldTourPendingRun> runs) async {
    final prefs = await SharedPreferences.getInstance();
    final kept = runs.length > maxEntries
        ? runs.sublist(runs.length - maxEntries)
        : runs;
    await prefs.setString(
      prefsKey,
      jsonEncode([for (final run in kept) run.toJson()]),
    );
  }

  /// One entry per run: adding the same run again changes nothing.
  Future<void> add(WorldTourPendingRun run) async {
    final all = await load();
    if (all.any((r) => r.uid == run.uid && r.activityId == run.activityId)) {
      return;
    }
    await _save([...all, run]);
  }

  Future<void> remove(String uid, String activityId) async {
    final all = await load();
    await _save([
      for (final run in all)
        if (!(run.uid == uid && run.activityId == activityId)) run,
    ]);
  }

  Future<void> markTried(String uid, String activityId) async {
    final all = await load();
    await _save([
      for (final run in all)
        if (run.uid == uid && run.activityId == activityId) run.tried() else run,
    ]);
  }
}
