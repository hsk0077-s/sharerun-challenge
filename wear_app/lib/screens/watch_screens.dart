import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/run_session.dart';
import '../core/watch_platform.dart';
import '../l10n/watch_copy.dart';
import 'watch_icons.dart';

/// 워치 5개 화면. 검은 배경(#000000)에 흰 글자, 보조 글자는 밝은 회색.
/// 원형 화면에서 가장자리가 잘리지 않도록 모든 크기를 화면 지름(s)의 비율로 잡고,
/// 줄마다 그 높이에서 원이 허락하는 폭 안에만 그린다.
const watchBg = Color(0xFF000000);
const watchInk = Color(0xFFFFFFFF);
const watchMuted = Color(0xFFBDBDBD);
const watchGreen = Color(0xFF1FA855);
const watchRed = Color(0xFFE53935);

Locale _locale() => WidgetsBinding.instance.platformDispatcher.locale;

TextStyle _text(double s, double fraction,
        {Color color = watchInk, FontWeight weight = FontWeight.w600}) =>
    TextStyle(
      color: color,
      fontSize: s * fraction,
      fontWeight: weight,
      height: 1.1,
    );

/// 원형 화면 틀. 지름 [s]인 정사각형 안에서 [builder]가 그린다.
class RoundFace extends StatelessWidget {
  const RoundFace({required this.builder, super.key});

  final Widget Function(BuildContext context, double s) builder;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: watchBg,
        body: LayoutBuilder(
          builder: (context, box) {
            final s = math.min(box.maxWidth, box.maxHeight);
            return Center(
              child: SizedBox(width: s, height: s, child: builder(context, s)),
            );
          },
        ),
      );
}

/// 지름 비율로 [top]~[bottom] 높이 띠. 띠의 위·아래 끝 중 원이 더 좁은 쪽에 폭을 맞춘다.
double chordWidth(double s, double top, double bottom, {double margin = 0.92}) {
  final dy = math.max((top - 0.5).abs(), (bottom - 0.5).abs());
  final half = math.sqrt(math.max(0, 0.25 - dy * dy));
  return 2 * half * s * margin;
}

Widget zone(double s, double top, double bottom, Widget child,
    {double margin = 0.92}) {
  final w = chordWidth(s, top, bottom, margin: margin);
  return Positioned(
    top: top * s,
    height: (bottom - top) * s,
    left: (s - w) / 2,
    width: w,
    child: FittedBox(fit: BoxFit.scaleDown, child: child),
  );
}

/// 폭을 다 쓰는 줄(왼쪽·오른쪽 따로 놓을 때).
Widget zoneRow(double s, double top, double bottom, Widget left, Widget right,
    {double margin = 0.92}) {
  final w = chordWidth(s, top, bottom, margin: margin);
  return Positioned(
    top: top * s,
    height: (bottom - top) * s,
    left: (s - w) / 2,
    width: w,
    child: Row(
      children: [
        Expanded(
          child: FittedBox(
              fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: left),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
              fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: right),
        ),
      ],
    ),
  );
}

// ───────────────────────── ② 대기·시작 ─────────────────────────

/// 위 GPS 아이콘(소), 가운데 원형 START(화면 40% 이상), 아래 내 동물 티어 이름(중).
/// 티어 값이 없으면 아래 줄은 그리지 않는다. 길게 누르면 계정 연결 화면.
class StartFace extends StatelessWidget {
  const StartFace({
    required this.onStart,
    this.onLongPress,
    this.tierName,
    this.tierCode,
    this.pendingCount = 0,
    super.key,
  });

  /// 아직 서버에 올라가지 못한 기록 수. 0이면 아무것도 보이지 않는다.
  final int pendingCount;

  final VoidCallback onStart;
  final VoidCallback? onLongPress;

  /// 이미 사용자 언어로 된 티어 이름(예: 치타 골드). 없으면 숨긴다.
  final String? tierName;

