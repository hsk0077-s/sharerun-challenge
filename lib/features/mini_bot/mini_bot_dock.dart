import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import 'snail_bot_face.dart';

/// 달팽이봇 버튼 설정. 폰에만 저장하고 서버와 무관하다.
abstract final class MiniBotDockSettings {
  static const visibleKey = 'src.mini_bot.visible';
  static const dockKey = 'src.mini_bot.dock';
  static const hintSeenKey = 'src.mini_bot.hint_seen';

  /// 홈·대회 화면에 버튼을 보일지. 기본은 보임.
  static final ValueNotifier<bool> visible = ValueNotifier<bool>(true);

  static var _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      visible.value = prefs.getBool(visibleKey) ?? true;
    } catch (_) {}
  }

  static Future<void> setVisible(bool value) async {
    visible.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(visibleKey, value);
    } catch (_) {}
  }

  /// 시험에서 처음 상태로 되돌린다.
  static void resetForTest() {
    _loaded = false;
    visible.value = true;
  }
}

/// 버튼 위치.
@immutable
class MiniBotDockState {
  const MiniBotDockState({this.dx = 0, this.dy = 0});

  /// 기본 자리(하단 탭 위 오른쪽)에서 얼마나 옮겼는지.
  final double dx;
  final double dy;

  String encode() => jsonEncode({'dx': dx, 'dy': dy});

  static MiniBotDockState decode(String? raw) {
    if (raw == null || raw.isEmpty) return const MiniBotDockState();
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return const MiniBotDockState();
      final dx = json['dx'];
      final dy = json['dy'];
      // 예전 버전이 저장한 접힘 값('edge')은 읽지 않는다.
      return MiniBotDockState(
        dx: dx is num && dx.isFinite ? dx.toDouble() : 0,
        dy: dy is num && dy.isFinite ? dy.toDouble() : 0,
      );
    } catch (_) {
      return const MiniBotDockState();
    }
  }
}

/// 끌기 계산. 화면 크기와 기본 자리만 받는 순수 함수라서 시험하기 쉽다.
abstract final class MiniBotDockMath {
  static const double size = 56;

  /// 펴져 있을 때 가장자리와 띄우는 여백.
  static const double margin = 4;

  /// 기본 자리 기준 dx 범위: 화면 안.
  static (double, double) dxRange(Rect anchor, double screenWidth) {
    return (
      -anchor.left + margin,
      screenWidth - size - anchor.left - margin,
    );
  }

  /// 기본 자리 기준 dy 범위: 위로는 상태 표시줄 아래까지, 아래로는 기본 자리까지.
  static (double, double) dyRange(Rect anchor, double topInset) {
    final minDy = (topInset + 8) - anchor.top;
    return (minDy > 0 ? 0 : minDy, 0);
  }

  static double clamp(double v, (double, double) range) =>
      v.clamp(range.$1, range.$2).toDouble();
}

/// 끌어서 옮기고, 누르면 열리는 달팽이 얼굴 버튼.
///
/// 버튼은 화면 위 겹침층에 그린다. 자리는 [anchor]가 잡고, 얼굴은 그 자리를 기준으로 움직인다.
/// 누르면 [onOpen]이 불린다.
class MiniBotDock extends StatefulWidget {
  const MiniBotDock({
    super.key,
    required this.onOpen,
    this.message,
    this.messageId,
  });

  final VoidCallback onOpen;

  /// 버튼 위에 잠깐 띄우는 말풍선 글. 없으면 말풍선을 띄우지 않는다.
  final String? message;

  /// 앱을 켠 뒤 같은 화면에서는 말풍선을 한 번만 띄우기 위한 이름(예: 'home').
  final String? messageId;

  static const messageKey = Key('mini-bot-dock-message');

  /// 이번에 앱을 켠 뒤 말풍선을 이미 보여 준 화면들.
  static final Set<String> _shownMessageIds = <String>{};

  @visibleForTesting
  static void resetMessagesForTest() => _shownMessageIds.clear();

  static const faceKey = Key('mini-bot-dock-face');
  static const hintKey = Key('mini-bot-dock-hint');

  @override
  State<MiniBotDock> createState() => _MiniBotDockState();
}

class _MiniBotDockState extends State<MiniBotDock> {
  final _link = LayerLink();
  final _anchorKey = GlobalKey();
  final _portal = OverlayPortalController();

