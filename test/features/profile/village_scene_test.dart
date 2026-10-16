import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/village_scene.dart';
import 'package:share_run_challenge/features/profile/widgets/my_village_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _scenes = [
  defaultVillageScene,
  VillageScene(
    id: 'village-a',
    nameKo: '마을 1',
    asset: 'assets/images/challenge_track.jpg',
  ),
  VillageScene(
    id: 'village-b',
    nameKo: '마을 2',
    asset: 'assets/images/splash_morning_run.jpg',
  ),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('scene list keeps only images in the village folder, default first', () {
    final scenes = villageScenesFromAssets([
      'assets/images/villages/.gitkeep',
      'assets/images/villages/village-2.jpg',
      'assets/images/villages/village-1.PNG',
      'assets/images/villages/notes.txt',
      'assets/images/other/village-9.jpg',
    ]);
    expect(scenes.map((s) => s.id), ['default', 'village-1', 'village-2']);
    expect(scenes.map((s) => s.nameKo), ['기본 마을', '마을 1', '마을 2']);
    expect(scenes.first.asset, isNull);
  });

  test('no images means only the default village', () {
    final scenes = villageScenesFromAssets(['assets/images/villages/.gitkeep']);
    expect(scenes, [defaultVillageScene]);
  });

  test('choice is saved and a missing village falls back to default', () async {
    final container = ProviderContainer(overrides: [
      villageScenesProvider.overrideWith((ref) async => _scenes),
    ]);
    addTearDown(container.dispose);
    await container.read(villageScenesProvider.future);

    await container.read(villageSceneIdProvider.notifier).choose('village-b');
    expect(container.read(villageSceneProvider).id, 'village-b');
    expect(
        (await SharedPreferences.getInstance()).getString('village_scene_v1'),
        'village-b');

    await container.read(villageSceneIdProvider.notifier).choose('gone');
    expect(container.read(villageSceneProvider), defaultVillageScene);
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
    expect(find.byKey(const Key('my-village-bg-village-b')), findsNothing);

    await tester.tap(find.byKey(const Key('my-village-change')));
    await tester.pumpAndSettle();
    for (final s in _scenes) {
      expect(find.byKey(VillagePicker.sceneKey(s.id)), findsOneWidget);
    }

    await tester.tap(find.byKey(VillagePicker.sceneKey('village-b')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-village-bg-village-b')), findsOneWidget);
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
