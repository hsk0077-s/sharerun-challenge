import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/watch_account.dart';
import 'package:share_run_wear/core/watch_glance.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/core/watch_run_link.dart';
import 'package:share_run_wear/l10n/watch_copy.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

import 'support/watch_helpers.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.localeTestValue =
        const Locale('ko');
  });

  test('glance payload keeps tour, goals, rank, crew and diamonds', () {
    final glance = WatchGlance.tryParse({
      'tier_code': 'wolf',
      'diamond_balance': 12,
      'world_tour': {
        'landmark_id': 'eiffel_tower',
        'country_code': 'FR',
        'title': '프랑스 에펠탑',
        'progress_km': 0.4,
        'target_km': 1,
        'remaining_km': 0.6,
        'completed_count': 0,
        'total_count': 13,
        'all_done': false,
      },
      'goals': {
        'today_km': 1.2,
        'today_target_km': 7,
        'week_km': 8,
        'week_target_km': 49,
      },
      'race': {'tournament_id': 'race', 'name': '한강', 'rank': 4, 'field': 20},
      'crew': {'name': '새벽', 'week_km': 12.4, 'rank': 3, 'rank_period': 'month'},
    });
    expect(glance, isNotNull);
    expect(glance!.diamondBalance, 12);
    final world = worldLines(const Locale('ko'), WatchGlanceState.ready, glance);
    expect(world.headline, '파리');
    expect(world.detail, '프랑스');
    expect(world.foot, contains('0.6 km 남음'));
    expect(world.foot, contains('전체 0/13'));
    final challenge = challengeLines(const Locale('ko'), WatchGlanceState.ready, glance);
    expect(challenge.headline, '1.2/7 km');
    expect(challenge.detail, '이번 주 8/49 km');
    expect(challenge.foot, '4위');
    final crew = crewLines(const Locale('ko'), WatchGlanceState.ready, glance);
    expect(crew.title, '새벽');
    expect(crew.headline, '12.4 km');
    expect(crew.foot, '이번 달 3위');
    expect(crew.foot, isNot(contains('응원')));
    final dia = diamondLines(const Locale('ko'), WatchGlanceState.ready, glance);
    expect(dia.headline, 'DIA 12개');
  });

  test('empty states stay empty: no crew, no race, offline, unpaired', () {
    const locale = Locale('ko');
    final bare = WatchGlance.tryParse({
      'diamond_balance': 0,
      'goals': {
        'today_km': 0,
        'today_target_km': 3,
        'week_km': 0,
        'week_target_km': 21,
      },
      'race': null,
      'crew': null,
      'world_tour': {
        'landmark_id': 'gwanghwamun',
        'title': '한국 서울 광화문',
        'remaining_km': 2,
        'completed_count': 5,
        'total_count': 13,
        'all_done': false,
      },
    });
    expect(challengeLines(locale, WatchGlanceState.ready, bare).foot, '참여 중인 대회가 없어요');
    expect(crewLines(locale, WatchGlanceState.ready, bare).headline, '참여 중인 크루가 없어요');
    expect(worldLines(locale, WatchGlanceState.offline, bare).headline, contains('달팽이봇'));
    expect(worldLines(locale, WatchGlanceState.offline, bare).headline, isNot(contains('미니봇')));
    expect(diamondLines(locale, WatchGlanceState.unpaired, null).headline, contains('연결'));
    expect(watchPlaceName(const Locale('en'), 'gwanghwamun', city: true), 'Seoul');
    expect(watchPlaceName(const Locale('ja'), 'mount_fuji', city: false), '日本');
  });

  test('a malformed board is not shown as zeros', () {
    expect(WatchGlance.tryParse({'diamond_balance': 4}), isNull);
  });

  test('fetchGlance sends device_id and reads the board', () async {
    final poster = _Poster()
      ..on('/auth/watch-pair', const HttpReply(200, {
        'custom_token': 'custom',
        'nickname': '달림이',
        'tier_code': 'wolf',
      }))
      ..on('signInWithCustomToken', const HttpReply(200, {
        'idToken': 'id',
        'refreshToken': 'refresh',
        'expiresIn': '3600',
      }))
      ..on('/actions/watch/glance', const HttpReply(200, {
        'tier_code': 'wolf',
        'diamond_balance': 2,
        'goals': {
          'today_km': 1,
          'today_target_km': 7,
          'week_km': 1,
          'week_target_km': 49,
        },
      }));
    final account = WatchAccount(
      store: MemoryStore(),
      poster: poster,
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await account.pair('482910');
    final glance = await account.fetchGlance();
    expect(glance!.diamondBalance, 2);
    final call = poster.calls.lastWhere((c) => c.uri.path == '/actions/watch/glance');
    expect(call.body['device_id'], isA<String>());
    expect((call.body['device_id'] as String).length, greaterThanOrEqualTo(8));
    expect(call.headers['Authorization'], 'Bearer id');
  });

  testWidgets('diamond tap asks the phone to open the shop and does not sell', (tester) async {
    final opener = _ShopOpener();
    final glance = WatchGlance.tryParse({
      'diamond_balance': 9,
      'goals': {
        'today_km': 0,
        'today_target_km': 3,
        'week_km': 0,
        'week_target_km': 21,
      },
    });
    await tester.pumpWidget(MaterialApp(
      home: GlanceFace(
        kind: GlanceKind.diamond,
        state: WatchGlanceState.ready,
        glance: glance,
        onOpenShop: () => opener.open(buildWatchShopUri()),
      ),
    ));
    expect(find.text('DIA 9개'), findsOneWidget);
    expect(find.textContaining('구매'), findsNothing);
    expect(find.textContaining('결제'), findsNothing);
    await tester.tap(find.byKey(GlanceFace.diamondKey));
    await tester.pump();
    expect(opener.uris, ['sharerun://shop']);
    expect(find.text('폰에서 상점을 열었어요'), findsOneWidget);
  });

  testWidgets('one swipe still pauses, the next swipe right is still the route', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RunFlow(queue: SyncQueue())));
    await startRun(tester);
    await swipeToControls(tester);
    expect(find.text('일시정지됨'), findsOneWidget);
    await tester.tap(find.byKey(ControlsFace.resumeKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await swipeToRoute(tester);
    expect(find.byKey(RouteFace.waitingKey), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(400, 0), 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(GlanceFace.worldKey), findsOneWidget);
    expect(find.textContaining('미니봇'), findsNothing);
  });

  testWidgets('the home screen swipes to the world tour without starting', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RunFlow(queue: SyncQueue())));
    expect(find.byKey(StartFace.buttonKey), findsOneWidget);
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    await tester.drag(find.byType(PageView), Offset(-width, 0));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(GlanceFace.worldKey)).dx, inInclusiveRange(0, width));
    final start = find.byKey(StartFace.buttonKey);
    if (start.evaluate().isNotEmpty) {
      expect(tester.getCenter(start).dx, isNot(inInclusiveRange(0, width)));
    }
    expect(
      tester.widget<Text>(find.byKey(GlanceFace.worldKey)).data,
      '폰 앱에서 워치를 연결해 주세요',
    );
  });

  testWidgets('writes glance previews when an artifacts folder is present', (tester) async {
    final out = Directory('/opt/cursor/artifacts');
    if (!out.existsSync()) return;
    tester.platformDispatcher.localeTestValue = const Locale('en');
    final loader = FontLoader('NotoSansKR')
      ..addFont(Future<ByteData>.value(ByteData.sublistView(
        File('test/fonts/NotoSansKR-700.ttf').readAsBytesSync(),
      )));
    await loader.load();
    const size = Size(384, 384);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final glance = WatchGlance.tryParse({
      'diamond_balance': 12,
      'world_tour': {
        'landmark_id': 'eiffel_tower',
        'title': '프랑스 에펠탑',
        'remaining_km': 0.6,
        'completed_count': 2,
        'total_count': 13,
        'all_done': false,
      },
      'goals': {
        'today_km': 1.2,
        'today_target_km': 7,
        'week_km': 8,
        'week_target_km': 49,
      },
      'race': {'tournament_id': 'race', 'name': '한강', 'rank': 4, 'field': 20},
      'crew': {'name': '새벽', 'week_km': 12.4, 'rank': 3},
    });
    const shots = [
      (GlanceKind.world, 'watch-glance-world.png'),
      (GlanceKind.challenge, 'watch-glance-challenge.png'),
      (GlanceKind.crew, 'watch-glance-crew.png'),
      (GlanceKind.diamond, 'watch-glance-diamond.png'),
    ];
    for (final shot in shots) {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'NotoSansKR', brightness: Brightness.dark),
        home: RepaintBoundary(
          key: const Key('glance-shot'),
          child: GlanceFace(
            kind: shot.$1,
            state: WatchGlanceState.ready,
            glance: glance,
          ),
        ),
      ));
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('glance-shot')));
      final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
      final bytes = await tester.runAsync(() async => (await image!.toByteData(format: ui.ImageByteFormat.png))!);
      File('${out.path}/${shot.$2}').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}

class _Call {
  _Call(this.uri, this.body, this.headers);
  final Uri uri;
  final Map<String, Object?> body;
  final Map<String, String> headers;
}

class _Poster implements JsonPoster {
  final calls = <_Call>[];
  final replies = <String, HttpReply>{};

  void on(String part, HttpReply reply) => replies[part] = reply;

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    calls.add(_Call(uri, body, headers));
    for (final entry in replies.entries) {
      if (uri.toString().contains(entry.key)) return entry.value;
    }
    return const HttpReply(404, {});
  }
}

class _ShopOpener implements WatchPhoneOpener {
  final uris = <String>[];

  @override
  Future<bool> open(String uri) async {
    uris.add(uri);
    return true;
  }
}
