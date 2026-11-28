import 'package:flutter/widgets.dart';

import '../l10n/watch_copy.dart';

/// What the watch could load for the four glance faces.
enum WatchGlanceState { unpaired, loading, offline, ready }

/// One read of `POST /actions/watch/glance`. Missing pieces stay null.
class WatchGlance {
  const WatchGlance({
    required this.diamondBalance,
    required this.goals,
    this.tierCode,
    this.world,
    this.race,
    this.crew,
  });

  final int diamondBalance;
  final String? tierCode;
  final WorldTourGlance? world;
  final GoalGlance goals;
  final RaceGlance? race;
  final CrewGlance? crew;

  static WatchGlance? tryParse(Map<String, Object?> json) {
    final goals = GoalGlance.tryParse(json['goals']);
    if (goals == null) return null;
    final diamonds = json['diamond_balance'];
    return WatchGlance(
      diamondBalance: diamonds is num && diamonds >= 0 ? diamonds.toInt() : 0,
      tierCode: json['tier_code'] is String ? json['tier_code'] as String : null,
      goals: goals,
      world: WorldTourGlance.tryParse(json['world_tour']),
      race: RaceGlance.tryParse(json['race']),
      crew: CrewGlance.tryParse(json['crew']),
    );
  }
}

class WorldTourGlance {
  const WorldTourGlance({
    required this.landmarkId,
    required this.countryCode,
    required this.title,
    required this.progressKm,
    required this.targetKm,
    required this.remainingKm,
    required this.completedCount,
    required this.totalCount,
    required this.allDone,
  });

  final String landmarkId;
  final String countryCode;
  final String title;
  final double progressKm;
  final double targetKm;
  final double remainingKm;
  final int completedCount;
  final int totalCount;
  final bool allDone;

  static WorldTourGlance? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();
    final landmark = json['landmark_id'];
    if (landmark is! String || landmark.isEmpty) return null;
    return WorldTourGlance(
      landmarkId: landmark,
      countryCode: json['country_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      progressKm: _km(json['progress_km']),
      targetKm: _km(json['target_km']),
      remainingKm: _km(json['remaining_km']),
      completedCount: _count(json['completed_count']),
      totalCount: _count(json['total_count']),
      allDone: json['all_done'] == true,
    );
  }
}

class GoalGlance {
  const GoalGlance({
    required this.todayKm,
    required this.todayTargetKm,
    required this.weekKm,
    required this.weekTargetKm,
  });

  final double todayKm;
  final double todayTargetKm;
  final double weekKm;
  final double weekTargetKm;

  static GoalGlance? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();
    if (json['today_target_km'] is! num || json['week_target_km'] is! num) return null;
    return GoalGlance(
      todayKm: _km(json['today_km']),
      todayTargetKm: _km(json['today_target_km']),
      weekKm: _km(json['week_km']),
      weekTargetKm: _km(json['week_target_km']),
    );
  }
}

class RaceGlance {
  const RaceGlance({
    required this.tournamentId,
    required this.name,
    required this.field,
    this.rank,
  });

  final String tournamentId;
  final String name;
  final int? rank;
  final int field;

  static RaceGlance? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();
    final id = json['tournament_id'];
    if (id is! String || id.isEmpty) return null;
    final rank = json['rank'];
    return RaceGlance(
      tournamentId: id,
      name: json['name'] as String? ?? '',
      rank: rank is num && rank >= 1 ? rank.toInt() : null,
      field: _count(json['field']),
    );
  }
}

class CrewGlance {
  const CrewGlance({
    required this.name,
    required this.weekKm,
    this.rank,
  });

  final String name;
  final double weekKm;

  /// This month's crew rank. The server has no weekly rank.
  final int? rank;

  static CrewGlance? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();
    final rank = json['rank'];
    return CrewGlance(
      name: json['name'] as String? ?? '',
      weekKm: _km(json['week_km']),
      rank: rank is num && rank >= 1 ? rank.toInt() : null,
    );
  }
}

double _km(Object? raw) {
  if (raw is! num || raw.isNaN || raw.isInfinite || raw < 0) return 0;
  return raw.toDouble();
}

int _count(Object? raw) => raw is num && raw >= 0 ? raw.toInt() : 0;