  var _state = const MiniBotDockState();
  var _showHint = false;
  Timer? _hintTimer;
  var _showMessage = false;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    await MiniBotDockSettings.ensureLoaded();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = MiniBotDockState.decode(
        prefs.getString(MiniBotDockSettings.dockKey),
      );
      final seen = prefs.getBool(MiniBotDockSettings.hintSeenKey) ?? false;
      if (!mounted) return;
      setState(() {
        _state = saved;
        _showHint = !seen;
      });
      if (_showHint) {
        _hintTimer = Timer(const Duration(seconds: 6), _dismissHint);
      } else {
        _maybeShowMessage();
      }
    } catch (_) {}
  }

  /// 첫 사용 안내를 이미 본 사람에게는 화면을 열 때 한마디를 띄운다. 앱을 켠 뒤 화면마다 한 번만.
  void _maybeShowMessage() {
    final text = widget.message;
    final id = widget.messageId;
    if (text == null || id == null || !MiniBotDockSettings.visible.value)
      return;
    if (!MiniBotDock._shownMessageIds.add(id)) return;
    if (!mounted) return;
    setState(() => _showMessage = true);
    _messageTimer = Timer(const Duration(seconds: 5), _dismissMessage);
  }

  void _dismissMessage() {
    _messageTimer?.cancel();
    if (_showMessage && mounted) setState(() => _showMessage = false);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(MiniBotDockSettings.dockKey, _state.encode());
    } catch (_) {}
  }

  void _dismissHint() {
    _hintTimer?.cancel();
    if (!_showHint) return;
    if (mounted) setState(() => _showHint = false);
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(MiniBotDockSettings.hintSeenKey, true);
      } catch (_) {}
    }());
  }

  Rect? _anchorRect() {
    final box = _anchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// 화면에 그릴 때 쓰는 기본 자리 기준 이동량.
  Offset _offset(Rect? anchor, Size screen, double topInset) {
    if (anchor == null) return Offset(_state.dx, _state.dy);
    final dy = MiniBotDockMath.clamp(
      _state.dy,
      MiniBotDockMath.dyRange(anchor, topInset),
    );
    final dx = MiniBotDockMath.clamp(
      _state.dx,
      MiniBotDockMath.dxRange(anchor, screen.width),
    );
    return Offset(dx, dy);
  }

  void _onPanStart(DragStartDetails _) {
    _dismissHint();
    _dismissMessage();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final anchor = _anchorRect();
    if (anchor == null) return;
    final media = MediaQuery.of(context);
    final base = _offset(anchor, media.size, media.padding.top);
    setState(() {
      _state = MiniBotDockState(
        dx: MiniBotDockMath.clamp(
          base.dx + details.delta.dx,
          MiniBotDockMath.dxRange(anchor, media.size.width),
        ),
        dy: MiniBotDockMath.clamp(
          base.dy + details.delta.dy,
          MiniBotDockMath.dyRange(anchor, media.padding.top),
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails _) => unawaited(_save());

  void _onTap() {
    _dismissHint();
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    // 기본 자리를 잡아 주는 보이지 않는 칸. 하단 탭과 겹치지 않는 위치 계산은 이 칸이 한다.
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildFace,
        child: SizedBox(
          key: _anchorKey,
          width: MiniBotDockMath.size,
          height: MiniBotDockMath.size,
        ),
      ),
    );
  }

  Widget _buildFace(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MiniBotDockSettings.visible,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        final media = MediaQuery.of(context);
        final offset = _offset(_anchorRect(), media.size, media.padding.top);
        return Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: offset,
            child: SizedBox(
              width: MiniBotDockMath.size,
              height: MiniBotDockMath.size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Semantics(
                      button: true,
                      label: '달팽이봇',
                      child: GestureDetector(
                        key: MiniBotDock.faceKey,
                        behavior: HitTestBehavior.opaque,
                        // 손가락이 처음 닿은 곳부터 따라가서 끌기가 밀리지 않는다.
                        dragStartBehavior: DragStartBehavior.down,
                        onTap: _onTap,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.nightCard,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.nightLime, width: 2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            // 그림 둘레 여백이 있어서 원 안에 꽉 차게 키운다.
                            child: Transform.scale(
                              scale: 1.4,
                              alignment: const Alignment(0, 0.35),
                              child: SnailBotFace(size: MiniBotDockMath.size),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showHint)
                    const Positioned(
                      right: 0,
                      bottom: MiniBotDockMath.size + 8,
                      child: _DockHint(key: MiniBotDock.hintKey),
                    ),
                  if (_showMessage && widget.message != null)
                    Positioned(
                      right: 0,
                      bottom: MiniBotDockMath.size + 8,
                      child: _DockMessage(
                        key: MiniBotDock.messageKey,
                        text: widget.message!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 달팽이봇이 건네는 한마디. 꼬리가 버튼을 가리킨다.
class _DockMessage extends StatelessWidget {
  const _DockMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 230),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: AppColors.nightLime,
              borderRadius: BorderRadius.circular(16),
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.nightOnLime,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: CustomPaint(
                size: const Size(14, 8),
                painter: _TailPainter(AppColors.nightLime),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

class _DockHint extends StatelessWidget {
  const _DockHint({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: const Color(0xE6202B2A),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '끌어서 옮길 수 있어요',
            style: TextStyle(color: Colors.white, fontSize: 12),
            softWrap: false,
          ),
        ),
      ),
    );
  }
}
