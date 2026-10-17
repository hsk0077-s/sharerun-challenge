import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'crew_emblem.dart';

/// 디자인팀 엠블럼 세트의 합성 순서(CREW-EMBLEM-SPEC 2절)를 그대로 따라 그린다.
/// 24칸 격자 기준: 계단 그림자 → 어두운 외곽선 → 금속 림 → 밝은 안쪽 선 →
/// 어두운 안쪽 테 → 배경 → 패턴 → 문양(그림자 포함) → 광택 → 반짝이.
class CrewEmblemLayered extends StatefulWidget {
  const CrewEmblemLayered({required this.emblem, required this.size, super.key});

  final CrewEmblem emblem;
  final double size;

  /// 그림을 미리 읽어 둔다(목록 화면이나 테스트에서 첫 그림이 늦지 않게).
  static Future<void> preload(Iterable<CrewEmblem> emblems) =>
      _CrewEmblemLayeredState._preload(emblems);

  @override
  State<CrewEmblemLayered> createState() => _CrewEmblemLayeredState();
}

class _CrewEmblemLayeredState extends State<CrewEmblemLayered> {
  static final _cache = <String, Future<ui.Image>>{};

  static Future<ui.Image> _load(String asset) => _cache.putIfAbsent(asset, () async {
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      });

  static Future<void> _preload(Iterable<CrewEmblem> emblems) async {
    for (final e in emblems.where((e) => e.isLayered)) {
      await _load(CrewEmblem.frameAsset(e.frame!));
      await _load(CrewEmblem.glyphAssetOf(e.icon));
      if (e.pattern != 'none') await _load(CrewEmblem.patternAsset(e.pattern));
    }
  }

  ui.Image? _frame;
  ui.Image? _glyph;
  ui.Image? _pattern;
  String? _loadedFor;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(CrewEmblemLayered old) {
    super.didUpdateWidget(old);
    if (old.emblem.code != widget.emblem.code) _resolve();
  }

  Future<void> _resolve() async {
    final e = widget.emblem;
    final key = e.code;
    try {
      final frame = await _load(CrewEmblem.frameAsset(e.frame!));
      final glyph = await _load(CrewEmblem.glyphAssetOf(e.icon));
      final pattern =
          e.pattern == 'none' ? null : await _load(CrewEmblem.patternAsset(e.pattern));
      if (!mounted || widget.emblem.code != key) return;
      setState(() {
        _frame = frame;
        _glyph = glyph;
        _pattern = pattern;
        _loadedFor = key;
      });
    } catch (_) {
      // 그림을 못 읽으면 빈 칸으로 둔다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.emblem;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _loadedFor == e.code && _frame != null && _glyph != null
          ? CustomPaint(
              painter: _EmblemPainter(
                frame: _frame!,
                glyph: _glyph!,
                pattern: _pattern,
                frameColor: CrewEmblem.paletteColors[e.color]!,
                glyphColor: CrewEmblem.paletteColors[e.glyphColor!]!,
                frameId: e.frame!,
              ),
            )
          : null,
    );
  }
}

/// 틀마다 다른 문양 위치(중심 y)와 크기, 반짝이 위치. 보드 예시에 맞춰 잡았다.
class _FrameFit {
  const _FrameFit(this.glyphCy, this.glyphScale, this.sparkle);
  final double glyphCy;
  final double glyphScale;
  final Offset sparkle;
}

const _fits = <String, _FrameFit>{
  'shield': _FrameFit(11.8, 0.52, Offset(17.2, 5.6)),
  'circle': _FrameFit(12.0, 0.52, Offset(17.4, 6.4)),
  'hexagon': _FrameFit(12.0, 0.54, Offset(17.8, 5.6)),
  'pennant': _FrameFit(10.8, 0.56, Offset(17.0, 5.6)),
  'diamond': _FrameFit(12.0, 0.42, Offset(15.4, 7.4)),
  'rounded-square': _FrameFit(12.0, 0.58, Offset(17.8, 6.0)),
  'octagon': _FrameFit(12.0, 0.54, Offset(17.8, 6.0)),
  'seal': _FrameFit(12.0, 0.52, Offset(17.8, 6.0)),
};

class _EmblemPainter extends CustomPainter {
  _EmblemPainter({
    required this.frame,
    required this.glyph,
    required this.pattern,
    required this.frameColor,
    required this.glyphColor,
    required this.frameId,
  });

  final ui.Image frame;
  final ui.Image glyph;
  final ui.Image? pattern;
  final Color frameColor;
  final Color glyphColor;
  final String frameId;

  static const _ink = Color(0xFF0B0F0D);
  static const _grid = Rect.fromLTWH(0, 0, 24, 24);
  static const _bounds = Rect.fromLTWH(-3, -3, 30, 30);

