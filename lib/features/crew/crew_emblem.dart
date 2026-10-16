import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../shop/widgets/store_look.dart';

/// 크루 엠블럼: 모양(아이콘) 하나와 색 하나. 서버에는 `모양:색` 한 줄로 저장한다.
@immutable
class CrewEmblem {
  const CrewEmblem(this.icon, this.color);

  final String icon;
  final String color;

  static const fallback = CrewEmblem('moon', 'lime');

  /// 서버와 같은 규칙(아이콘 44개 + 그림 문양 30개, 색 6개). 목록에 없으면 null.
  static CrewEmblem? parse(String? code) {
    if (code == null) return null;
    final parts = code.split(':');
    if (parts.length != 2) return null;
    if (!(icons.containsKey(parts[0]) || glyphIds.contains(parts[0])) ||
        !colors.containsKey(parts[1])) {
      return null;
    }
    return CrewEmblem(parts[0], parts[1]);
  }

  String get code => '$icon:$color';
  bool get isGlyph => icon.startsWith(glyphPrefix);
  IconData? get iconData => icons[icon];

  /// 그림 문양(`g_wolf` 같은 코드)의 PNG 경로. 흰색 원본에 색을 입혀 쓴다.
  String get glyphAsset => glyphAssetOf(icon);

  static const glyphPrefix = 'g_';

  static String glyphAssetOf(String id) =>
      'assets/images/crew_glyphs/glyph-${id.substring(glyphPrefix.length).replaceAll('_', '-')}.png';

  /// 새로 더한 그림 문양 30개. 서버 목록과 같아야 한다.
  static const glyphIds = <String>{
    'g_bolt',
    'g_cheetah',
    'g_chevrons',
    'g_city',
    'g_clock',
    'g_compass',
    'g_crown',
    'g_droplet',
    'g_ecg',
    'g_flag',
    'g_flame',
    'g_footprints',
    'g_hands',
    'g_heart',
    'g_horse',
    'g_infinity',
    'g_laurel',
    'g_maltese',
    'g_map_pin',
    'g_mountain',
    'g_shoe',
    'g_sprout',
    'g_star',
    'g_sun',
    'g_tree',
    'g_trophy',
    'g_turtle',
    'g_wave',
    'g_wings',
    'g_wolf',
  };
  Color get colorValue => colors[color]!;

  @override
  bool operator ==(Object other) =>
      other is CrewEmblem && other.icon == icon && other.color == color;

  @override
  int get hashCode => Object.hash(icon, color);

  static const icons = <String, IconData>{
    'moon': Icons.nightlight_round,
    'bolt': Icons.bolt_rounded,
    'fire': Icons.local_fire_department_rounded,
    'star': Icons.star_rounded,
    'heart': Icons.favorite_rounded,
    'shield': Icons.shield_rounded,
    'sun': Icons.wb_sunny_rounded,
    'rocket': Icons.rocket_launch_rounded,
    'paw': Icons.pets_rounded,
    'crown': Icons.workspace_premium_rounded,
    'leaf': Icons.eco_rounded,
    'wave': Icons.waves_rounded,
    'peak': Icons.terrain_rounded,
    'anchor': Icons.anchor_rounded,
    'flag': Icons.flag_rounded,
    'diamond': Icons.diamond_rounded,
    'trophy': Icons.emoji_events_rounded,
    'run': Icons.directions_run_rounded,
    'lotus': Icons.spa_rounded,
    'snow': Icons.ac_unit_rounded,
    'wing': Icons.flight_rounded,
    'bike': Icons.directions_bike_rounded,
    'sail': Icons.sailing_rounded,
    'target': Icons.adjust_rounded,
    'walk': Icons.directions_walk_rounded,
    'hike': Icons.hiking_rounded,
    'swim': Icons.pool_rounded,
    'speed': Icons.speed_rounded,
    'timer': Icons.timer_rounded,
    'dumbbell': Icons.fitness_center_rounded,
    'ball': Icons.sports_soccer_rounded,
    'hoops': Icons.sports_basketball_rounded,
    'tennis': Icons.sports_tennis_rounded,
    'skate': Icons.skateboarding_rounded,
    'tree': Icons.park_rounded,
    'drop': Icons.water_drop_rounded,
    'flower': Icons.local_florist_rounded,
    'cloud': Icons.cloud_rounded,
    'globe': Icons.public_rounded,
    'medal': Icons.military_tech_rounded,
    'spark': Icons.auto_awesome_rounded,
    'bird': Icons.flutter_dash_rounded,
    'bunny': Icons.cruelty_free_rounded,
    'bee': Icons.emoji_nature_rounded,
  };

  /// 고르는 창에서 묶어 보여 주는 순서. 모양 44개가 빠짐없이 한 번씩 들어 있다.
  static const groups = <String, List<String>>{
    '달리기 · 운동': [
      'run',
      'walk',
      'hike',
      'bike',
      'swim',
      'speed',
      'timer',
      'dumbbell',
      'ball',
      'hoops',
      'tennis',
      'skate',
      'trophy',
      'medal',
      'flag',
      'target',
    ],
    '자연': [
      'moon',
      'sun',
      'snow',
      'cloud',
      'drop',
      'wave',
      'fire',
      'bolt',
      'leaf',
      'tree',
      'flower',
      'lotus',
      'peak',
    ],
    '상징': [
      'star',
      'heart',
      'shield',
      'crown',
      'diamond',
      'spark',
      'globe',
      'anchor',
      'sail',
      'rocket',
      'wing',
    ],
    '동물': ['paw', 'bird', 'bunny', 'bee'],
    '그림 문양': [
      'g_bolt',
      'g_cheetah',
      'g_chevrons',
      'g_city',
      'g_clock',
      'g_compass',
      'g_crown',
      'g_droplet',
      'g_ecg',
      'g_flag',
      'g_flame',
      'g_footprints',
      'g_hands',
      'g_heart',
      'g_horse',
      'g_infinity',
      'g_laurel',
      'g_maltese',
      'g_map_pin',
      'g_mountain',
      'g_shoe',
      'g_sprout',
      'g_star',
      'g_sun',
      'g_tree',
      'g_trophy',
      'g_turtle',
      'g_wave',
      'g_wings',
      'g_wolf',
    ],
  };

