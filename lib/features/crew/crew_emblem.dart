import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../shop/widgets/store_look.dart';
import 'crew_emblem_layered.dart';

/// 크루 엠블럼. 두 가지 모양의 코드를 모두 읽는다.
/// - 예전: `모양:색` (아이콘 44개 + 그림 문양 30개, 색 6개). 이미 만든 크루가 그대로 쓴다.
/// - 새 것: `틀:문양:패턴:틀색:문양색` (틀 8 × 문양 30 × 패턴 4+없음 × 색 12).
///   디자인팀 엠블럼 세트 기준이며, 대비 3:1 이상인 색 조합만 허용한다.
@immutable
class CrewEmblem {
  const CrewEmblem(
    this.icon,
    this.color, {
    this.frame,
    this.pattern = 'none',
    this.glyphColor,
  });

  /// 새 엠블럼. [glyph]는 `g_wolf` 같은 그림 문양 코드.
  const CrewEmblem.layered({
    required String this.frame,
    required String glyph,
    this.pattern = 'none',
    required String frameColor,
    required String this.glyphColor,
  })  : icon = glyph,
        color = frameColor;

  /// 문양(새 엠블럼) 또는 모양(예전 엠블럼).
  final String icon;

  /// 틀 색(새 엠블럼) 또는 색(예전 엠블럼).
  final String color;
  final String? frame;
  final String pattern;
  final String? glyphColor;

  static const fallback = CrewEmblem('moon', 'lime');

  /// 새 엠블럼의 기본값.
  static const layeredDefault = CrewEmblem.layered(
    frame: 'shield',
    glyph: 'g_wolf',
    pattern: 'rays',
    frameColor: 'navy',
    glyphColor: 'white',
  );

  bool get isLayered => frame != null;

  /// 서버와 같은 규칙. 목록에 없으면 null.
  static CrewEmblem? parse(String? code) {
    if (code == null) return null;
    final parts = code.split(':');
    if (parts.length == 5) {
      final e = CrewEmblem.layered(
        frame: parts[0],
        glyph: parts[1],
        pattern: parts[2],
        frameColor: parts[3],
        glyphColor: parts[4],
      );
      return e.isValidLayered ? e : null;
    }
    if (parts.length != 2) return null;
    if (!(icons.containsKey(parts[0]) || glyphIds.contains(parts[0])) ||
        !colors.containsKey(parts[1])) {
      return null;
    }
    return CrewEmblem(parts[0], parts[1]);
  }

  bool get isValidLayered =>
      frames.contains(frame) &&
      glyphIds.contains(icon) &&
      patterns.contains(pattern) &&
      allowsGlyphColor(color, glyphColor ?? '');

  String get code => isLayered
      ? '$frame:$icon:$pattern:$color:$glyphColor'
      : '$icon:$color';

  static const frames = <String>[
    'shield',
    'circle',
    'hexagon',
    'pennant',
    'diamond',
    'rounded-square',
    'octagon',
    'seal',
  ];
  static const patterns = <String>['none', 'rays', 'stripes', 'dots', 'chevrons'];

  static String frameAsset(String id) =>
      'assets/images/crew_emblem/frames/frame-$id.png';
  static String patternAsset(String id) =>
      'assets/images/crew_emblem/patterns/pattern-$id.png';

  /// 새 엠블럼의 12색(디자인팀 colors.csv).
  static const paletteColors = <String, Color>{
    'lime': Color(0xFFD4FF4A),
    'gold': Color(0xFFE8B84B),
    'red': Color(0xFFFF6B6B),
    'white': Color(0xFFF7F5EE),
    'orange': Color(0xFFFF9A3C),
    'sky': Color(0xFF5EC8F2),
    'blue': Color(0xFF3D6BFF),
    'purple': Color(0xFF9B6BFF),
    'pink': Color(0xFFFF7EB6),
    'mint': Color(0xFF3DDC97),
    'navy': Color(0xFF1D2B53),
    'charcoal': Color(0xFF2A302C),
  };

  /// 틀 색 × 문양 색 중 대비 3:1 이상인 조합(color-pairs.csv). 서버도 같은 표로 거른다.
  static const allowedPairs = <String, List<String>>{
    'blue': ['charcoal', 'lime', 'navy', 'white'],
    'charcoal': ['blue', 'gold', 'lime', 'mint', 'orange', 'pink', 'purple', 'red', 'sky', 'white'],
    'gold': ['charcoal', 'navy'],
    'lime': ['blue', 'charcoal', 'navy', 'purple'],
    'mint': ['charcoal', 'navy'],
    'navy': ['blue', 'gold', 'lime', 'mint', 'orange', 'pink', 'purple', 'red', 'sky', 'white'],
    'orange': ['charcoal', 'navy'],
    'pink': ['charcoal', 'navy'],
    'purple': ['charcoal', 'lime', 'navy', 'white'],
    'red': ['charcoal', 'navy'],
    'sky': ['charcoal', 'navy'],
    'white': ['blue', 'charcoal', 'navy', 'purple'],
  };

  static bool allowsGlyphColor(String frameColor, String glyphColor) =>
      allowedPairs[frameColor]?.contains(glyphColor) ?? false;
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
  Color get colorValue => isLayered ? paletteColors[color]! : colors[color]!;

  @override
  bool operator ==(Object other) =>
      other is CrewEmblem && other.code == code;

