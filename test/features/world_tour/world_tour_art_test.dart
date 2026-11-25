import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/world_tour/screens/world_tour_arrival_screen.dart';
import 'package:share_run_challenge/features/world_tour/screens/world_tour_screens.dart';
import 'package:share_run_challenge/features/world_tour/widgets/world_tour_widgets.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_landmarks.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_models.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_run_end.dart';

import 'world_tour_support.dart';

const _withArt = [
  'eiffel_tower',
  'statue_of_liberty',
  'mount_fuji',
  'taj_mahal',
  'big_ben',
  'gwanghwamun',
  'taroko_gorge',
  'alhambra',
  'iguazu_falls',
  'neuschwanstein',
  'ha_long_bay',
  'ayutthaya',
  'bali_rice_terraces',
];
const _scenes = ['approach_far', 'approach_mid', 'approach_close', 'poster'];

WorldTourMission _mission({
  String landmarkId = 'eiffel_tower',
  double target = 3,
  double progress = 0,
  bool completed = false,
}) =>
    WorldTourMission(
      missionId: 'm-$landmarkId',
      title: 't',
      countryCode: 'FR',
      landmarkId: landmarkId,
      targetKm: target,
      order: 1,
      progressKm: progress,
      completed: completed,
    );

void main() {
  group('landmark pictures are packaged', () {
    final expected = [
      for (final id in _withArt)
        for (final s in _scenes) 'assets/images/world_tour/${id}_$s.webp',
    ];

    test('52 paths come from the landmark ids and scenes', () {
      final built = <String>[
        for (final id in _withArt)
          for (final scene in WorldTourArtScene.values)
            WorldTourLandmark.of(id).artAsset(scene)!,
      ];
      expect(built.toSet(), expected.toSet());
      expect(built.length, 52);
    });

    test('unknown landmarks have no picture', () {
      for (final id in ['', 'nowhere']) {
        final landmark = WorldTourLandmark.of(id);
        expect(landmark.hasArt, isFalse, reason: id);
        expect(landmark.artAsset(WorldTourArtScene.poster), isNull);
      }
    });

    testWidgets('all 52 files are in the AssetManifest', (tester) async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final listed = manifest.listAssets().toSet();
      for (final path in expected) {
        expect(listed, contains(path));
      }
    });

    test('all 52 files are real WebP files', () {
      for (final path in expected) {
        final bytes = File(path).readAsBytesSync();
        expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF', reason: path);
        expect(ascii.decode(bytes.sublist(8, 12)), 'WEBP', reason: path);
      }
    });
  });

  group('scene choice', () {
    test('not started: far', () {
      expect(WorldTourArtScene.forMission(_mission()), WorldTourArtScene.far);
    });

    test('under a third of the way: far', () {
      expect(
        WorldTourArtScene.forMission(_mission(progress: 0.9)),
        WorldTourArtScene.far,
      );
    });

    test('a third or more but not finished: mid', () {
      expect(
        WorldTourArtScene.forMission(_mission(progress: 1.0)),
        WorldTourArtScene.mid,
      );
      expect(
        WorldTourArtScene.forMission(_mission(progress: 2.9)),
        WorldTourArtScene.mid,
      );
    });

    test('finished: close', () {
      expect(
        WorldTourArtScene.forMission(_mission(progress: 3, completed: true)),
        WorldTourArtScene.close,
      );
    });
  });

  group('WorldTourLandmarkArt', () {
    Future<void> pump(
      WidgetTester tester,
      String landmarkId,
      WorldTourArtScene scene, {
      bool dimmed = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldTourLandmarkArt(
              landmark: WorldTourLandmark.of(landmarkId),
              scene: scene,
              height: 110,
              radius: 16,
              dimmed: dimmed,
            ),
          ),
        ),
      );
    }

    for (final id in _withArt) {
      testWidgets('$id shows its picture, not the icon', (tester) async {
        await pump(tester, id, WorldTourArtScene.close);
        final image = tester.widget<Image>(find.byType(Image));
        expect((image.image as AssetImage).assetName,
            'assets/images/world_tour/${id}_approach_close.webp');
        expect(image.fit, BoxFit.cover);
        expect(find.byIcon(WorldTourLandmark.of(id).icon), findsNothing);
        expect(tester.getSize(find.byType(WorldTourLandmarkArt)).height, 110);
      });
    }

    testWidgets('the poster scene uses the poster file', (tester) async {
      await pump(tester, 'mount_fuji', WorldTourArtScene.poster);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName,
          'assets/images/world_tour/mount_fuji_poster.webp');
    });

    testWidgets('dimmed lowers the picture opacity', (tester) async {
      await pump(tester, 'eiffel_tower', WorldTourArtScene.far, dimmed: true);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.45);
      await pump(tester, 'eiffel_tower', WorldTourArtScene.far);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });

    for (final id in ['']) {
      testWidgets('"$id" keeps the colour + icon placeholder', (tester) async {
        await pump(tester, id, WorldTourArtScene.close);
        expect(find.byType(Image), findsNothing);
        expect(find.byIcon(WorldTourLandmark.of(id).icon), findsOneWidget);
      });
    }

    testWidgets('a picture that fails to load falls back to the placeholder',
        (tester) async {
      // Stand-in landmark with an id that claims art but no asset exists:
      // the error builder must show the icon instead of a broken image.
      const ghost = _GhostLandmark();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorldTourLandmarkArt(landmark: ghost, height: 110),
          ),
        ),
      );
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      expect(find.byIcon(Icons.public), findsOneWidget);
    });
  });

  group('screens use the pictures', () {
    String assetOf(WidgetTester tester, Finder f) {
      final image = tester
          .widget<Image>(find.descendant(of: f, matching: find.byType(Image)));
      return (image.image as AssetImage).assetName;
    }

    testWidgets('mission list: Eiffel and Taj cards show the far scene',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(tourApp(
        home: const WorldTourListScreen(),
        api: FakeWorldTourApi(me: meJson()),
      ));
      await tester.pumpAndSettle();

      final eiffel = find.byKey(WorldTourMissionCard.cardKey('france_eiffel'));
      expect(assetOf(tester, eiffel),
          'assets/images/world_tour/eiffel_tower_approach_far.webp');
      final taj = find.byKey(WorldTourMissionCard.cardKey('india_taj'));
      expect(assetOf(tester, taj),
          'assets/images/world_tour/taj_mahal_approach_far.webp');
    });

    testWidgets('mission list: a finished card shows the close scene',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(tourApp(
        home: const WorldTourListScreen(),
        api: FakeWorldTourApi(me: meJson(done: {'france_eiffel'})),
      ));
      await tester.pumpAndSettle();

      expect(
        assetOf(
            tester, find.byKey(WorldTourMissionCard.cardKey('france_eiffel'))),
        'assets/images/world_tour/eiffel_tower_approach_close.webp',
      );
    });

    testWidgets('arrival card background is the poster', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(tourApp(
        home: const WorldTourArrivalScreen(
          args: WorldTourArrivalArgs(
            missionId: 'france_eiffel',
            landmarkId: 'eiffel_tower',
            distanceKm: 3.02,
            durationSeconds: 1450,
            stampId: 'stamp-france_eiffel',
          ),
        ),
        api: FakeWorldTourApi(me: meJson(done: {'france_eiffel'})),
      ));
      await tester.pumpAndSettle();

      expect(
        assetOf(tester, find.byType(WorldTourLandmarkArt)),
        'assets/images/world_tour/eiffel_tower_poster.webp',
      );
    });
  });
}

/// Claims art (via a subclass override) for a path that is not packaged.
class _GhostLandmark extends WorldTourLandmark {
  const _GhostLandmark()
      : super(id: 'ghost', icon: Icons.public, color: Colors.grey);

  @override
  bool get hasArt => true;

  @override
  String? artAsset(WorldTourArtScene scene) =>
      'assets/images/world_tour/ghost_${scene.fileSuffix}.webp';
}
