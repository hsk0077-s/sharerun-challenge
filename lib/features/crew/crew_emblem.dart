import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../shop/widgets/store_look.dart';
import 'crew_emblem_layered.dart';
import 'crew_emblem_status.dart';

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
    this.border,
    this.paid = false,
  });

  /// 유료 일러스트 엠블럼. 완성된 그림이라 틀·색을 따로 고르지 않는다.
  const CrewEmblem.paidIllustration(String id)
      : icon = id,
        color = '',
        frame = null,
        pattern = 'none',
        glyphColor = null,
        border = null,
        paid = true;

  /// 새 엠블럼. [glyph]는 `g_wolf` 같은 그림 문양 코드.
  const CrewEmblem.layered({
    required String this.frame,
    required String glyph,
    this.pattern = 'none',
    required String frameColor,
    required String this.glyphColor,
    this.border,
  })  : icon = glyph,
        color = frameColor,
        paid = false;

  /// 문양(새 엠블럼) 또는 모양(예전 엠블럼).
  final String icon;

  /// 틀 색(새 엠블럼) 또는 색(예전 엠블럼).
  final String color;
  final String? frame;
  final String pattern;
  final String? glyphColor;

  /// 활동으로 해금한 테두리(`distance-2` 같은 코드). 없으면 null.
  final String? border;

  /// 크루가 산 유료 일러스트 엠블럼인지.
  final bool paid;

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
    if (parts.length == 2 && parts[0] == 'paid') {
      return paidIds.contains(parts[1])
          ? CrewEmblem.paidIllustration(parts[1])
          : null;
    }
    if (parts.length == 5 || parts.length == 6) {
      final e = CrewEmblem.layered(
        frame: parts[0],
        glyph: parts[1],
        pattern: parts[2],
        frameColor: parts[3],
        glyphColor: parts[4],
        border: parts.length == 6 ? parts[5] : null,
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
      allowsGlyphColor(color, glyphColor ?? '') &&
      (border == null || borderIds.contains(border));

  String get code => paid
      ? 'paid:$icon'
      : isLayered
          ? '$frame:$icon:$pattern:$color:$glyphColor${border == null ? '' : ':$border'}'
          : '$icon:$color';

  /// 같은 엠블럼에 테두리만 바꾼다. 없애려면 null.
  CrewEmblem withBorder(String? value) => CrewEmblem.layered(
        frame: frame!,
        glyph: icon,
        pattern: pattern,
        frameColor: color,
        glyphColor: glyphColor!,
        border: value,
      );

  static const borderKinds = <String>['distance', 'donation', 'members', 'ranking'];
  static const borderTierNames = <String>['bronze', 'silver', 'gold'];
  static final borderIds = <String>{
    for (final k in borderKinds)
      for (var t = 1; t <= 3; t++) '$k-$t',
  };

  /// `distance-2` → 그림 경로.
  static String borderAsset(String id) {
    final tier = int.parse(id.split('-').last);
    return 'assets/images/crew_emblem/unlock/border-$id-${borderTierNames[tier - 1]}.png';
  }

  static const paidIds = <String>{
    'sunrise-cheetah',
    'moon-wolf',
    'ocean-turtle',
    'glow-heart',
  };
  static String paidAsset(String id) =>
      'assets/images/crew_emblem/paid/paid-$id.png';

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
  Color get colorValue => paid
      ? paletteColors['white']!
      : isLayered
          ? paletteColors[color]!
          : colors[color]!;

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
    if (emblem.paid) {
      return Image.asset(
        CrewEmblem.paidAsset(emblem.icon),
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
    }
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
  const CrewEmblemPicker({
    required this.initial,
    this.status,
    this.onBuy,
    super.key,
  });

  final CrewEmblem initial;

  /// 서버가 알려 준 해금·구매 상태. 없으면(크루가 서버에 없을 때) 잠금·준비 중으로 보인다.
  final CrewEmblemStatus? status;

  /// 유료 엠블럼을 살 때 부른다. 성공하면 새 상태를, 못 샀으면 null을 돌려준다.
  final Future<CrewEmblemStatus?> Function(String emblemId)? onBuy;

  static const doneKey = Key('crew-emblem-done');
  static Key frameKey(String id) => Key('crew-emblem-frame-$id');
  static Key iconKey(String id) => Key('crew-emblem-icon-$id');
  static Key patternKey(String id) => Key('crew-emblem-pattern-$id');
  static Key colorKey(String id) => Key('crew-emblem-color-$id');
  static Key borderKey(String id) => Key('crew-emblem-border-$id');
  static Key paidKey(String id) => Key('crew-emblem-paid-$id');
  static Key glyphColorKey(String id) => Key('crew-emblem-glyph-color-$id');

  static Future<CrewEmblem?> show(
    BuildContext context,
    CrewEmblem initial, {
    CrewEmblemStatus? status,
    Future<CrewEmblemStatus?> Function(String emblemId)? onBuy,
  }) {
    return showModalBottomSheet<CrewEmblem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.srcTokens.colors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          CrewEmblemPicker(initial: initial, status: status, onBuy: onBuy),
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
  String? _border;
  String? _paid;
  late CrewEmblemStatus _status = widget.status ?? const CrewEmblemStatus();

  @override
  void initState() {
    super.initState();
    _border = widget.initial.border;
    _paid = widget.initial.paid ? widget.initial.icon : null;
    // 예전 엠블럼은 새 기본값에서 시작한다(색·모양이 서로 달라 옮길 수 없다).
    final e = widget.initial.isLayered
        ? widget.initial
        : CrewEmblem.layeredDefault;
    if (!widget.initial.isLayered) _border = null;
    _frame = e.frame!;
    _glyph = e.icon;
    _pattern = e.pattern;
    _frameColor = e.color;
    _glyphColor = e.glyphColor!;
  }

  CrewEmblem get _emblem => _paid != null
      ? CrewEmblem.paidIllustration(_paid!)
      : CrewEmblem.layered(
          frame: _frame,
          glyph: _glyph,
          pattern: _pattern,
          frameColor: _frameColor,
          glyphColor: _glyphColor,
          border: _border,
        );

  /// 틀·문양 같은 것을 고르면 유료 엠블럼 선택은 풀린다.
  void _edit(VoidCallback change) => setState(() {
        _paid = null;
        change();
      });

  Future<void> _buy(String id) async {
    final buy = widget.onBuy;
    if (buy == null) return;
    final next = await buy(id);
    if (!mounted || next == null) return;
    setState(() {
      _status = next;
      if (next.paidOwned.contains(id)) _paid = id;
    });
  }

  static const _borderTitles = <String, String>{
    'distance': '거리',
    'donation': '기부',
    'members': '인원',
    'ranking': '랭킹',
  };

  String _borderRule(String kind) {
    final t = _status.thresholds[kind];
    if (t == null || t.length != 3) return '';
    String n(int v) => v.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
    final now = _status.progress[kind] ?? 0;
    switch (kind) {
      case 'distance':
        return '${n(t[0])}km · ${n(t[1])}km · ${n(t[2])}km  (지금 ${n(now.round())}km)';
      case 'donation':
        return '${n(t[0])}원 · ${n(t[1])}원 · ${n(t[2])}원  (지금 ${n(now.round())}원)';
      case 'members':
        return '${t[0]}명 · ${t[1]}명 · ${t[2]}명  (지금 ${now.round()}명)';
      default:
        return '월간 ${t[0]}위 · ${t[1]}위 · ${t[2]}위 이내';
    }
  }

  void _pickFrameColor(String id) {
    final allowed = CrewEmblem.allowedPairs[id] ?? const <String>[];
    _edit(() {
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

  Widget _borderTile(String id, SrcColorRoles c) {
    final unlocked = _status.earnedBorders.contains(id);
    final selected = _border == id && _paid == null;
    return InkWell(
      key: CrewEmblemPicker.borderKey(id),
      borderRadius: BorderRadius.circular(14),
      onTap: unlocked
          ? () => _edit(() => _border = selected ? null : id)
          : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c.primary : c.outline,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.28,
              child: Image.asset(CrewEmblem.borderAsset(id), width: 48, height: 48),
            ),
            if (!unlocked)
              Icon(Icons.lock_rounded, size: 16, color: c.muted),
          ],
        ),
      ),
    );
  }

  Widget _paidTile(String id, SrcColorRoles c) {
    final owned = _status.paidOwned.contains(id);
    final selected = _paid == id;
    final price = _status.paidPrices[id];
    final canBuy = !owned && _status.paidSaleEnabled && widget.onBuy != null;
    return Column(
      children: [
        InkWell(
          key: CrewEmblemPicker.paidKey(id),
          borderRadius: BorderRadius.circular(14),
          onTap: owned
              ? () => setState(() => _paid = selected ? null : id)
              : canBuy
                  ? () => _buy(id)
                  : null,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? c.primary : c.outline,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Opacity(
              opacity: owned || canBuy ? 1 : 0.4,
              child: Image.asset(CrewEmblem.paidAsset(id), width: 56, height: 56),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          owned ? '보유' : (price == null ? '' : '$price DIA'),
          style: storeText(11, owned ? c.primary : c.muted, w: FontWeight.w700),
        ),
      ],
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
                    onTap: () => _edit(() => _frame = id),
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
                    onTap: () => _edit(() => _glyph = id),
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
                    onTap: () => _edit(() => _pattern = id),
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
                    onTap: () => _edit(() => _glyphColor = id),
                  ),
              ],
            ),
            _label('해금 테두리 (활동으로 얻어요)', c.muted),
            for (final kind in CrewEmblem.borderKinds) ...[
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _borderTitles[kind]!,
                      style: storeText(12, c.ink, w: FontWeight.w800),
                    ),
                  ),
                  for (var tier = 1; tier <= 3; tier++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _borderTile('$kind-$tier', c),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 4, bottom: 10),
                child: Text(
                  _borderRule(kind),
                  style: storeText(11, c.muted, h: 1.3),
                ),
              ),
            ],
            _label('유료 일러스트 (크루가 평생 가져요)', c.muted),
            Row(
              children: [
                for (final id in CrewEmblem.paidIds.toList()..sort())
                  Expanded(child: _paidTile(id, c)),
              ],
            ),
            if (!_status.paidSaleEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '판매는 준비 중이에요.',
                  key: const Key('crew-emblem-paid-preparing'),
                  style: storeText(11, c.muted),
                ),
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
