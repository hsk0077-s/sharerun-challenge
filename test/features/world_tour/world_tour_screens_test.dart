import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/run_result/run_finish_image_share.dart';
import 'package:share_run_challenge/features/world_tour/screens/world_tour_arrival_screen.dart';
import 'package:share_run_challenge/features/world_tour/screens/world_tour_screens.dart';
import 'package:share_run_challenge/features/world_tour/widgets/world_tour_widgets.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_run_end.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

import 'world_tour_support.dart';

const _eiffel = 'france_eiffel';

/// A tall phone so a lazy list builds every card and button.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('mission list', () {
    testWidgets('shows the five missions and recommends the Eiffel Tower first',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        tourApp(home: const WorldTourListScreen(), api: FakeWorldTourApi()),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘은 어디로 달릴까요?'), findsOneWidget);
      for (final id in [
        _eiffel,
        'india_taj',
        'japan_fuji',
        'egypt_pyramids',
        'usa_liberty',
      ]) {
        expect(
          find.byKey(WorldTourMissionCard.cardKey(id), skipOffstage: false),
          findsOneWidget,
          reason: id,
        );
      }
      expect(find.text('프랑스 에펠탑'), findsOneWidget);
      expect(find.text('목표 1 km'), findsOneWidget);
      expect(find.text('0 / 1 km'), findsOneWidget);
      expect(find.byKey(WorldTourMissionCard.recommendedKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(WorldTourMissionCard.cardKey(_eiffel)),
          matching: find.byKey(WorldTourMissionCard.recommendedKey),
        ),
        findsOneWidget,
      );
      expect(find.byKey(WorldTourVirtualNote.noteKey), findsOneWidget);
      expect(find.text('가상 여행 거리'), findsOneWidget);
    });

    testWidgets('progress and finished missions come from the server only',
        (tester) async {
      _tall(tester);
      final api = FakeWorldTourApi(
        me: meJson(progress: {'india_taj': 0.5}, done: {_eiffel}),
      );
      await tester.pumpWidget(
        tourApp(home: const WorldTourListScreen(), api: api),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(WorldTourMissionCard.doneKey), findsOneWidget);
      expect(find.text('완주'), findsOneWidget);
      expect(find.text('0.5 / 2 km'), findsOneWidget);
      // Someone who has started is not pushed toward the first trip again.
      expect(find.byKey(WorldTourMissionCard.recommendedKey), findsNothing);
    });

    testWidgets('no numbers are invented when the server cannot be read',
        (tester) async {
      final api = FakeWorldTourApi()..fetchError = const SocketException('x');
      await tester.pumpWidget(
        tourApp(home: const WorldTourListScreen(), api: api),
      );
      await tester.pumpAndSettle();

      expect(find.text('여행 정보를 불러오지 못했어요.'), findsOneWidget);
      expect(find.byType(WorldTourMissionCard), findsNothing);
      expect(find.textContaining(' km'), findsNothing);

      api.fetchError = null;
      await tester.tap(find.byKey(const Key('world-tour-retry')));
      await tester.pumpAndSettle();
      expect(find.byType(WorldTourMissionCard), findsWidgets);
    });

    testWidgets('a card opens the mission and the passport button opens the book',
        (tester) async {
      await tester.pumpWidget(
        tourRouterApp(
          api: FakeWorldTourApi(),
          initial: RouteNames.worldTour,
          routes: [
            GoRoute(
              path: RouteNames.worldTour,
              builder: (_, __) => const WorldTourListScreen(),
            ),
            GoRoute(
              path: RouteNames.worldTourMissionPattern,
              builder: (_, s) => WorldTourDetailScreen(
                missionId: s.pathParameters['missionId']!,
              ),
            ),
            GoRoute(
              path: RouteNames.worldTourPassport,
              builder: (_, __) => const WorldTourPassportScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WorldTourMissionCard.cardKey(_eiffel)));
      await tester.pumpAndSettle();
      expect(find.byKey(WorldTourDetailScreen.startKey), findsOneWidget);
    });
  });

  group('mission detail', () {
    testWidgets('tells start, middle and arrival and offers the start button',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        tourApp(
          home: const WorldTourDetailScreen(missionId: _eiffel),
          api: FakeWorldTourApi(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('프랑스 에펠탑'), findsOneWidget);
      expect(find.text('출발'), findsOneWidget);
      expect(find.text('중간'), findsOneWidget);
      expect(find.text('도착'), findsOneWidget);
      expect(find.text('파리의 아침, 센 강변에서 가볍게 출발해요.'), findsOneWidget);
      expect(find.text('에펠탑 앞에 도착! 파리를 달렸어요.'), findsOneWidget);
      expect(find.text('여행 출발하기'), findsOneWidget);
      expect(find.byKey(WorldTourVirtualNote.noteKey), findsOneWidget);
    });

    testWidgets('start opens the ordinary run screen route with the mission only',
        (tester) async {
      final profile = UserModel.dashboardDefault(uid: 'u1')
          .copyWith(healthDataConsent: true);
      Object? extra;
      await tester.pumpWidget(
        tourRouterApp(
          api: FakeWorldTourApi(),
          initial: '/detail',
          overrides: [
            activeUserProfileProvider.overrideWith(
              (ref) => Stream<UserModel>.value(profile),
            ),
          ],
          routes: [
            GoRoute(
              path: '/detail',
              builder: (_, __) =>
                  const WorldTourDetailScreen(missionId: _eiffel),
            ),
            GoRoute(
              path: RouteNames.runTracking,
              builder: (_, s) {
                extra = s.extra;
                return const Scaffold(body: Text('run-screen'));
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WorldTourDetailScreen.startKey));
      await tester.pumpAndSettle();

      expect(find.text('run-screen'), findsOneWidget);
      final args = extra as WorldTourRunArgs;
      expect(args.missionId, _eiffel);
      expect(args.landmarkId, 'eiffel_tower');
    });

    testWidgets('a finished mission has no start button', (tester) async {
      await tester.pumpWidget(
        tourApp(
          home: const WorldTourDetailScreen(missionId: _eiffel),
          api: FakeWorldTourApi(me: meJson(done: {_eiffel})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(WorldTourDetailScreen.startKey), findsNothing);
      expect(find.byKey(WorldTourDetailScreen.doneNoteKey), findsOneWidget);
    });
  });

  group('run screen trip line', () {
    Future<void> pumpChip(
      WidgetTester tester,
      FakeWorldTourApi api,
      double runKm,
    ) async {
      await tester.pumpWidget(
        tourApp(
          api: api,
          home: Scaffold(
            body: WorldTourRunChip(
              args: const WorldTourRunArgs(
                missionId: 'india_taj',
                landmarkId: 'taj_mahal',
              ),
              runKm: runKm,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('counts down the distance left including past progress',
        (tester) async {
      await pumpChip(
        tester,
        FakeWorldTourApi(me: meJson(progress: {'india_taj': 0.5})),
        0.4,
      );
      expect(find.text('타지마할까지 1.1 km 남음'), findsOneWidget);
      expect(find.text('가상 여행 거리'), findsOneWidget);
    });

    testWidgets('says the stamp comes after the run is confirmed',
        (tester) async {
      await pumpChip(tester, FakeWorldTourApi(), 2.3);
      expect(find.textContaining('타지마할 도착!'), findsOneWidget);
    });

    testWidgets('does not guess earlier progress when the list is missing',
        (tester) async {
      final api = FakeWorldTourApi()..fetchError = const SocketException('x');
      await pumpChip(tester, api, 0.35);
      expect(find.text('타지마할 여행 중 · 이번 0.35 km'), findsOneWidget);
      expect(find.textContaining('남음'), findsNothing);
    });
  });

  group('after the run', () {
    Future<void> pumpEnd(
      WidgetTester tester,
      FakeWorldTourApi api, {
      required bool verified,
      bool pending = false,
    }) async {
      await tester.pumpWidget(
        tourRouterApp(
          api: api,
          initial: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => TextButton(
                    key: const Key('end'),
                    onPressed: () async {
                      final end = await WorldTourRunEnd.settle(
                        ref: ref,
                        args: const WorldTourRunArgs(
                          missionId: _eiffel,
                          landmarkId: 'eiffel_tower',
                        ),
                        uid: 'u1',
                        activityId: 'a1',
                        verified: verified,
                        pending: pending,
                        distanceKm: 3.02,
                        durationSeconds: 1450,
                      );
                      end.announce(
                        router: GoRouter.of(context),
                        messenger: ScaffoldMessenger.of(context),
                      );
                    },
                    child: const Text('end'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: RouteNames.worldTourArrival,
              builder: (_, s) => Scaffold(
                body: Text(
                  'arrival ${(s.extra as WorldTourArrivalArgs).distanceKm}',
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('end')));
      await tester.pumpAndSettle();
    }

    testWidgets('a run that failed verification says it was not counted',
        (tester) async {
      final api = FakeWorldTourApi();
      await pumpEnd(tester, api, verified: false);

      expect(find.text('이번 기록은 여행 거리에 반영되지 않았어요'), findsOneWidget);
      expect(api.attachCalls, isEmpty, reason: 'nothing to ask the server');
    });

    testWidgets('a refusal from the server says the same', (tester) async {
      final api = FakeWorldTourApi()
        ..attachError =
            const ApiException(statusCode: 422, detail: 'run_not_verified');
      await pumpEnd(tester, api, verified: true);
      expect(find.text('이번 기록은 여행 거리에 반영되지 않았어요'), findsOneWidget);
    });

    testWidgets('no answer yet is kept and promised for later', (tester) async {
      final api = FakeWorldTourApi()..attachError = const SocketException('x');
      await pumpEnd(tester, api, verified: true);
      expect(find.text('여행 거리는 잠시 후 다시 반영할게요'), findsOneWidget);
    });

    testWidgets('finishing the mission opens the arrival screen', (tester) async {
      await pumpEnd(tester, FakeWorldTourApi(), verified: true);
      expect(find.text('arrival 3.02'), findsOneWidget);
    });
  });

  group('arrival', () {
    const args = WorldTourArrivalArgs(
      missionId: _eiffel,
      landmarkId: 'eiffel_tower',
      distanceKm: 3.02,
      durationSeconds: 1450,
      stampId: 'stamp-france_eiffel',
    );

    testWidgets('shows the place, real distance and time, stamp and next trip',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        tourApp(
          home: const WorldTourArrivalScreen(args: args),
          api: FakeWorldTourApi(me: meJson(done: {_eiffel})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('에펠탑 도착!'), findsOneWidget);
      expect(find.text('3.02 km  ·  24:10'), findsOneWidget);
      expect(find.text('스탬프를 받았어요'), findsOneWidget);
      expect(find.text('가상 여행 거리'), findsOneWidget);
      expect(find.text('다음 여행: 타지마할'), findsOneWidget);
      expect(find.byKey(WorldTourArrivalScreen.shareKey), findsOneWidget);
      expect(find.byKey(WorldTourArrivalScreen.passportKey), findsOneWidget);
    });

    testWidgets('share reuses the existing image capture and share sheet',
        (tester) async {
      _tall(tester);
      final dir = Directory.systemTemp.createTempSync('wt_share');
      addTearDown(() {
        RunFinishImageShare.debugCaptureOverride = null;
        RunFinishImageShare.debugSystemShare = null;
        dir.deleteSync(recursive: true);
      });
      GlobalKey? captured;
      ShareParams? shared;
      RunFinishImageShare.debugCaptureOverride = (key) async {
        captured = key;
        final file = File('${dir.path}/poster.png')..writeAsBytesSync([1, 2, 3]);
        return file;
      };
      RunFinishImageShare.debugSystemShare = (params) async {
        shared = params;
        return const ShareResult('ok', ShareResultStatus.success);
      };

      await tester.pumpWidget(
        tourApp(
          home: const WorldTourArrivalScreen(args: args),
          api: FakeWorldTourApi(me: meJson(done: {_eiffel})),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(WorldTourArrivalScreen.shareKey));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(shared!.files!.single.path, endsWith('poster.png'));
    });

    testWidgets('a failed capture shows the existing message', (tester) async {
      _tall(tester);
      addTearDown(() => RunFinishImageShare.debugCaptureOverride = null);
      RunFinishImageShare.debugCaptureOverride =
          (_) async => throw StateError('no');
      await tester.pumpWidget(
        tourApp(
          home: const WorldTourArrivalScreen(args: args),
          api: FakeWorldTourApi(me: meJson(done: {_eiffel})),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(WorldTourArrivalScreen.shareKey));
      await tester.pumpAndSettle();
      expect(find.text(RunFinishImageShare.captureFailedMessage), findsOneWidget);
    });
  });

  group('passport', () {
    testWidgets('stamps finished trips and leaves the rest empty',
        (tester) async {
      final api = FakeWorldTourApi(me: meJson(done: {_eiffel, 'japan_fuji'}));
      await tester.pumpWidget(
        tourApp(home: const WorldTourPassportScreen(), api: api),
      );
      await tester.pumpAndSettle();

      expect(find.text('2/5개국'), findsOneWidget);
      expect(find.byKey(WorldTourPassportScreen.stampedKey(_eiffel)),
          findsOneWidget);
      expect(find.byKey(WorldTourPassportScreen.stampedKey('japan_fuji')),
          findsOneWidget);
      expect(find.byKey(WorldTourPassportScreen.stampedKey('india_taj')),
          findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(3));
    });

    testWidgets('an empty book explains how to get a stamp', (tester) async {
      await tester.pumpWidget(
        tourApp(home: const WorldTourPassportScreen(), api: FakeWorldTourApi()),
      );
      await tester.pumpAndSettle();
      expect(find.text('0/5개국'), findsOneWidget);
      expect(find.text('여행을 마치면 스탬프가 찍혀요'), findsOneWidget);
    });
  });

  group('long languages on a narrow screen', () {
    // German and French run long. A 320 wide phone with large text must not
    // overflow on any World Tour screen.
    for (final language in ['de', 'fr', 'es']) {
      testWidgets('no overflow in $language', (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final api = FakeWorldTourApi(
          me: meJson(progress: {'india_taj': 0.5}, done: {_eiffel}),
        );
        final locale = Locale(language);

        Future<void> show(Widget home) async {
          await tester.pumpWidget(
            tourApp(
              home: home,
              api: api,
              locale: locale,
              textScale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: language);
        }

        await show(const WorldTourListScreen());
        await show(const WorldTourDetailScreen(missionId: 'india_taj'));
        await show(const WorldTourPassportScreen());
        await show(
          const WorldTourArrivalScreen(
            args: WorldTourArrivalArgs(
              missionId: 'india_taj',
              landmarkId: 'taj_mahal',
              distanceKm: 12.34,
              durationSeconds: 3725,
            ),
          ),
        );
        await show(
          const Scaffold(
            body: WorldTourRunChip(
              args: WorldTourRunArgs(
                missionId: 'usa_liberty',
                landmarkId: 'statue_of_liberty',
              ),
              runKm: 1.5,
            ),
          ),
        );
      });
    }

    testWidgets('texts really change language', (tester) async {
      await tester.pumpWidget(
        tourApp(
          home: const WorldTourPassportScreen(),
          api: FakeWorldTourApi(),
          locale: const Locale('de'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0/5 Länder'), findsOneWidget);
      expect(find.text('Reisepass'), findsOneWidget);
    });
  });

  testWidgets('the home door opens World Tour and sends nothing when idle',
      (tester) async {
    final api = FakeWorldTourApi();
    await tester.pumpWidget(
      tourRouterApp(
        api: api,
        initial: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: WorldTourEntryCard()),
          ),
          GoRoute(
            path: RouteNames.worldTour,
            builder: (_, __) => const Scaffold(body: Text('tour-list')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('World Tour'), findsOneWidget);
    expect(find.text('오늘은 어디로 달릴까요?'), findsOneWidget);
    expect(api.attachCalls, isEmpty);
    await tester.tap(find.byKey(WorldTourEntryCard.cardKey));
    await tester.pumpAndSettle();
    expect(find.text('tour-list'), findsOneWidget);
  });

  test('the app locale is left as the tests found it', () {
    expect(RemainingSurface.currentLocale.languageCode, 'ko');
  });
}
