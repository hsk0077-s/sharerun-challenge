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

/// ① 시작: 목표를 고르고 탭해서 시작.
class StartFace extends StatelessWidget {
  const StartFace({required this.targetKm, required this.onStart, this.onChangeTarget, super.key});

  final double targetKm;
  final VoidCallback onStart;
  final VoidCallback? onChangeTarget;

  @override
  Widget build(BuildContext context) => _Face(
        label: '시작',
        big: '${targetKm.toStringAsFixed(0)}km',
        sub: '탭해서 시작',
        icon: Icons.play_arrow_rounded,
        onTap: onStart,
      );
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