  @override
  int get hashCode => code.hashCode;

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

/// 크루 엠블럼. 새 엠블럼은 틀·패턴·문양을 겹쳐 그리고, 예전 엠블럼은 동그란 바탕에 색 테두리로 그린다.
class CrewEmblemBadge extends StatelessWidget {
  const CrewEmblemBadge({required this.emblem, this.size = 48, super.key});

  final CrewEmblem emblem;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (emblem.isLayered) return CrewEmblemLayered(emblem: emblem, size: size);
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
/// 틀 8 · 문양 30 · 패턴 4(+없음) · 틀 색 12 · 문양 색(대비 3:1 이상인 것만).
class CrewEmblemPicker extends StatefulWidget {
  const CrewEmblemPicker({required this.initial, super.key});

  final CrewEmblem initial;

  static const doneKey = Key('crew-emblem-done');
  static Key frameKey(String id) => Key('crew-emblem-frame-$id');
  static Key iconKey(String id) => Key('crew-emblem-icon-$id');
  static Key patternKey(String id) => Key('crew-emblem-pattern-$id');
  static Key colorKey(String id) => Key('crew-emblem-color-$id');
  static Key glyphColorKey(String id) => Key('crew-emblem-glyph-color-$id');

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
  late String _frame;
  late String _glyph;
  late String _pattern;
  late String _frameColor;
  late String _glyphColor;

  @override
  void initState() {
    super.initState();
    // 예전 엠블럼은 새 기본값에서 시작한다(색·모양이 서로 달라 옮길 수 없다).
    final e = widget.initial.isLayered
        ? widget.initial
        : CrewEmblem.layeredDefault;
    _frame = e.frame!;
    _glyph = e.icon;
    _pattern = e.pattern;
    _frameColor = e.color;
    _glyphColor = e.glyphColor!;
  }

  CrewEmblem get _emblem => CrewEmblem.layered(
        frame: _frame,
        glyph: _glyph,
        pattern: _pattern,
        frameColor: _frameColor,
        glyphColor: _glyphColor,
      );

  void _pickFrameColor(String id) {
    final allowed = CrewEmblem.allowedPairs[id] ?? const <String>[];
    setState(() {
      _frameColor = id;
      if (!allowed.contains(_glyphColor) && allowed.isNotEmpty) {
        _glyphColor = allowed.first;
      }
    });
  }

  Widget _label(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 14),
        child: Text(text, style: storeText(13, color, w: FontWeight.w800)),
      );

  Widget _swatch({
    required Key key,
    required Color fill,
    required bool selected,
    required VoidCallback onTap,
    required Color ring,
  }) {
    return InkWell(
      key: key,
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ring : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required Key key,
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
    double size = 52,
  }) {
    final c = context.srcTokens.colors;
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: c.surface,
          border: Border.all(
            color: selected ? c.primary : c.outline,
            width: selected ? 2.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final emblem = _emblem;
    final allowedGlyphColors =
        CrewEmblem.allowedPairs[_frameColor] ?? const <String>[];
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
            Center(
              child: CrewEmblemBadge(
                key: const Key('crew-emblem-preview'),
                emblem: emblem,
                size: 120,
              ),
            ),
            _label('틀', c.muted),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in CrewEmblem.frames)
                  _tile(
                    key: CrewEmblemPicker.frameKey(id),
                    selected: id == _frame,
                    onTap: () => setState(() => _frame = id),
                    child: Image.asset(
                      CrewEmblem.frameAsset(id),
                      width: 40,
                      height: 40,
                      color: id == _frame ? c.primary : c.muted,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
              ],
            ),
            _label('문양', c.muted),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in CrewEmblem.glyphIds)
                  _tile(
                    key: CrewEmblemPicker.iconKey(id),
                    selected: id == _glyph,
                    onTap: () => setState(() => _glyph = id),
                    child: Image.asset(
                      CrewEmblem.glyphAssetOf(id),
                      width: 36,
                      height: 36,
                      color: id == _glyph ? c.primary : c.muted,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
              ],
            ),
            _label('배경 무늬', c.muted),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in CrewEmblem.patterns)
                  _tile(
                    key: CrewEmblemPicker.patternKey(id),
                    selected: id == _pattern,
                    onTap: () => setState(() => _pattern = id),
                    child: id == 'none'
                        ? Text('없음', style: storeText(12, c.muted, w: FontWeight.w700))
                        : Image.asset(
                            CrewEmblem.patternAsset(id),
                            width: 40,
                            height: 40,
                            color: id == _pattern ? c.primary : c.muted,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                  ),
              ],
            ),
            _label('틀 색', c.muted),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in CrewEmblem.paletteColors.entries)
                  _swatch(
                    key: CrewEmblemPicker.colorKey(entry.key),
                    fill: entry.value,
                    selected: entry.key == _frameColor,
                    ring: c.ink,
                    onTap: () => _pickFrameColor(entry.key),
                  ),
              ],
            ),
            _label('문양 색 (틀 색과 잘 보이는 색만)', c.muted),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in allowedGlyphColors)
                  _swatch(
                    key: CrewEmblemPicker.glyphColorKey(id),
                    fill: CrewEmblem.paletteColors[id]!,
                    selected: id == _glyphColor,
                    ring: c.ink,
                    onTap: () => setState(() => _glyphColor = id),
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
