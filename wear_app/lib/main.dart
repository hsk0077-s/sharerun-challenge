import 'package:flutter/material.dart';

import 'core/run_session.dart';
import 'core/sync_queue.dart';
import 'screens/watch_screens.dart';

void main() => runApp(const ShareRunWatchApp());

/// 쉐어런 워치 앱. 센서 연결(심박·위치)과 휴대폰 중계는 다음 단계이고,
/// 지금은 화면 흐름과 기록 대기열까지 만든다(README 참고).
class ShareRunWatchApp extends StatelessWidget {
  const ShareRunWatchApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '쉐어런',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const RunFlow(),
      );
}

class RunFlow extends StatefulWidget {
  const RunFlow({super.key, this.queue, this.newId});

  final SyncQueue? queue;
  final String Function()? newId;

  @override
  State<RunFlow> createState() => _RunFlowState();
}

class _RunFlowState extends State<RunFlow> {
  late final SyncQueue _queue = widget.queue ?? SyncQueue();
  RunSession _session = RunSession();

  String _id() =>
      widget.newId?.call() ?? 'watch_${DateTime.now().microsecondsSinceEpoch}';

  void _finish() {
    _session.finish();
    final run = buildPendingRun(
      activityId: _id(),
      distanceKm: _session.distanceKm,
      movingTime: _session.movingTime,
      heartRates: _session.heartRates,
      startedAt: _session.startedAt!,
      endedAt: _session.endedAt!,
    );
    if (run != null) _queue.add(run);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (_session.phase) {
      case RunPhase.idle:
        return StartFace(
          targetKm: _session.targetKm,
          onStart: () => setState(_session.start),
        );
      case RunPhase.running:
        return RunningFace(session: _session, onTap: () => setState(_session.pause));
      case RunPhase.paused:
        return PausedFace(onResume: () => setState(_session.resume), onFinish: _finish);
      case RunPhase.finished:
        return SummaryFace(
          session: _session,
          pendingCount: _queue.length,
          onDone: () => setState(() => _session = RunSession()),
        );
    }
  }
}
