import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_coordinator.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_models.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_providers.dart';

import '../../support/ko_localization.dart';

/// The server's five missions as JSON, with optional progress overrides.
Map<String, dynamic> meJson({
  Map<String, double> progress = const {},
  Set<String> done = const {},
}) {
  const rows = [
    ('france_eiffel', 'eiffel_tower', 'FR', 1.0, 1),
    ('india_taj', 'taj_mahal', 'IN', 2.0, 2),
    ('japan_fuji', 'mount_fuji', 'JP', 3.0, 3),
    ('egypt_pyramids', 'pyramids', 'EG', 5.0, 4),
    ('usa_liberty', 'statue_of_liberty', 'US', 3.0, 5),
  ];
  final missions = [
    for (final (id, landmark, country, target, order) in rows)
      {
        'mission_id': id,
        'title': id,
        'country_code': country,
        'landmark_id': landmark,
        'target_km': target,
        'order': order,
        'progress_km': done.contains(id) ? target : (progress[id] ?? 0.0),
        'state': done.contains(id) ? 'completed' : 'active',
        'stamp_id': done.contains(id) ? 'stamp-$id' : null,
        'completed_at': done.contains(id) ? '2026-11-12T01:00:00' : null,
      },
  ];
  return {
    'missions': missions,
    'passport': [
      for (final m in missions)
        if (m['state'] == 'completed')
          {
            'mission_id': m['mission_id'],
            'stamp_id': m['stamp_id'],
            'landmark_id': m['landmark_id'],
            'completed_at': m['completed_at'],
          },
    ],
    'completed_count': done.length,
    'total_count': rows.length,
  };
}

/// A server stand-in with the same one-run-one-link rule as the real one.
class FakeWorldTourApi implements WorldTourApi {
  FakeWorldTourApi({Map<String, dynamic>? me}) : meData = me ?? meJson();

  Map<String, dynamic> meData;
  Object? fetchError;
  Object? attachError;
  final attachCalls = <(String, String)>[];
  final _linked = <String>{};
  double progress = 0;
  Completer<void>? attachGate;

  @override
  Future<WorldTourMe> fetchMe() async {
    final error = fetchError;
    if (error != null) throw error;
    return WorldTourMe.fromJson(meData);
  }

  @override
  Future<WorldTourAttachResult> attach({
    required String missionId,
    required String activityId,
  }) async {
    attachCalls.add((missionId, activityId));
    final gate = attachGate;
    if (gate != null) await gate.future;
    final error = attachError;
    if (error != null) throw error;
    final again = !_linked.add(activityId);
    if (!again) progress += 1.2;
    final finished = progress >= 1.0;
    return WorldTourAttachResult(
      missionId: missionId,
      activityId: activityId,
      countedKm: 1.2,
      progressKm: progress,
      targetKm: 1.0,
      completed: finished,
      alreadyAttached: again,
      newlyCompleted: finished && !again,
      stampId: finished ? 'stamp-$missionId' : null,
    );
  }
}

Widget tourApp({
  required Widget home,
  required FakeWorldTourApi api,
  Locale locale = koTestLocale,
  List<Override> overrides = const [],
  double textScale = 1.0,
  Size? size,
}) {
  return ProviderScope(
    overrides: [
      worldTourApiProvider.overrideWithValue(api),
      ...overrides,
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: koTestSupportedLocales,
      localizationsDelegates: koTestDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          size: size ?? MediaQuery.of(context).size,
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

Widget tourRouterApp({
  required FakeWorldTourApi api,
  required List<GoRoute> routes,
  required String initial,
  Locale locale = koTestLocale,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      worldTourApiProvider.overrideWithValue(api),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: locale,
      supportedLocales: koTestSupportedLocales,
      localizationsDelegates: koTestDelegates,
      routerConfig: GoRouter(initialLocation: initial, routes: routes),
    ),
  );
}