/// One decimal when it matters, otherwise a whole number. Never a made-up value.
String formatGlanceKm(double km) {
  if (!km.isFinite || km < 0) return '0';
  final rounded = (km * 10).round() / 10;
  if ((rounded - rounded.roundToDouble()).abs() < 0.001) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(1);
}

class GlanceLines {
  const GlanceLines({
    required this.title,
    required this.headline,
    this.detail = '',
    this.foot = '',
  });

  final String title;
  final String headline;
  final String detail;
  final String foot;
}

GlanceLines _blocked(Locale locale, String title, WatchGlanceState state) {
  if (state == WatchGlanceState.unpaired) {
    return GlanceLines(title: title, headline: watchUi(locale, 'glanceUnpaired'));
  }
  if (state == WatchGlanceState.offline) {
    return GlanceLines(title: title, headline: watchUi(locale, 'glanceOffline'));
  }
  return GlanceLines(title: title, headline: WatchCopy.of(locale).checking);
}

GlanceLines worldLines(Locale locale, WatchGlanceState state, WatchGlance? glance) {
  final title = watchUi(locale, 'glanceWorld');
  if (state != WatchGlanceState.ready || glance?.world == null) {
    return _blocked(locale, title, state);
  }
  final world = glance!.world!;
  final progress = watchUi(
    locale,
    'glanceOverall',
    n: '${world.completedCount}/${world.totalCount}',
  );
  if (world.allDone) {
    return GlanceLines(
      title: title,
      headline: watchUi(locale, 'glanceAllDone'),
      detail: progress,
    );
  }
  final city = watchPlaceName(locale, world.landmarkId, city: true);
  final country = watchPlaceName(locale, world.landmarkId, city: false) ?? '';
  return GlanceLines(
    title: title,
    headline: (city == null || city.isEmpty) ? world.title : city,
    detail: country,
    foot:
        '${watchUi(locale, 'glanceRemain', n: formatGlanceKm(world.remainingKm))}\n$progress',
  );
}

GlanceLines challengeLines(Locale locale, WatchGlanceState state, WatchGlance? glance) {
  final title = watchUi(locale, 'glanceChallenge');
  if (state != WatchGlanceState.ready || glance == null) {
    return _blocked(locale, title, state);
  }
  final goals = glance.goals;
  final today = '${formatGlanceKm(goals.todayKm)}/${formatGlanceKm(goals.todayTargetKm)} km';
  final week = '${formatGlanceKm(goals.weekKm)}/${formatGlanceKm(goals.weekTargetKm)} km';
  final race = glance.race;
  final foot = race == null
      ? watchUi(locale, 'glanceNoRace')
      : race.rank == null
          ? watchUi(locale, 'glanceInRace')
          : WatchCopy.rankPlace(locale, race.rank!);
  return GlanceLines(
    title: title,
    headline: today,
    detail: watchUi(locale, 'glanceWeekLine', n: week),
    foot: foot,
  );
}

GlanceLines crewLines(Locale locale, WatchGlanceState state, WatchGlance? glance) {
  final title = watchUi(locale, 'glanceCrew');
  if (state != WatchGlanceState.ready || glance == null) {
    return _blocked(locale, title, state);
  }
  final crew = glance.crew;
  if (crew == null) {
    return GlanceLines(title: title, headline: watchUi(locale, 'glanceNoCrew'));
  }
  final rank = crew.rank;
  return GlanceLines(
    title: crew.name.isEmpty ? title : crew.name,
    headline: '${formatGlanceKm(crew.weekKm)} km',
    detail: watchUi(locale, 'glanceWeekLine', n: '${formatGlanceKm(crew.weekKm)} km'),
    foot: rank == null
        ? watchUi(locale, 'glanceUnranked')
        : watchUi(locale, 'glanceMonthRank', n: rank),
  );
}

GlanceLines diamondLines(Locale locale, WatchGlanceState state, WatchGlance? glance) {
  final title = 'DIA';
  if (state != WatchGlanceState.ready || glance == null) {
    return _blocked(locale, title, state);
  }
  return GlanceLines(
    title: '',
    headline: watchUi(locale, 'glanceDia', n: glance.diamondBalance),
    detail: watchUi(locale, 'glanceOpenShop'),
  );
}