  static const colors = <String, Color>{
    'lime': Color(0xFFD4FF4A),
    'gold': Color(0xFFE8B84B),
    'sky': Color(0xFF5BC8FF),
    'pink': Color(0xFFFF86A0),
    'violet': Color(0xFFB28CFF),
    'white': Color(0xFFE8EFE6),
  };
}

/// 모양 하나. 아이콘이면 글꼴 아이콘, `g_` 문양이면 PNG에 색을 입혀 그린다.
class CrewEmblemMark extends StatelessWidget {
  const CrewEmblemMark({
    required this.id,
    required this.color,
    required this.size,
    super.key,
  });

  final String id;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (id.startsWith(CrewEmblem.glyphPrefix)) {
      return Image.asset(
        CrewEmblem.glyphAssetOf(id),
        width: size,
        height: size,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.medium,
      );
    }
    return Icon(CrewEmblem.icons[id], color: color, size: size);
  }
}

/// 동그란 엠블럼. 어두운 바탕에 색 테두리와 같은 색 모양.
class CrewEmblemBadge extends StatelessWidget {
  const CrewEmblemBadge({required this.emblem, this.size = 48, super.key});

  final CrewEmblem emblem;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: emblem.colorValue, width: size >= 72 ? 3 : 2),
      ),
      alignment: Alignment.center,
      child: CrewEmblemMark(
        id: emblem.icon,
        color: emblem.colorValue,
        size: size * 0.5,
      ),
    );
  }
}

const _prefsKey = 'crew_emblem_v1';

/// 내 크루의 엠블럼. 폰에 저장해 두고, 크루를 만들 때 서버로도 보낸다.
class CrewEmblemNotifier extends Notifier<CrewEmblem> {
  @override
  CrewEmblem build() {
    _load();
    return CrewEmblem.fallback;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = CrewEmblem.parse(prefs.getString(_prefsKey));
      if (saved != null && ref.mounted) state = saved;
    } catch (_) {
      // 저장소를 못 읽으면 기본 엠블럼을 쓴다.
    }
  }

  Future<void> choose(CrewEmblem emblem) async {
    state = emblem;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, emblem.code);
    } catch (_) {}
  }
}

final crewEmblemProvider =
    NotifierProvider<CrewEmblemNotifier, CrewEmblem>(CrewEmblemNotifier.new);

/// 엠블럼 고르는 시트. 고르면 [CrewEmblem], 닫으면 null.
class CrewEmblemPicker extends StatefulWidget {
  const CrewEmblemPicker({required this.initial, super.key});

  final CrewEmblem initial;

  static const doneKey = Key('crew-emblem-done');
  static Key iconKey(String id) => Key('crew-emblem-icon-$id');
  static Key colorKey(String id) => Key('crew-emblem-color-$id');

  static Future<CrewEmblem?> show(BuildContext context, CrewEmblem initial) {
    return showModalBottomSheet<CrewEmblem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.srcTokens.colors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CrewEmblemPicker(initial: initial),
    );
  }

  @override
  State<CrewEmblemPicker> createState() => _CrewEmblemPickerState();
}

class _CrewEmblemPickerState extends State<CrewEmblemPicker> {
  late String _icon = widget.initial.icon;
  late String _color = widget.initial.color;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final emblem = CrewEmblem(_icon, _color);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const StoreTag('EMBLEM'),
            const SizedBox(height: 6),
            Text('크루 엠블럼 고르기', style: storeText(24, c.ink, w: FontWeight.w900)),
            const SizedBox(height: 18),
            Center(child: CrewEmblemBadge(emblem: emblem, size: 88)),
            const SizedBox(height: 20),
            for (final group in CrewEmblem.groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  group.key,
                  style: storeText(13, c.muted, w: FontWeight.w800),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final id in group.value)
                    InkWell(
                      key: CrewEmblemPicker.iconKey(id),
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _icon = id),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface,
                          border: Border.all(
                            color: id == _icon ? emblem.colorValue : c.outline,
                            width: id == _icon ? 2.5 : 1,
                          ),
                        ),
                        child: CrewEmblemMark(
                          id: id,
                          color: id == _icon ? emblem.colorValue : c.muted,
                          size: id.startsWith(CrewEmblem.glyphPrefix) ? 28 : 24,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final id in CrewEmblem.colors.keys)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: InkWell(
                      key: CrewEmblemPicker.colorKey(id),
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = id),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: CrewEmblem.colors[id],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: id == _color ? c.ink : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            StorePillButton(
              key: CrewEmblemPicker.doneKey,
              label: '이 엠블럼으로 정하기',
              onPressed: () => Navigator.of(context).pop(emblem),
            ),
          ],
        ),
      ),
    );
  }
}
