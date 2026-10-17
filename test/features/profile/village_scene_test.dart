import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/village_scene.dart';
import 'package:share_run_challenge/features/profile/widgets/my_village_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _scenes = [
  VillageScene(
    id: 'spring-park',
    nameKo: '봄 공원',
    asset: 'assets/images/challenge_track.jpg',
  ),
  VillageScene(
    id: 'seaside',
    nameKo: '바닷가',
    asset: 'assets/images/splash_morning_run.jpg',
  ),
  defaultVillageScene,
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('scene list: known villages in design order, then others, default last',
      () {
    final scenes = villageScenesFromAssets([
      'assets/images/villages/.gitkeep',
      'assets/images/villages/village-seaside.jpg',
      'assets/images/villages/village-spring-park.jpg',
      'assets/images/villages/village-zzz.jpg',
      'assets/images/villages/village-aaa.png',
      'assets/images/villages/thumbs/village-seaside-thumb.jpg',
      'assets/images/villages/notes.txt',
      'assets/images/other/village-9.jpg',
    ]);
    expect(scenes.map((s) => s.id),
        ['spring-park', 'seaside', 'aaa', 'zzz', 'default']);
    expect(
        scenes.map((s) => s.nameKo), ['봄 공원', '바닷가', '마을 1', '마을 2', '기본 마을']);
    expect(scenes[1].thumb,
        'assets/images/villages/thumbs/village-seaside-thumb.jpg');
    expect(scenes[0].thumb, isNull);
    expect(scenes.last.asset, isNull);
  });

  test('every shipped village image is found with its thumbnail', () {
    final dir = Directory('assets/images/villages');
    final keys = [
      for (final f in dir.listSync(recursive: true))
        if (f is File) f.path.replaceAll('\\', '/'),
    ];
    final scenes = villageScenesFromAssets(keys);
    expect(scenes.length, 9);
    for (final s in scenes.where((s) => s.asset != null)) {
      expect(File(s.asset!).existsSync(), isTrue, reason: s.id);
      expect(s.thumb, isNotNull, reason: s.id);
      expect(File(s.thumb!).existsSync(), isTrue, reason: s.id);
    }
    expect(scenes.first.id, startVillageId);
  });

  test('no images means only the default village', () {
    final scenes = villageScenesFromAssets(['assets/images/villages/.gitkeep']);
    expect(scenes, [defaultVillageScene]);
  });

  test('nothing chosen starts at spring park; a lost choice falls back',
      () async {
    final container = ProviderContainer(overrides: [
      villageScenesProvider.overrideWith((ref) async => _scenes),
    ]);
    addTearDown(container.dispose);
    await container.read(villageScenesProvider.future);
    expect(container.read(villageSceneProvider).id, 'spring-park');

    await container.read(villageSceneIdProvider.notifier).choose('seaside');
    expect(container.read(villageSceneProvider).id, 'seaside');
    expect(
        (await SharedPreferences.getInstance()).getString('village_scene_v1'),
        'seaside');

    await container.read(villageSceneIdProvider.notifier).choose('gone');
    expect(container.read(villageSceneProvider).id, 'spring-park');
  });

  testWidgets('picker lists every village and choosing one changes the hero',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [villageScenesProvider.overrideWith((ref) async => _scenes)],
        child: MaterialApp(
          theme: SrcTheme.night,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Column(
                children: [
                  MyVillageHero(
                    tier: UserTier.unratedFallback,
                    onSettings: () {},
                    scene: ref.watch(villageSceneProvider),
                    onChangeVillage: () => VillagePicker.show(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-village-bg-seaside')), findsNothing);

    await tester.tap(find.byKey(const Key('my-village-change')));
    await tester.pumpAndSettle();
    for (final s in _scenes) {
      expect(find.byKey(VillagePicker.sceneKey(s.id)), findsOneWidget);
    }

    await tester.tap(find.byKey(VillagePicker.sceneKey('seaside')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-village-bg-seaside')), findsOneWidget);
  });

  testWidgets('hide the change button when no handler is given',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.night,
        home: Scaffold(
          body: MyVillageHero(
            tier: UserTier.unratedFallback,
            onSettings: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('my-village-change')), findsNothing);
  });
}
