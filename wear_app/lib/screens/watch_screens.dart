import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/run_session.dart';
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
    super.key,
  });

  final VoidCallback onStart;
  final VoidCallback? onLongPress;

  /// 이미 사용자 언어로 된 티어 이름(예: 치타 골드). 없으면 숨긴다.
  final String? tierName;

  /// 티어 동물 코드(`turtle` …). 아이콘 자리표시를 고른다.
  final String? tierCode;

  static const buttonKey = Key('watch-start-button');
  static const gpsKey = Key('watch-start-gps');
  static const tierKey = Key('watch-start-tier');

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
                0.08,
                0.21,
                WatchIcon(
                  WatchIconNames.gps,
                  key: gpsKey,
                  size: s * 0.1,
                  fallback: Icons.gps_fixed,
                  color: watchMuted,
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
  const PairingFace({required this.onSubmit, required this.onSkip, super.key});

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
        ? (_busy ? copy.checking : watchUi(locale, 'pairTop'))
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

/// 위 현재 시각(소), 가운데 거리 km(대·굵게), 아래 왼쪽 페이스 분/km·오른쪽 경과 시간(중),
/// 최하단 곡선 진행 바(다음 1km까지). 1km를 막 지났으면 위 줄에 잠깐 안내가 뜬다.
class RunningFace extends StatelessWidget {
  const RunningFace({
    required this.session,
    required this.now,
    this.passedKm,
    super.key,
  });

  final RunSession session;

  /// 화면에 보여 줄 현재 시각.
  final DateTime now;

  /// 방금 지난 km(안내를 보여 주는 동안만 값이 있다). 없으면 현재 시각을 보여 준다.
  final int? passedKm;

  static const timeKey = Key('watch-run-time');
  static const bannerKey = Key('watch-run-banner');
  static const distanceKey = Key('watch-run-distance');
  static const paceKey = Key('watch-run-pace');
  static const elapsedKey = Key('watch-run-elapsed');
  static const arcKey = Key('watch-run-arc');

  /// 다음 1km까지의 진행(0~1).
  static double kmProgress(double distanceKm) {
    if (distanceKm <= 0 || distanceKm.isNaN || distanceKm.isInfinite) return 0;
    return distanceKm - distanceKm.floorToDouble();
  }

  static String clockText(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final locale = _locale();
    final km = session.distanceKm;
    final banner = passedKm;
    final won = banner == null ? 0 : plannedDonationWon(banner.toDouble());
    return RoundFace(
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
          zone(
            s,
            0.23,
            0.53,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatKm(km),
                    key: distanceKey,
                    style: _text(s, 0.27, weight: FontWeight.w900)),
                SizedBox(width: s * 0.02),
                Text('km', style: _text(s, 0.085, color: watchMuted)),
              ],
            ),
          ),
          zoneRow(
            s,
            0.56,
            0.71,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatPace(session.paceSecondsPerKm),
                    key: paceKey, style: _text(s, 0.105, weight: FontWeight.w700)),
                Text('/km', style: _text(s, 0.055, color: watchMuted)),
              ],
            ),
            Text(formatElapsed(session.movingTime),
                key: elapsedKey, style: _text(s, 0.105, weight: FontWeight.w700)),
          ),
        ],
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

/// 달리는 중 화면에서 옆으로 밀면 나온다. 위 "일시정지됨"(소), 가운데 종료(빨강)·재개(초록) 큰 버튼,
/// 아래 페이지 점. 이 화면에 있는 동안 달리기는 멈춰 있다.
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
      String label, VoidCallback onTap) {
    final d = s * buttonFraction;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
        ),
        SizedBox(height: s * 0.02),
        Text(label, style: _text(s, 0.065)),
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
                _button(s, stopKey, watchRed, WatchIconNames.stop,
                    Icons.stop_rounded, watchUi(locale, 'stop'), onFinish),
                SizedBox(width: s * 0.07),
                _button(s, resumeKey, watchGreen, WatchIconNames.play,
                    Icons.play_arrow_rounded, watchUi(locale, 'resume'), onResume),
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
                for (var i = 0; i < 2; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: s * 0.015),
                    child: Container(
                      width: s * 0.035,
                      height: s * 0.035,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 1 ? watchInk : const Color(0xFF3A3A3A),
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

// ───────────────────────── ⑤ 결과 요약 ─────────────────────────

/// 위 "러닝 종료"(소), 가운데 총 거리(대)와 기부 예정(중), 아래 확인 버튼.
/// 기부 예정액은 서버 규칙(인증된 러닝 1km당 100원, 월 한도 안)으로 계산한 값이며 인증 뒤에 쌓인다.
class SummaryFace extends StatelessWidget {
  const SummaryFace({
    required this.session,
    required this.pendingCount,
    required this.onDone,
    super.key,
  });

  final RunSession session;
  final int pendingCount;
  final VoidCallback onDone;

  static const distanceKey = Key('watch-summary-distance');
  static const donationKey = Key('watch-summary-donation');
  static const confirmKey = Key('watch-summary-confirm');

  @override
  Widget build(BuildContext context) {
    final locale = _locale();
    final copy = WatchCopy.of(locale);
    final won = plannedDonationWon(session.distanceKm);
    return RoundFace(
      builder: (context, s) => Stack(
        children: [
          zone(s, 0.08, 0.19,
              Text(watchUi(locale, 'runEnded'),
                  style: _text(s, 0.07, color: watchMuted, weight: FontWeight.w500))),
          zone(
            s,
            0.20,
            0.45,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(formatKm(session.distanceKm),
                    key: distanceKey, style: _text(s, 0.24, weight: FontWeight.w900)),
                SizedBox(width: s * 0.02),
                Text('km', style: _text(s, 0.08, color: watchMuted)),
              ],
            ),
          ),
          if (won > 0)
            zone(
              s,
              0.47,
              0.62,
              Column(
                key: donationKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(watchUi(locale, 'donationPlanned', n: won),
                      style: _text(s, 0.075, weight: FontWeight.w700)),
                  Text(watchUi(locale, 'afterVerify'),
                      style: _text(s, 0.048, color: watchMuted, weight: FontWeight.w500)),
                ],
              ),
            ),
          zone(
            s,
            0.64,
            0.72,
            Text(
              pendingCount > 0 ? copy.uploadPending(pendingCount) : copy.nothingToUpload,
              textAlign: TextAlign.center,
              style: _text(s, 0.045, color: watchMuted, weight: FontWeight.w500),
            ),
          ),
          Positioned(
            top: 0.76 * s,
            left: s * 0.25,
            width: s * 0.5,
            height: s * 0.13,
            child: Material(
              key: confirmKey,
              color: watchGreen,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onDone,
                child: Center(
                  child: Text(watchUi(locale, 'confirm'),
                      style: _text(s, 0.07, weight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
