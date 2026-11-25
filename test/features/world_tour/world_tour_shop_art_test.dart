import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/profile/village_backgrounds.dart';
import 'package:share_run_challenge/features/world_tour/screens/world_tour_screens.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_shop_art.dart';

import 'world_tour_support.dart';

void main() {
  test('32 paths are named: 2 passport, 5 stamps, 15 shop, 10 costumes', () {
    expect(WorldTourShopArt.allPaths.length, 2 + 5 + 15 + 10);
    expect(WorldTourShopArt.allPaths.toSet().length, 32);
  });

  test('every named path is a real WebP file', () {
    for (final path in WorldTourShopArt.allPaths) {
      final bytes = File(path).readAsBytesSync();
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF', reason: path);
      expect(ascii.decode(bytes.sublist(8, 12)), 'WEBP', reason: path);
    }
  });

  testWidgets('every named path is in the AssetManifest', (tester) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final listed = manifest.listAssets().toSet();
    for (final path in [
      ...WorldTourShopArt.allPaths,
      ...VillageBackgrounds.worldTour.values,
    ]) {
      expect(listed, contains(path));
    }
  });

  test('the old Egypt and Pyramids pictures are gone', () {
    for (final path in [
      'assets/images/world_tour/shop/pyramids_accessory.webp',
      'assets/images/world_tour/shop/pyramids_village.webp',
      'assets/images/world_tour/shop/pyramids_passport_cover.webp',
      'assets/images/world_tour/passport/stamp_pyramids.webp',
      'assets/images/world_tour/pyramids_poster.webp',
      'assets/images/characters/costume/wt-egypt-male.webp',
      'assets/images/characters/costume/wt-egypt-female.webp',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('landmarks without a picture get none, so no missing file', () {
    expect(WorldTourShopArt.stamp('big_ben'), isNotNull);
    expect(WorldTourShopArt.stamp('gwanghwamun'), isNull);
    expect(WorldTourShopArt.stamp('pyramids'), isNull);
    expect(WorldTourShopArt.village('alhambra'), isNull);
    expect(WorldTourShopArt.costume('big_ben', 'female'),
        'assets/images/characters/costume/wt-uk-female.webp');
    expect(WorldTourShopArt.costume('big_ben', 'other'), isNull);
    expect(WorldTourShopArt.costume('ha_long_bay', 'male'), isNull);
  });

  test('village backgrounds match the shop village files', () {
    expect(VillageBackgrounds.worldTour.keys.toSet(), WorldTourShopArt.shopIds);
    for (final entry in VillageBackgrounds.worldTour.entries) {
      expect(entry.value, WorldTourShopArt.village(entry.key));
    }
  });

  group('passport', () {
    Future<void> pumpPassport(WidgetTester tester, Set<String> done) async {
      await tester.binding.setSurfaceSize(const Size(800, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(tourApp(
        home: const WorldTourPassportScreen(),
        api: FakeWorldTourApi(me: meJson(done: done)),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('a stamped landmark with art shows its stamp picture',
        (tester) async {
      await pumpPassport(tester, {'uk_big_ben', 'france_eiffel'});

      final big = find.byKey(WorldTourPassportScreen.stampedKey('uk_big_ben'));
      expect(big, findsOneWidget);
      expect(
        find.descendant(of: big, matching: find.byType(Image)),
        findsOneWidget,
      );
    });

    testWidgets('a stamped landmark without art keeps the check mark',
        (tester) async {
      await pumpPassport(tester, {'korea_gwanghwamun'});

      final slot =
          find.byKey(WorldTourPassportScreen.stampedKey('korea_gwanghwamun'));
      expect(slot, findsOneWidget);
      expect(find.descendant(of: slot, matching: find.byType(Image)),
          findsNothing);
      expect(find.descendant(of: slot, matching: find.byIcon(Icons.verified)),
          findsOneWidget);
    });
  });
}