  /// 티어 동물 코드(`turtle` …). 아이콘 자리표시를 고른다.
  final String? tierCode;

  static const buttonKey = Key('watch-start-button');
  static const gpsKey = Key('watch-start-gps');
  static const tierKey = Key('watch-start-tier');
  static const pendingKey = Key('watch-start-pending');

  /// START 버튼 지름 비율(화면 지름 대비). 40% 이상이어야 한다.
  static const buttonFraction = 0.46;

  @override
  Widget build(BuildContext context) {
    final tier = tierName?.trim();
    return RoundFace(
      builder: (context, s) {
        final d = buttonFraction * s;
        return GestureDetector(
          onLongPress: onLongPress,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              zone(
                s,
                0.07,
                0.21,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WatchIcon(
                      WatchIconNames.gps,
                      key: gpsKey,
                      size: s * 0.085,
                      fallback: Icons.gps_fixed,
                      color: watchMuted,
                    ),
                    if (pendingCount > 0)
                      Text(
                        watchUi(_locale(), 'pendingUpload', n: pendingCount),
                        key: pendingKey,
                        style: _text(s, 0.045, color: watchMuted, weight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: (s - d) / 2,
                top: (s - d) / 2,
                width: d,
                height: d,
                child: Material(
                  key: buttonKey,
                  color: watchGreen,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onStart,
                    child: Center(
                      child: Text('START',
                          style: _text(s, 0.105, weight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
              if (tier != null && tier.isNotEmpty)
                zone(
                  s,
                  0.76,
                  0.89,
                  Row(
                    key: tierKey,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (WatchIconNames.tier(tierCode) != null) ...[
                        WatchIcon(
                          WatchIconNames.tier(tierCode)!,
                          size: s * 0.1,
                          fallback: Icons.pets,
                        ),
                        SizedBox(width: s * 0.025),
                      ],
                      Text(tier, style: _text(s, 0.085)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── ① 페어링 ─────────────────────────

/// 휴대폰 앱이 보여 준 6자리 숫자를 워치에서 입력한다(동작은 그대로, 화면만 새로).
/// 위 안내(소), 가운데 6자리(대), 숫자판, 아래 진행 점과 취소("나중에").
/// 여섯 자리가 차면 바로 확인한다.
class PairingFace extends StatefulWidget {
  const PairingFace({
    required this.onSubmit,
    required this.onSkip,
    this.notice,
    super.key,
  });

  /// 위 안내 대신 보여 줄 문구(연결이 만료돼 다시 연결할 때). 없으면 기본 안내.
  final String? notice;

  /// 오류 메시지를 돌려주면 보여 주고, null이면 연결 성공.
  final Future<String?> Function(String code) onSubmit;
  final VoidCallback onSkip;

  static const codeKey = Key('pairing-code');
  static const messageKey = Key('pairing-message');
  static const skipKey = Key('pairing-skip');
  static const progressKey = Key('pairing-progress');
  static Key digitKey(int digit) => Key('pairing-digit-$digit');
  static const backKey = Key('pairing-back');

  @override
  State<PairingFace> createState() => _PairingFaceState();
}

class _PairingFaceState extends State<PairingFace> {
  static const _length = 6;
  var _code = '';
  var _busy = false;
  String? _message;

  Future<void> _press(String digit) async {
    if (_busy || _code.length >= _length) return;
    setState(() {
      _code += digit;
      _message = null;
    });
    if (_code.length < _length) return;
    setState(() => _busy = true);
    final error = await widget.onSubmit(_code);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error != null) {
        _message = error;
        _code = '';
      }
    });
  }

  void _back() {
    if (_busy || _code.isEmpty) return;
    setState(() {
      _code = _code.substring(0, _code.length - 1);
      _message = null;
    });
  }

  Widget _key(double s, Key key, String label, VoidCallback? onTap,
          {IconData? icon}) =>
      SizedBox(
        width: s * 0.17,
        height: s * 0.105,
        child: TextButton(
          key: key,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: watchInk,
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(s * 0.052)),
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: icon != null
                ? Icon(icon, size: s * 0.065, color: watchInk)
                : Text(label, style: _text(s, 0.058, weight: FontWeight.w700)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final locale = _locale();
    final copy = WatchCopy.of(locale);
    final shown = _code.padRight(_length, '•');
    final display = '${shown.substring(0, 3)} ${shown.substring(3)}';
    final message = _message == null
        ? (_busy ? copy.checking : (widget.notice ?? watchUi(locale, 'pairTop')))
        : WatchCopy.pairingError(locale, _message!);
    return RoundFace(
      builder: (context, s) {
        final gap = s * 0.012;
        Widget row(List<Widget> keys) => Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < keys.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    keys[i],
                  ],
                ],
              ),
            );
        return Stack(
          children: [
            zone(
              s,
              0.07,
              0.16,
              Text(
                message,
                key: PairingFace.messageKey,
                textAlign: TextAlign.center,
                style: _text(s, 0.055,
                    color: _message == null ? watchMuted : const Color(0xFFFF8A80),
                    weight: FontWeight.w500),
              ),
            ),
            zone(
              s,
              0.17,
              0.30,
              Text(
                display,
                key: PairingFace.codeKey,
                style: _text(s, 0.115, weight: FontWeight.w800)
                    .copyWith(letterSpacing: s * 0.01),
              ),
            ),
            zone(
              s,
              0.31,
              0.80,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final digits in const [
                    [1, 2, 3],
                    [4, 5, 6],
                    [7, 8, 9],
                  ])
                    row([
                      for (final d in digits)
                        _key(s, PairingFace.digitKey(d), '$d', () => _press('$d')),
                    ]),
                  row([
                    _key(s, PairingFace.skipKey, copy.later,
                        _busy ? null : widget.onSkip),
                    _key(s, PairingFace.digitKey(0), '0', () => _press('0')),
                    _key(s, PairingFace.backKey, '', _back, icon: Icons.backspace_outlined),
                  ]),
                ],
              ),
            ),
            zone(
              s,
              0.84,
              0.90,
              Row(
                key: PairingFace.progressKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _length; i++)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: s * 0.012),
                      child: Container(
                        width: s * 0.032,
                        height: s * 0.032,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _code.length ? watchInk : const Color(0xFF3A3A3A),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────────────────────── ③ 달리는 중 ─────────────────────────

/// 달리는 중. 큰 숫자는 하나(처음엔 거리), 작은 숫자는 둘(시간·페이스). 화면을 탭하면
/// 큰 숫자가 거리 → 시간 → 페이스 순서로 바뀐다. 최하단 곡선은 다음 1km까지의 진행 바.
/// 1km를 막 지났으면 위 줄에 잠깐 안내가 뜬다.
class RunningFace extends StatelessWidget {
  const RunningFace({
    required this.session,
    required this.now,
    this.passedKm,
    this.focus = 0,
    this.onCycle,
    this.shareEarned,
    this.tierCode,
    super.key,
  });

  final RunSession session;

  /// 이번 달리기로 쌓인 SHARE. 값을 만들어 내는 곳이 아직 없으면 null이고, 그러면 숫자는 숨긴다.
  /// (휴대폰 앱의 VALUE 계산이나 만보기 SHARE 공식은 쓰지 않는다.)
  final int? shareEarned;

  /// 내 티어 동물 코드(`turtle` …). 없으면 티어 얼굴은 숨긴다.
  final String? tierCode;

  /// 화면에 보여 줄 현재 시각.
  final DateTime now;

  /// 방금 지난 km(안내를 보여 주는 동안만 값이 있다). 없으면 현재 시각을 보여 준다.
  final int? passedKm;

  /// 큰 숫자로 보여 줄 값: 0 거리, 1 시간, 2 페이스.
  final int focus;

  /// 화면을 탭했을 때(다음 값으로 넘긴다).
  final VoidCallback? onCycle;

  static const metricCount = 3;
  static const timeKey = Key('watch-run-time');
  static const bannerKey = Key('watch-run-banner');
  static const distanceKey = Key('watch-run-distance');
  static const paceKey = Key('watch-run-pace');
  static const elapsedKey = Key('watch-run-elapsed');
  static const arcKey = Key('watch-run-arc');
  static const shareRowKey = Key('watch-run-share-row');
  static const shareKey = Key('watch-run-share');

  /// 다음 1km까지의 진행(0~1).
  static double kmProgress(double distanceKm) {
    if (distanceKm <= 0 || distanceKm.isNaN || distanceKm.isInfinite) return 0;
    return distanceKm - distanceKm.floorToDouble();
  }

  static String clockText(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _value(double s, int metric, {required bool big}) {
    final size = big ? 0.27 : 0.105;
    final weight = big ? FontWeight.w900 : FontWeight.w700;
    final unitSize = big ? 0.085 : 0.055;
    switch (metric) {
      case 0:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(formatKm(session.distanceKm),
                key: distanceKey, style: _text(s, size, weight: weight)),
            Text(' km', style: _text(s, unitSize, color: watchMuted)),
          ],
        );
      case 1:
        return Text(formatElapsed(session.movingTime),
            key: elapsedKey, style: _text(s, size, weight: weight));
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(formatPace(session.paceSecondsPerKm),
                key: paceKey, style: _text(s, size, weight: weight)),
            Text('/km', style: _text(s, unitSize, color: watchMuted)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = _locale();
    final km = session.distanceKm;
    final banner = passedKm;
    final won = banner == null ? 0 : plannedDonationWon(banner.toDouble());
    final main = focus % metricCount;
    final others = [for (var i = 0; i < metricCount; i++) if (i != main) i];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCycle,
      child: RoundFace(
        builder: (context, s) => Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                key: arcKey,
                painter: KmArcPainter(progress: kmProgress(km)),
              ),
            ),
            if (banner == null)
              zone(
                s,
                0.09,
                0.21,
                Text(clockText(now),
                    key: timeKey,
                    style: _text(s, 0.075, color: watchMuted, weight: FontWeight.w500)),
              )
            else
              zone(
                s,
                0.07,
                0.22,
                Column(
                  key: bannerKey,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(watchUi(locale, 'kmPassed', n: banner),
                        style: _text(s, 0.07, weight: FontWeight.w800)),
                    if (won > 0)
                      Text(watchUi(locale, 'donationPlanned', n: won),
                          style: _text(s, 0.05, color: watchMuted, weight: FontWeight.w500)),
                  ],
                ),
              ),
            zone(s, 0.23, 0.53, _value(s, main, big: true)),
            zoneRow(
              s,
              0.56,
              0.71,
              _value(s, others[0], big: false),
              _value(s, others[1], big: false),
            ),
            // 작은 숫자와 아래 호 사이: [티어 얼굴] [SHARE 동전] [숫자]. 값이 없으면 줄째 숨긴다.
            if (shareEarned != null || WatchIconNames.tier(tierCode) != null)
              zone(
                s,
                0.725,
                0.82,
                Row(
                  key: shareRowKey,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (WatchIconNames.tier(tierCode) != null) ...[
                      WatchIcon(
                        WatchIconNames.tier(tierCode)!,
                        size: s * 0.075,
                        fallback: Icons.pets,
                      ),
                      SizedBox(width: s * 0.03),
                    ],
                    if (shareEarned != null) ...[
                      WatchIcon(
                        WatchIconNames.share,
                        size: s * 0.075,
                        fallback: Icons.monetization_on_outlined,
                        color: const Color(0xFFFFC83D),
                      ),
                      SizedBox(width: s * 0.015),
                      Text('$shareEarned',
                          key: shareKey,
                          style: _text(s, 0.07, weight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 화면 맨 아래 곡선을 따라 채워지는 진행 바. 왼쪽에서 오른쪽으로 찬다.
class KmArcPainter extends CustomPainter {
  const KmArcPainter({required this.progress});

  final double progress;

  static const _startDeg = 125.0;
  static const _sweepDeg = 70.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: s * 0.455);
    final stroke = s * 0.03;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = const Color(0xFF2E2E2E);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = watchGreen;
    final start = _startDeg * math.pi / 180;
    final sweep = _sweepDeg * math.pi / 180;
    canvas.drawArc(rect, start, -sweep, false, track);
    final p = progress.clamp(0.0, 1.0);
    if (p > 0) canvas.drawArc(rect, start, -sweep * p, false, fill);
  }

  @override
  bool shouldRepaint(KmArcPainter old) => old.progress != progress;
}

// ───────────────────────── ④ 일시정지·조작 ─────────────────────────

/// 달리는 중 화면에서 옆으로 밀면 나온다. 위 "일시정지됨"(소), 가운데 종료(빨강, 길게 눌러야 끝남)·
/// 재개(초록, 탭) 큰 버튼, 아래 페이지 점. 이 화면에 있는 동안 달리기는 멈춰 있다.
class ControlsFace extends StatelessWidget {
  const ControlsFace({required this.onResume, required this.onFinish, super.key});

  final VoidCallback onResume;
  final VoidCallback onFinish;

  static const stopKey = Key('watch-controls-stop');
  static const resumeKey = Key('watch-controls-resume');
  static const dotsKey = Key('watch-controls-dots');

  /// 큰 버튼 지름 비율.
  static const buttonFraction = 0.30;

  Widget _button(double s, Key key, Color color, String icon, IconData fallback,
      String label, {VoidCallback? onTap, VoidCallback? onHoldComplete}) {
    final d = s * buttonFraction;
    final circle = SizedBox(
      width: d,
      height: d,
      child: Material(
        key: key,
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: WatchIcon(icon, size: d * 0.5, fallback: fallback),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onHoldComplete == null)
          // 고리가 있는 종료 버튼과 높이를 맞추려고 같은 바깥 여백을 둔다.
          Padding(padding: EdgeInsets.all(s * HoldRingButton.gapFraction), child: circle)
        else
          HoldRingButton(
            diameter: d,
            ringWidth: s * 0.012,
            ringGap: s * HoldRingButton.gapFraction,
            onComplete: onHoldComplete,
            child: circle,
          ),
        SizedBox(height: s * 0.02),
        SizedBox(
          width: d * 1.25,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, textAlign: TextAlign.center, style: _text(s, 0.062)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = _locale();
    return RoundFace(
      builder: (context, s) => Stack(
        children: [
          zone(
            s,
            0.09,
            0.21,
            Text(watchUi(locale, 'pausedTitle'),
                style: _text(s, 0.07, color: watchMuted, weight: FontWeight.w500)),
          ),
          zone(
            s,
            0.27,
            0.74,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 실수로 끝나지 않게 길게 눌러야 끝난다.
                _button(s, stopKey, watchRed, WatchIconNames.stop,
                    Icons.stop_rounded, watchUi(locale, 'holdToStop'),
                    onHoldComplete: onFinish),
                SizedBox(width: s * 0.07),
                _button(s, resumeKey, watchGreen, WatchIconNames.play,
                    Icons.play_arrow_rounded, watchUi(locale, 'resume'),
                    onTap: onResume),
              ],
            ),
          ),
          zone(
            s,
            0.84,
            0.90,
            Row(
              key: dotsKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: s * 0.015),
                    child: Container(
                      width: s * 0.035,
                      height: s * 0.035,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 2 ? watchInk : const Color(0xFF3A3A3A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 길게 눌러야 끝나는 버튼. 누르고 있는 동안 [holdDuration]에 걸쳐 바깥 고리가 0 → 1로 차고,
/// 다 차면 [onComplete]를 한 번만 부른다. 다 차기 전에 손가락을 떼면 고리가 0으로 돌아가고
/// 아무 일도 일어나지 않는다. 탭만으로는 끝나지 않는다.
class HoldRingButton extends StatefulWidget {
  const HoldRingButton({
    required this.diameter,
    required this.ringWidth,
    required this.ringGap,
    required this.onComplete,
    required this.child,
    this.holdDuration = const Duration(milliseconds: 800),
    super.key,
  });

  /// 안쪽 버튼 지름.
  final double diameter;
  final double ringWidth;

  /// 버튼과 고리 사이 바깥 여백(고리가 차지하는 폭 포함).
  final double ringGap;
  final VoidCallback onComplete;
  final Widget child;
  final Duration holdDuration;

  /// 버튼 지름 대비 고리 바깥 여백 비율.
  static const gapFraction = 0.022;
  static const ringKey = Key('watch-hold-ring');

  @override
  State<HoldRingButton> createState() => _HoldRingButtonState();
}

class _HoldRingButtonState extends State<HoldRingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.holdDuration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && !_fired) {
            _fired = true;
            widget.onComplete();
          }
        });
  var _fired = false;

  /// 현재 고리 진행(0~1). 시험에서 읽는다.
  double get progress => _controller.value;

  void _down(PointerDownEvent _) {
    _fired = false;
    _controller.forward(from: 0);
  }

  void _release([PointerEvent? _]) {
    // 끝나서 화면이 바뀐 뒤에 손가락을 떼면 이미 정리된 버튼이다.
    if (!mounted) return;
    _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outer = widget.diameter + widget.ringGap * 2;
    return Listener(
      onPointerDown: _down,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: SizedBox(
        width: outer,
        height: outer,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            key: HoldRingButton.ringKey,
            foregroundPainter: _HoldRingPainter(
              progress: _controller.value,
              stroke: widget.ringWidth,
            ),
            child: child,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({required this.progress, required this.stroke});

  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = const Color(0xFF2E2E2E);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = watchInk;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0.0, 1.0), false, fill);
    }
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) => old.progress != progress || old.stroke != stroke;
}

// ───────────────────────── 대회 순위 알림 ─────────────────────────

/// 대회 순위 알림. 순위 데이터는 휴대폰이 중계해 준 값만 보여 주고, 없으면 아무것도 그리지 않는다.
class RankAlertFace extends StatelessWidget {
  const RankAlertFace({required this.rank, required this.gapPeople, super.key});

  final int rank;
  final int gapPeople;

  @override
  Widget build(BuildContext context) {
    final copy = WatchCopy.ofContext(context);
    final locale = _locale();
    return RoundFace(
      builder: (context, s) => Stack(
        children: [
          zone(s, 0.12, 0.24,
              Text(copy.rankAlert, style: _text(s, 0.07, color: watchMuted))),
          zone(s, 0.30, 0.58,
              Text(WatchCopy.rankPlace(locale, rank),
                  style: _text(s, 0.2, weight: FontWeight.w900))),
          zone(s, 0.62, 0.74,
              Text(gapPeople > 0 ? copy.aheadOf(gapPeople) : copy.leading,
                  style: _text(s, 0.075, color: watchMuted))),
        ],
      ),
    );
  }
}

// ───────────────────────── 카운트다운 ─────────────────────────

/// 시작을 누른 뒤 3·2·1. 화면을 탭하면 취소하고 시작 화면으로 돌아간다.
class CountdownFace extends StatelessWidget {
  const CountdownFace({required this.count, required this.onCancel, super.key});

  final int count;
  final VoidCallback onCancel;

  static const numberKey = Key('watch-countdown-number');

  @override
  Widget build(BuildContext context) {
    final locale = _locale();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCancel,
      child: RoundFace(
        builder: (context, s) => Stack(
          children: [
            zone(
              s,
              0.18,
              0.78,
              Text('$count',
                  key: numberKey, style: _text(s, 0.5, weight: FontWeight.w900)),
            ),
            zone(
              s,
              0.80,
              0.90,
              Text(watchUi(locale, 'cancelHint'),
                  style: _text(s, 0.05, color: watchMuted, weight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 경로 선 ─────────────────────────

/// 위도·경도 점을 정사각형 안에 맞춰 그리는 단순한 선. 지도는 없다.
/// 현재 위치(마지막 점)는 점으로 표시한다.
class RoutePainter extends CustomPainter {
  const RoutePainter({
    required this.points,
    this.stroke = 4,
    this.showCurrent = true,
  });

  /// (위도, 경도) 순서.
  final List<(double, double)> points;
  final double stroke;
  final bool showCurrent;

  /// [points]를 [size]에 맞춘 화면 좌표. 점이 둘 미만이면 빈 목록.
  /// 위도 1도와 경도 1도의 실제 길이가 달라 경도에 cos(위도)를 곱해 모양을 맞춘다.
  static List<Offset> project(List<(double, double)> points, Size size, {double inset = 0.08}) {
    if (points.length < 2) return const [];
    final lat0 = points.map((p) => p.$1).reduce((a, b) => a + b) / points.length;
    final k = math.cos(lat0 * math.pi / 180);
    final xs = [for (final p in points) p.$2 * k];
    final ys = [for (final p in points) -p.$1];
    final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    final w = math.max(maxX - minX, 1e-9);
    final h = math.max(maxY - minY, 1e-9);
    final avail = math.min(size.width, size.height) * (1 - 2 * inset);
    final scale = avail / math.max(w, h);
    final dx = (size.width - w * scale) / 2;
    final dy = (size.height - h * scale) / 2;
    final raw = [
      for (var i = 0; i < points.length; i++)
        Offset(dx + (xs[i] - minX) * scale, dy + (ys[i] - minY) * scale),
    ];
    // 대각선으로 뛴 경로는 정사각형 모서리까지 닿아 원형 화면 밖으로 나간다.
    // 가운데에서 가장 먼 점이 원 안에 들도록 가운데를 기준으로 줄인다.
    final center = Offset(size.width / 2, size.height / 2);
    final limit = math.min(size.width, size.height) / 2 * (1 - inset);
    final far = raw.map((p) => (p - center).distance).reduce(math.max);
    if (far <= limit || far <= 0) return raw;
    final k2 = limit / far;
    return [for (final p in raw) center + (p - center) * k2];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pts = project(points, size);
    if (pts.isEmpty) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke
        ..color = watchInk,
    );
    canvas.drawCircle(pts.first, stroke * 0.9, Paint()..color = watchMuted);
    if (showCurrent) {
      canvas.drawCircle(pts.last, stroke * 1.9, Paint()..color = watchInk);
      canvas.drawCircle(pts.last, stroke * 1.3, Paint()..color = watchGreen);
    } else {
      canvas.drawCircle(pts.last, stroke * 1.2, Paint()..color = watchGreen);
    }
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.points != points || old.stroke != stroke || old.showCurrent != showCurrent;
}

List<(double, double)> routePoints(List<GpsFix> fixes) =>
    [for (final f in fixes) (f.latitude, f.longitude)];

/// 달리는 중 화면의 왼쪽에 있는 경로 화면. 점이 둘 미만이면 GPS를 기다린다는 문구.
class RouteFace extends StatelessWidget {
  const RouteFace({required this.session, super.key});

  final RunSession session;

  static const paintKey = Key('watch-route-paint');
  static const waitingKey = Key('watch-route-waiting');

  @override
  Widget build(BuildContext context) {
    final points = routePoints(session.route);
    return RoundFace(
      builder: (context, s) => Stack(
        children: [
          if (points.length >= 2)
            Positioned(
              left: s * 0.12,
              top: s * 0.12,
              width: s * 0.76,
              height: s * 0.76,
              child: CustomPaint(
                key: paintKey,
                painter: RoutePainter(points: points, stroke: s * 0.012),
              ),
            )
          else
            zone(
              s,
              0.42,
              0.58,
              Text(watchUi(_locale(), 'waitingGps'),
                  key: waitingKey,
                  textAlign: TextAlign.center,
                  style: _text(s, 0.06, color: watchMuted, weight: FontWeight.w500)),
            ),
          zone(
            s,
            0.86,
            0.93,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: s * 0.015),
                    child: Container(
                      width: s * 0.03,
                      height: s * 0.03,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? watchInk : const Color(0xFF3A3A3A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── ⑤ 결과 요약 ─────────────────────────

/// 위 "러닝 종료"(소), 총 거리(대), 시간과 평균 페이스(중), 경로 선 썸네일,
/// "자세한 건 폰에서 보기", 아래 확인 버튼.
class SummaryFace extends StatelessWidget {
  const SummaryFace({
    required this.session,
    required this.onDone,
    this.shareEarned,
    super.key,
  });

  final RunSession session;
  final VoidCallback onDone;

  /// 이번 달리기로 쌓인 SHARE. 값이 없으면(null) 줄을 숨긴다. 공식을 워치에서 만들지 않는다.
  final int? shareEarned;

  static const shareKey = Key('watch-summary-share');
  static const distanceKey = Key('watch-summary-distance');
  static const timeKey = Key('watch-summary-time');
  static const paceKey = Key('watch-summary-pace');
  static const thumbKey = Key('watch-summary-route');
  static const phoneHintKey = Key('watch-summary-phone');
  static const confirmKey = Key('watch-summary-confirm');

  @override
  Widget build(BuildContext context) {
    final locale = _locale();
    final points = routePoints(session.route);
    return RoundFace(
      builder: (context, s) => Stack(
        children: [
          zone(s, 0.07, 0.16,
              Text(watchUi(locale, 'runEnded'),
                  style: _text(s, 0.06, color: watchMuted, weight: FontWeight.w500))),
          zone(
            s,
            0.17,
            0.36,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatKm(session.distanceKm),
                    key: distanceKey, style: _text(s, 0.2, weight: FontWeight.w900)),
                Text(' km', style: _text(s, 0.07, color: watchMuted)),
              ],
            ),
          ),
          zoneRow(
            s,
            0.37,
            0.47,
            Text(formatElapsed(session.movingTime),
                key: timeKey, style: _text(s, 0.085, weight: FontWeight.w700)),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatPace(session.paceSecondsPerKm),
                    key: paceKey, style: _text(s, 0.085, weight: FontWeight.w700)),
                Text('/km', style: _text(s, 0.045, color: watchMuted)),
              ],
            ),
          ),
          if (shareEarned != null)
            zone(
              s,
              0.475,
              0.545,
              Row(
                key: shareKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  WatchIcon(
                    WatchIconNames.share,
                    size: s * 0.06,
                    fallback: Icons.monetization_on_outlined,
                    color: const Color(0xFFFFC83D),
                  ),
                  SizedBox(width: s * 0.015),
                  Text('+$shareEarned',
                      style: _text(s, 0.06, weight: FontWeight.w700)),
                ],
              ),
            ),
          if (points.length >= 2)
            Positioned(
              left: s * 0.33,
              top: s * 0.555,
              width: s * 0.34,
              height: s * 0.17,
              child: CustomPaint(
                key: thumbKey,
                painter: RoutePainter(
                  points: points,
                  stroke: s * 0.008,
                  showCurrent: false,
                ),
              ),
            ),
          zone(
            s,
            0.73,
            0.80,
            Text(watchUi(locale, 'seeOnPhone'),
                key: phoneHintKey,
                style: _text(s, 0.048, color: watchMuted, weight: FontWeight.w500)),
          ),
          Positioned(
            top: 0.82 * s,
            left: s * 0.3,
            width: s * 0.4,
            height: s * 0.11,
            child: Material(
              key: confirmKey,
              color: watchGreen,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onDone,
                child: Center(
                  child: Text(watchUi(locale, 'confirm'),
                      style: _text(s, 0.06, weight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
