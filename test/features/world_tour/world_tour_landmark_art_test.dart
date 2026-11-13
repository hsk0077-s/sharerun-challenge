import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_landmarks.dart';

import 'world_tour_support.dart';

/// Mission id -> landmark id -> picture, exactly as the server's five missions.
const _expected = {
  'france_eiffel': ('eiffel_tower', 'landmark_eiffel.png'),
  'india_taj': ('taj_mahal', 'landmark_tajmahal.png'),
  'japan_fuji': ('mount_fuji', 'landmark_fuji.png'),
  'egypt_pyramids': ('pyramids', 'landmark_pyramids.png'),
  'usa_liberty': ('statue_of_liberty', 'landmark_liberty.png'),
};

Widget _box(WorldTourLandmark landmark,
    {double width = 330, double height = 110, bool dimmed = false}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: WorldTourLandmarkArt(
            landmark: landmark,
            height: double.infinity,
            dimmed: dimmed,
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('each server mission shows its own illustration', () {
    final missions = {
      for (final m in meJson()['missions'] as List)
        (m as Map)['mission_id'] as String: m['landmark_id'] as String,
    };
    expect(missions.keys.toSet(), _expected.keys.toSet());
    for (final entry in _expected.entries) {
      final landmarkId = missions[entry.key]!;
      expect(landmarkId, entry.value.$1);
      expect(WorldTourLandmark.of(landmarkId).asset,
          'assets/images/world_tour/${entry.value.$2}');
    }
  });

  test('the five illustration files exist, are under 1 MB and are registered', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/images/world_tour/'));
    for (final landmark in WorldTourLandmark.all) {
      final file = File(landmark.asset!);
      expect(file.existsSync(), isTrue, reason: landmark.asset);
      expect(file.lengthSync(), lessThan(1024 * 1024), reason: landmark.asset);
      expect(landmark.asset, startsWith('assets/images/world_tour/'));
    }
    expect(WorldTourLandmark.all.map((l) => l.asset).toSet(), hasLength(5));
  });

  testWidgets('a wide card shows the whole picture on the matching backdrop',
      (tester) async {
    await tester.pumpWidget(_box(WorldTourLandmark.eiffel));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    expect((image.image as AssetImage).assetName,
        'assets/images/world_tour/landmark_eiffel.png');
    expect(find.byType(ClipRRect), findsOneWidget);
    final box = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(WorldTourLandmarkArt),
      matching: find.byType(DecoratedBox),
    ));
    final gradient = (box.decoration as BoxDecoration).gradient as LinearGradient;
    expect(gradient.colors, const [
      WorldTourLandmarkArt.backdropTop,
      WorldTourLandmarkArt.backdropBottom,
    ]);
  });

  testWidgets('a tall tile fills the card and trims the sides', (tester) async {
    await tester.pumpWidget(_box(WorldTourLandmark.fuji, width: 160, height: 300));
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
  });

  testWidgets('every illustration decodes (no fallback icon)', (tester) async {
    for (final landmark in WorldTourLandmark.all) {
      await tester.pumpWidget(_box(landmark));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(WorldTourLandmarkArt));
        await precacheImage(AssetImage(landmark.asset!), context);
      });
      await tester.pump();
      expect(find.byIcon(landmark.icon), findsNothing, reason: landmark.id);
    }
  });

  testWidgets('a landmark without an illustration keeps the colour and icon',
      (tester) async {
    await tester.pumpWidget(_box(WorldTourLandmark.unknown));
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.public), findsOneWidget);
  });

  testWidgets('a finished mission is shown dimmed', (tester) async {
    await tester.pumpWidget(_box(WorldTourLandmark.taj, dimmed: true));
    final opacity = tester.widget<Opacity>(find.descendant(
      of: find.byType(WorldTourLandmarkArt),
      matching: find.byType(Opacity),
    ));
    expect(opacity.opacity, lessThan(1));
  });
}
