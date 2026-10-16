import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../shop/widgets/store_look.dart';

/// 마이 탭 맨 위 마을 배경. 기본은 코드로 그린 풍경이고,
/// `assets/images/villages/` 에 그림 파일을 넣으면 자동으로 고를 수 있는 목록에 올라온다.
@immutable
class VillageScene {
  const VillageScene({required this.id, required this.nameKo, this.asset});

  final String id;
  final String nameKo;

  /// null 이면 코드로 그린 기본 풍경.
  final String? asset;
}

const defaultVillageScene = VillageScene(id: 'default', nameKo: '기본 마을');

const villageAssetDir = 'assets/images/villages/';

const _imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

/// 에셋 목록에서 마을 그림만 골라 이름순으로 장면 목록을 만든다. 맨 앞은 항상 기본 마을.
List<VillageScene> villageScenesFromAssets(Iterable<String> assetKeys) {
  final files = [
    for (final key in assetKeys)
      if (key.startsWith(villageAssetDir) &&
          _imageExtensions.any(key.toLowerCase().endsWith))
        key,
  ]..sort();
  return [
    defaultVillageScene,
    for (var i = 0; i < files.length; i++)
      VillageScene(
        id: _idOf(files[i]),
        nameKo: '마을 ${i + 1}',
        asset: files[i],
      ),
  ];
}

String _idOf(String key) {
  final name = key.substring(villageAssetDir.length);
  final dot = name.lastIndexOf('.');
  return dot < 0 ? name : name.substring(0, dot);
}

final villageScenesProvider = FutureProvider<List<VillageScene>>((ref) async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return villageScenesFromAssets(manifest.listAssets());
  } catch (_) {
    return const [defaultVillageScene];
  }
});

const _prefsKey = 'village_scene_v1';

/// 고른 마을의 id. 이 폰에만 저장한다.
class VillageSceneIdNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return defaultVillageScene.id;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && ref.mounted) state = saved;
    } catch (_) {
      // 저장소를 못 읽으면 기본 마을을 쓴다.
    }
  }

  Future<void> choose(String id) async {
    state = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, id);
    } catch (_) {}
  }
}

final villageSceneIdProvider = NotifierProvider<VillageSceneIdNotifier, String>(
    VillageSceneIdNotifier.new);

/// 지금 보여 줄 마을. 고른 그림이 없어졌으면 기본 마을로 돌아간다.
final villageSceneProvider = Provider<VillageScene>((ref) {
  final id = ref.watch(villageSceneIdProvider);
  final scenes = ref.watch(villageScenesProvider).asData?.value ??
      const [defaultVillageScene];
  for (final scene in scenes) {
    if (scene.id == id) return scene;
  }
  return defaultVillageScene;
});

/// 마을을 고르는 아래 창.
class VillagePicker extends ConsumerWidget {
  const VillagePicker({super.key});

  static Key sceneKey(String id) => Key('village-scene-$id');

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.srcTokens.colors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const VillagePicker(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.srcTokens.colors;
    final scenes = ref.watch(villageScenesProvider).asData?.value ??
        const [defaultVillageScene];
    final current = ref.watch(villageSceneProvider).id;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const StoreTag('VILLAGE'),
            const SizedBox(height: 6),
            Text('마을 고르기', style: storeText(24, c.ink, w: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              scenes.length > 1
                  ? '마이 화면 맨 위 배경이 바뀌어요.'
                  : '아직 고를 수 있는 마을이 기본 하나뿐이에요.',
              style: storeText(13, c.muted),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final scene in scenes)
                      _SceneTile(
                        scene: scene,
                        selected: scene.id == current,
                        onTap: () {
                          ref
                              .read(villageSceneIdProvider.notifier)
                              .choose(scene.id);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({
    required this.scene,
    required this.selected,
    required this.onTap,
  });

  final VillageScene scene;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final width = (MediaQuery.sizeOf(context).width - 40 - 12) / 2;
    return InkWell(
      key: VillagePicker.sceneKey(scene.id),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: width * 0.62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? c.primary : c.outline,
                  width: selected ? 2.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: scene.asset == null
                  ? const _DefaultThumb()
                  : Image.asset(
                      scene.asset!,
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              scene.nameKo,
              style: storeText(
                14,
                selected ? c.primary : c.ink,
                w: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultThumb extends StatelessWidget {
  const _DefaultThumb();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFE4FF), Color(0xFFE3F6E6)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}
