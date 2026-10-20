import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../shop/widgets/store_look.dart';

/// 마이 탭 맨 위 마을 배경. 그림은 `assets/images/villages/` 에 `village-<이름>.jpg` 로 넣고,
/// 고르는 창에 쓰는 작은 그림은 `thumbs/village-<이름>-thumb.jpg` 로 넣는다.
/// 새 그림을 넣으면 코드를 고치지 않아도 목록에 올라온다(이름만 아래 표에 없으면 "마을 N").
/// 마지막에는 항상 코드로 그린 기본 풍경이 있다.
@immutable
class VillageScene {
  const VillageScene({
    required this.id,
    required this.nameKo,
    this.asset,
    this.thumb,
  });

  final String id;
  final String nameKo;

  /// null 이면 코드로 그린 기본 풍경.
  final String? asset;

  /// 고르는 창에서 쓰는 작은 그림. 없으면 [asset]을 줄여서 쓴다.
  final String? thumb;
}

/// 코드로 그린 풍경. 그림 파일이 하나도 없을 때의 바탕이기도 하다.
const defaultVillageScene = VillageScene(id: 'default', nameKo: '기본 마을');

/// 처음 보이는 마을(디자인 문서의 "무료 기본"). 그림이 없으면 코드로 그린 풍경.
const startVillageId = 'spring-park';

const villageAssetDir = 'assets/images/villages/';
const villageThumbDir = 'assets/images/villages/thumbs/';

const _imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

/// 디자인 문서 순서와 한글 이름.
const _knownVillages = <String, String>{
  'spring-park': '봄 공원',
  'seaside': '바닷가',
  'night-city': '밤 도시',
  'snow-village': '눈 마을',
  'autumn-forest': '가을 숲',
  'festival': '축제의 밤',
  'aurora-lake': '오로라 호수',
  'sky-island': '하늘섬',
};

bool _isImage(String key) => _imageExtensions.any(key.toLowerCase().endsWith);

String _stem(String key, String dir) {
  final name = key.substring(dir.length);
  final dot = name.lastIndexOf('.');
  var stem = dot < 0 ? name : name.substring(0, dot);
  if (stem.startsWith('village-')) stem = stem.substring('village-'.length);
  return stem;
}

/// 에셋 목록에서 마을 그림만 골라 장면 목록을 만든다.
/// 아는 마을은 문서 순서대로, 모르는 마을은 이름순으로 뒤에 붙고, 맨 끝은 기본 풍경이다.
List<VillageScene> villageScenesFromAssets(Iterable<String> assetKeys) {
  final keys = assetKeys.toList();
  final full = <String, String>{}; // id -> 큰 그림
  for (final key in keys) {
    if (!key.startsWith(villageAssetDir) || !_isImage(key)) continue;
    final rest = key.substring(villageAssetDir.length);
    if (rest.contains('/')) continue; // thumbs/ 같은 아래 폴더는 건너뛴다
    full[_stem(key, villageAssetDir)] = key;
  }
  final thumbs = <String, String>{};
  for (final key in keys) {
    if (!key.startsWith(villageThumbDir) || !_isImage(key)) continue;
    var id = _stem(key, villageThumbDir);
    if (id.endsWith('-thumb'))
      id = id.substring(0, id.length - '-thumb'.length);
    thumbs[id] = key;
  }
  final known = [
    for (final id in _knownVillages.keys)
      if (full.containsKey(id)) id,
  ];
  final others = [
    for (final id in full.keys)
      if (!_knownVillages.containsKey(id)) id,
  ]..sort();
  var extra = 0;
  return [
    for (final id in known)
      VillageScene(
        id: id,
        nameKo: _knownVillages[id]!,
        asset: full[id],
        thumb: thumbs[id],
      ),
    for (final id in others)
      VillageScene(
        id: id,
        nameKo: '마을 ${++extra}',
        asset: full[id],
        thumb: thumbs[id],
      ),
    defaultVillageScene,
  ];
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

/// 사용자가 고른 마을 id. 아직 안 골랐으면 빈 문자열. 이 폰에만 저장한다.
class VillageSceneIdNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return '';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && ref.mounted) state = saved;
    } catch (_) {
      // 저장소를 못 읽으면 처음 마을을 쓴다.
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

/// 지금 보여 줄 마을. 고른 적이 없거나 고른 그림이 없어졌으면 처음 마을(봄 공원),
/// 그것도 없으면 코드로 그린 기본 풍경.
final villageSceneProvider = Provider<VillageScene>((ref) {
  final id = ref.watch(villageSceneIdProvider);
  final scenes = ref.watch(villageScenesProvider).asData?.value ??
      const [defaultVillageScene];
  for (final wanted in [id, startVillageId]) {
    for (final scene in scenes) {
      if (scene.id == wanted) return scene;
    }
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
                      scene.thumb ?? scene.asset!,
                      fit: BoxFit.cover,
                      // 마이 화면 위 풍경과 같은 부분(아래쪽 마을)이 보이게 한다.
                      alignment: Alignment.bottomCenter,
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