  static Color _shade(Color c, double dl) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + dl).clamp(0.0, 1.0)).toColor();
  }

  /// 이미지 하나를 24칸 격자에 그린다. [k]배 줄이고 (dx, dy)만큼 옮긴다(중심 기준).
  void _put(Canvas canvas, ui.Image img, Paint paint,
      {double k = 1, double dx = 0, double dy = 0, double cx = 12, double cy = 12}) {
    canvas.save();
    canvas.translate(cx + dx, cy + dy);
    canvas.scale(k);
    canvas.translate(-cx, -cy);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      _grid,
      paint,
    );
    canvas.restore();
  }

  /// 이미지의 모양으로 [fill]을 채운다.
  void _fillShape(Canvas canvas, ui.Image img, Paint fill,
      {double k = 1, double dx = 0, double dy = 0, double cx = 12, double cy = 12}) {
    canvas.saveLayer(_bounds, Paint());
    _put(canvas, img, Paint(), k: k, dx: dx, dy: dy, cx: cx, cy: cy);
    canvas.drawRect(_bounds, fill..blendMode = BlendMode.srcIn);
    canvas.restore();
  }

  Paint _flat(Color c) => Paint()..color = c;

  Paint _vertical(Color top, Color bottom, {double y0 = 2, double y1 = 22}) => Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, y0),
      Offset(0, y1),
      [top, bottom],
    );

  /// 같은 모양을 여덟 방향으로 겹쳐 [r]만큼 굵게 만든 외곽선.
  void _outline(Canvas canvas, ui.Image img, Color color, double r,
      {double k = 1, double cy = 12}) {
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      _fillShape(canvas, img, _flat(color),
          k: k, dx: r * math.cos(a), dy: r * math.sin(a), cy: cy);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fit = _fits[frameId] ?? _fits['circle']!;
    canvas.save();
    canvas.scale(size.width / 24);

    // 1. 계단 그림자
    _fillShape(canvas, frame, _flat(_ink.withValues(alpha: 0.55)), dy: 1.1);
    // 2. 굵은 어두운 외곽선(틀 0.90배 + 선 2)
    _outline(canvas, frame, _ink, 1.0, k: 0.90);
    _fillShape(canvas, frame, _flat(_ink), k: 0.90);
    // 3. 금속 림: 문양 색에서 만든 그라데이션
    _fillShape(canvas, frame,
        _vertical(_shade(glyphColor, 0.12), _shade(glyphColor, -0.18)),
        k: 0.90);
    // 4. 밝은 안쪽 선
    _fillShape(canvas, frame, _flat(Colors.white.withValues(alpha: 0.75)), k: 0.855);
    // 5. 어두운 안쪽 테
    _fillShape(canvas, frame, _flat(_shade(frameColor, -0.22)), k: 0.82);
    // 6. 배경: 위가 밝고 아래가 어두운 그라데이션 + 왼쪽 절반 흰색 8%
    _fillShape(canvas, frame,
        _vertical(_shade(frameColor, 0.08), _shade(frameColor, -0.08), y0: 4, y1: 20),
        k: 0.80);
    _fillShape(
      canvas,
      frame,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(24, 0),
          [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
            Colors.transparent,
          ],
          const [0, 0.5, 0.5, 1],
        ),
      k: 0.80,
    );
    // 7. 패턴: 흰색 12%, 배경 모양 안쪽만
    final pat = pattern;
    if (pat != null) {
      canvas.saveLayer(_bounds, Paint());
      _put(canvas, frame, Paint(), k: 0.80);
      _put(
        canvas,
        pat,
        Paint()
          ..blendMode = BlendMode.srcIn
          ..colorFilter = ColorFilter.mode(
            Colors.white.withValues(alpha: 0.12),
            BlendMode.srcIn,
          ),
      );
      canvas.restore();
    }
    // 8~9. 문양: 틀보다 밝으면 어두운 외곽선, 아니면 검정 35% 그림자
    final lighter = glyphColor.computeLuminance() > frameColor.computeLuminance();
    final g = fit.glyphScale;
    if (lighter) {
      _outline(canvas, glyph, _ink, 0.45, k: g, cy: fit.glyphCy);
      _fillShape(canvas, glyph, _flat(_ink.withValues(alpha: 0.6)),
          k: g, dx: 0.35, dy: 0.7, cy: fit.glyphCy);
    } else {
      _fillShape(canvas, glyph, _flat(Colors.black.withValues(alpha: 0.35)),
          k: g, dx: 0.35, dy: 0.7, cy: fit.glyphCy);
    }
    _fillShape(canvas, glyph,
        _vertical(_shade(glyphColor, 0.06), _shade(glyphColor, -0.10), y0: 6, y1: 18),
        k: g, cy: fit.glyphCy);
    // 10. 상단 광택 띠
    _fillShape(
      canvas,
      frame,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 3),
          const Offset(0, 10),
          [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)],
        ),
      k: 0.80,
    );
    // 11. 4각 반짝이
    _sparkle(canvas, fit.sparkle,
        frameColor.computeLuminance() > 0.47 ? glyphColor : Colors.white);

    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset c, Color color) {
    const r = 1.35;
    const w = 0.34;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, _flat(color.withValues(alpha: 0.95)));
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.frame != frame ||
      old.glyph != glyph ||
      old.pattern != pattern ||
      old.frameColor != frameColor ||
      old.glyphColor != glyphColor;
}
