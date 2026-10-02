import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kst_calendar.dart';
import 'pedometer_harvest_ledger.dart';
import 'pedometer_health_cap.dart';
import 'pedometer_step_truth.dart';
import 'solo_pedometer_engine.dart';

/// One account-day of steps in `users/{uid}/daily_metrics/{yyyy-MM-dd}`.
class DailyMetricDoc {
  const DailyMetricDoc({
    required this.dayKey,
    required this.steps,
    required this.source,
    this.lastHealth,
  });

  final String dayKey;
  final int steps;

  /// `health_connect` or `sensor`.
  final String source;
  final int? lastHealth;
}

/// Per-account daily steps. Local prefs are a cache of this Firestore history.
///
/// Live totals are committed only for the caller-supplied day. A 0 never
/// writes. A different day is max-merged and cannot shrink. Today may shrink
/// only when a positive Health reading heals an inflated store.
abstract final class DailyMetricsAccount {
  static const lookbackDays = 35;

  static void Function()? onCacheUpdated;

  @visibleForTesting
  static Future<List<DailyMetricDoc>> Function(String uid)? debugLoad;

  @visibleForTesting
  static var debugUseMemory = false;

  @visibleForTesting
  static final debugDocs = <String, DailyMetricDoc>{};

  static String _pulledKey = '';
  static Future<void>? _inflight;
  static String _inflightKey = '';

  @visibleForTesting
  static void debugReset() {
    debugLoad = null;
    debugUseMemory = false;
    debugDocs.clear();
    _pulledKey = '';
    _inflight = null;
    _inflightKey = '';
    onCacheUpdated = null;
  }

  static String normalizeSource(String source, {int? lastHealth}) {
    if (source == 'health' || source == 'health_connect') {
      return 'health_connect';
    }
    if (source == 'restore' && lastHealth != null && lastHealth > 0) {
      return 'health_connect';
    }
    return 'sensor';
  }

  /// Null means do not write. Past days never go down. Today goes down only
  /// for a Health-backed heal, and never to 0. Steps stay within 0..30000.
  static DailyMetricDoc? merge({
    required String dayKey,
    required int existingSteps,
    required int incoming,
    required bool isToday,
    required String source,
    int? lastHealth,
    String? existingSource,
    int? existingLastHealth,
  }) {
    final raw = PedometerStepTruth.clampDaily(incoming);
    if (raw <= 0) return null;
    final health = (lastHealth != null && lastHealth > 0)
        ? PedometerStepTruth.clampDaily(lastHealth)
        : null;
    final previous = PedometerStepTruth.clampDaily(existingSteps);
    final normalized = normalizeSource(
      source,
      lastHealth: health,
    );
    final int steps;
    if (!isToday) {
      steps = math.max(previous, raw);
      if (steps <= previous && previous > 0) return null;
    } else if (health != null) {
      final capped = PedometerHealthCap.cap(raw, health);
      if (capped <= 0) return null;
      final healed = PedometerStepTruth.healthReplacesStored(
        stored: previous,
        healthToday: health,
        merged: capped,
      );
      steps = healed ? capped : math.max(previous, capped);
    } else {
      steps = math.max(previous, raw);
    }
    final stored = PedometerStepTruth.clampDaily(steps);
    if (stored <= 0) return null;
    final nextHealth = health ?? existingLastHealth;
    final changed = stored != previous ||
        existingSource != normalized ||
        (health != null && health != existingLastHealth);
    if (!changed && previous > 0) return null;
    return DailyMetricDoc(
      dayKey: dayKey,
      steps: stored,
      source: normalized,
      lastHealth: nextHealth,
    );
  }

  /// Login, cold start, and reinstall. Fills the weekly diary keys, the
  /// month cache My Page reads, and today's floor.
  static Future<void> pullIntoPrefs({
    required String uid,
    String? todayKey,
  }) async {
    if (uid.isEmpty) return;
    final today = todayKey ?? KstCalendar.dateKey();
    final key = '$uid|$today';
    if (_pulledKey == key) return;
    final existing = _inflight;
    if (existing != null && _inflightKey == key) {
      await existing;
      return;
    }
    _inflightKey = key;
    final future = _pull(uid, today);
    _inflight = future;
    try {
      final ok = await future;
      if (ok) _pulledKey = key;
    } finally {
      if (identical(_inflight, future)) {
        _inflight = null;
        _inflightKey = '';
      }
    }
  }

  static Future<bool> _pull(String uid, String today) async {
    List<DailyMetricDoc> rows;
    try {
      rows = debugLoad != null ? await debugLoad!(uid) : await _loadRemote(uid);
    } catch (e) {
      debugPrint('[CLOUD RECOVERY] daily_metrics 읽기 실패: $e');
      return false;
    }
    try {
      final prefs = await PedometerHealthCap.fresh();
      final wrote = await _hydrate(
        prefs,
        uid: uid,
        todayKey: today,
        rows: rows,
      );
      if (wrote) onCacheUpdated?.call();
    } catch (e) {
      debugPrint('[CLOUD RECOVERY] daily_metrics 캐시 실패: $e');
      return false;
    }
    return true;
  }

