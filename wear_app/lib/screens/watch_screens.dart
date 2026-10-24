import 'package:flutter/material.dart';

import '../core/run_session.dart';

const _bg = Color(0xFF0B0F0C);
const _lime = Color(0xFFD4FF4A);
const _ink = Color(0xFFF4F7F0);
const _muted = Color(0xFFA9B2A6);

/// 원형 화면 한가운데에 놓는 공통 틀. 글자는 큼직하게, 한 화면에 한 가지만.
class _Face extends StatelessWidget {
  const _Face({required this.label, required this.big, required this.sub, this.icon, this.onTap});

  final String label;
  final String big;
  final String sub;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
                if (icon != null) Icon(icon, color: _lime, size: 22),
                Text(
                  big,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ① 시작: 탭해서 시작. 길게 누르면 계정 연결 화면.
class StartFace extends StatelessWidget {
  const StartFace({
    required this.targetKm,
    required this.onStart,
    this.onChangeTarget,
    this.onLongPress,
    this.linkedName,
    super.key,
  });

  final double targetKm;
  final VoidCallback onStart;
  final VoidCallback? onChangeTarget;
  final VoidCallback? onLongPress;

  /// 연결된 계정의 닉네임. 연결 전이면 null.
  final String? linkedName;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPress: onLongPress,
        child: _Face(
          label: linkedName == null ? '시작' : (linkedName!.isEmpty ? '연결됨' : linkedName!),
          big: '${targetKm.toStringAsFixed(0)}km',
          sub: '탭해서 시작',
          icon: Icons.play_arrow_rounded,
          onTap: onStart,
        ),
      );
}

/// ⓪ 연결: 휴대폰 앱이 보여 준 6자리 숫자를 워치에서 입력한다.
/// 원형 화면에 맞춰 숫자판을 가운데에 모았다. 여섯 자리가 차면 바로 확인한다.
class PairingFace extends StatefulWidget {
  const PairingFace({required this.onSubmit, required this.onSkip, super.key});

  /// 오류 메시지를 돌려주면 보여 주고, null이면 연결 성공.
  final Future<String?> Function(String code) onSubmit;
  final VoidCallback onSkip;

  static const codeKey = Key('pairing-code');
  static const messageKey = Key('pairing-message');
  static const skipKey = Key('pairing-skip');
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

  Widget _key(Key key, String label, VoidCallback? onTap) => SizedBox(
        width: 44,
        height: 34,
        child: TextButton(
          key: key,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: _ink,
            backgroundColor: const Color(0xFF1B231D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final shown = _code.padRight(_length, '•');
    final display = '${shown.substring(0, 3)} ${shown.substring(3)}';
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _message ?? (_busy ? '확인하는 중' : '휴대폰 앱의 6자리'),
                  key: PairingFace.messageKey,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message == null ? _muted : const Color(0xFFFF8A80),
                    fontSize: 11,
                  ),
                ),
                Text(
                  display,
                  key: PairingFace.codeKey,
                  style: const TextStyle(
                    color: _lime,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                for (final row in const [
                  [1, 2, 3],
                  [4, 5, 6],
                  [7, 8, 9],
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final d in row) ...[
                          _key(PairingFace.digitKey(d), '$d', () => _press('$d')),
                          if (d % 3 != 0) const SizedBox(width: 3),
                        ],
                      ],
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _key(PairingFace.skipKey, '나중에', _busy ? null : widget.onSkip),
                    const SizedBox(width: 3),
                    _key(PairingFace.digitKey(0), '0', () => _press('0')),
                    const SizedBox(width: 3),
                    _key(PairingFace.backKey, '←', _back),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ② 달리는 중: 페이스·심박·거리.
class RunningFace extends StatelessWidget {
  const RunningFace({required this.session, required this.onTap, super.key});

  final RunSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hr = session.lastHeartRate;
    return _Face(
      label: '달리는 중',
      big: formatPace(session.paceSecondsPerKm),
      sub: '${hr > 0 ? '♥ $hr' : '♥ --'}  ·  ${formatKm(session.distanceKm)}km',
      icon: Icons.directions_run,
      onTap: onTap,
    );
  }
}

/// ③ 일시정지: 탭해서 다시 시작, 길게 눌러 종료.
class PausedFace extends StatelessWidget {
  const PausedFace({required this.onResume, required this.onFinish, super.key});

  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPress: onFinish,
        child: _Face(
          label: '일시정지',
          big: '일시정지',
          sub: '탭해서 다시 시작\n길게 눌러 끝내기',
          icon: Icons.pause_rounded,
          onTap: onResume,
        ),
      );
}

/// ④ 대회 순위 알림. 순위 데이터는 휴대폰이 중계해 준 값만 보여 주고, 없으면 아무것도 그리지 않는다.
class RankAlertFace extends StatelessWidget {
  const RankAlertFace({required this.rank, required this.gapPeople, super.key});

  final int rank;
  final int gapPeople;

  @override
  Widget build(BuildContext context) => _Face(
        label: '대회 알림',
        big: '$rank위!',
        sub: gapPeople > 0 ? '대회 $gapPeople명 앞서요' : '선두예요',
        icon: Icons.emoji_events_outlined,
      );
}

/// ⑤ 완주 요약 + 동기화 대기 상태.
class SummaryFace extends StatelessWidget {
  const SummaryFace({required this.session, required this.pendingCount, required this.onDone, super.key});

  final RunSession session;
  final int pendingCount;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => _Face(
        label: '끝',
        big: '${formatKm(session.distanceKm)}km',
        sub: '${formatPace(session.paceSecondsPerKm)}/km · ${formatMinutes(session.movingTime)}\n'
            '${pendingCount > 0 ? '휴대폰 연결 시 올려요 ($pendingCount)' : '올릴 기록 없음'}',
        icon: Icons.check_rounded,
        onTap: onDone,
      );
}