  static Future<bool> _hydrate(
    SharedPreferences prefs, {
    required String uid,
    required String todayKey,
    required List<DailyMetricDoc> rows,
  }) async {
    final start = _shiftDay(todayKey, -(lookbackDays - 1));
    if (start == null) return false;
    final localCap = PedometerHealthCap.fromPrefs(prefs, todayKey: todayKey);
    int? serverHealth;
    for (final row in rows) {
      if (row.dayKey == todayKey &&
          row.lastHealth != null &&
          row.lastHealth! > 0) {
        serverHealth = row.lastHealth;
      }
    }
    final capHealth = localCap ?? serverHealth;
    if (localCap == null && serverHealth != null) {
      await PedometerHealthCap.persist(
        prefs,
        todayKey: todayKey,
        health: serverHealth,
      );
    }
    var wrote = false;
    for (final row in rows) {
      if (row.dayKey.compareTo(start) < 0 ||
          row.dayKey.compareTo(todayKey) > 0) {
        continue;
      }
      final server = PedometerStepTruth.clampDaily(row.steps);
      if (server <= 0) continue;
      final key = '${row.dayKey}_steps';
      if (row.dayKey == todayKey) {
        final hasLocal = prefs.containsKey(key);
        final local = prefs.getInt(key) ?? 0;
        final cappedServer = PedometerHealthCap.cap(server, capHealth);
        final cappedLocal =
            hasLocal ? PedometerHealthCap.cap(local, capHealth) : 0;
        final chosen = math.max(cappedLocal, cappedServer);
        if (chosen <= 0) continue;
        if (!hasLocal || chosen != local) {
          await _cacheDay(prefs, row.dayKey, chosen);
          final prefix = PedometerHarvestLedger.prefix(
            uid: uid,
            dateKey: todayKey,
          );
          await prefs.setInt('$prefix.steps', chosen);
          await prefs.setDouble(
            '$prefix.km',
            SoloPedometerEngine.kmFromSteps(chosen),
          );
          wrote = true;
        }
      } else {
        final local = prefs.getInt(key) ?? 0;
        final merged = math.max(local, server);
        if (merged <= local) continue;
        await _cacheDay(prefs, row.dayKey, merged);
        wrote = true;
      }
    }
    if (wrote || prefs.getStringList('pedometer_weekly_history') == null) {
      await _writeWeekList(prefs, todayKey);
      wrote = true;
    }
    return wrote;
  }

  static Future<void> _cacheDay(
    SharedPreferences prefs,
    String dayKey,
    int steps,
  ) async {
    await prefs.setInt('${dayKey}_steps', steps);
    await prefs.setDouble(
      '${dayKey}_km',
      SoloPedometerEngine.kmFromSteps(steps),
    );
  }

  static Future<void> _writeWeekList(
    SharedPreferences prefs,
    String todayKey,
  ) async {
    final noon = _noon(todayKey);
    if (noon == null) return;
    final history = <String>[];
    for (final day in KstCalendar.thisWeekDays(noon)) {
      final steps = prefs.getInt('${day.key}_steps') ?? 0;
      if (steps > 0) history.add('${day.key}:$steps');
    }
    await prefs.setStringList('pedometer_weekly_history', history);
  }

  /// Writes one day. Returns false when the write is refused (0, or no change).
  static Future<bool> commit({
    required String uid,
    required String todayKey,
    required String dayKey,
    required int steps,
    required String source,
    int? lastHealth,
  }) async {
    if (uid.isEmpty || dayKey.isEmpty) return false;
    if (PedometerStepTruth.clampDaily(steps) <= 0) return false;
    final isToday = dayKey == todayKey;
    if (debugUseMemory) {
      final existing = debugDocs[dayKey];
      final merged = merge(
        dayKey: dayKey,
        existingSteps: existing?.steps ?? 0,
        incoming: steps,
        isToday: isToday,
        source: source,
        lastHealth: lastHealth,
        existingSource: existing?.source,
        existingLastHealth: existing?.lastHealth,
      );
      if (merged == null) return false;
      debugDocs[dayKey] = merged;
      return true;
    }
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_metrics')
          .doc(dayKey);
      var wrote = false;
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        final existingSteps = (data?['steps'] as num?)?.toInt() ?? 0;
        final existingSource = data?['source'] as String?;
        final existingHealth = (data?['lastHealth'] as num?)?.toInt();
        final merged = merge(
          dayKey: dayKey,
          existingSteps: existingSteps,
          incoming: steps,
          isToday: isToday,
          source: source,
          lastHealth: lastHealth,
          existingSource: existingSource,
          existingLastHealth: existingHealth,
        );
        if (merged == null) return;
        final payload = <String, dynamic>{
          'steps': merged.steps,
          'km': SoloPedometerEngine.kmFromSteps(merged.steps),
          'source': merged.source,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        final health = merged.lastHealth;
        if (health != null && health > 0) payload['lastHealth'] = health;
        tx.set(ref, payload, SetOptions(merge: true));
        wrote = true;
      });
      return wrote;
    } catch (e) {
      debugPrint('[CLOUD SYNC ERR] Firestore 걸음 수 백업 실패: $e');
      return false;
    }
  }

  static Future<List<DailyMetricDoc>> _loadRemote(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_metrics')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(lookbackDays)
        .get();
    return [
      for (final doc in snap.docs)
        if (_row(doc.id, doc.data()) case final row?) row,
    ];
  }

  static DailyMetricDoc? _row(String dayKey, Map<String, dynamic> data) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dayKey)) return null;
    final steps = (data['steps'] as num?)?.toInt() ?? 0;
    if (steps <= 0) return null;
    final health = (data['lastHealth'] as num?)?.toInt();
    return DailyMetricDoc(
      dayKey: dayKey,
      steps: PedometerStepTruth.clampDaily(steps),
      source: normalizeSource(
        data['source'] as String? ?? 'sensor',
        lastHealth: health,
      ),
      lastHealth: (health != null && health > 0) ? health : null,
    );
  }

  static DateTime? _noon(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime.utc(year, month, day);
  }

  static String? _shiftDay(String dayKey, int days) {
    final noon = _noon(dayKey);
    if (noon == null) return null;
    final shifted = noon.add(Duration(days: days));
    return KstCalendar.dateKeyFromYmd(
      shifted.year,
      shifted.month,
      shifted.day,
    );
  }
}
