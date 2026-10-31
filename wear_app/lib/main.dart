import 'dart:async';

import 'package:flutter/material.dart';

import 'core/run_session.dart';
import 'core/sync_queue.dart';
import 'core/sync_uploader.dart';
import 'core/watch_account.dart';
import 'core/watch_platform.dart';
import 'screens/watch_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = MethodChannelStore();
  final account = WatchAccount(store: store);
  await account.load();
  final queueStore = QueueStore(store);
  final queue = await queueStore.load();
  runApp(ShareRunWatchApp(
    flow: RunFlow(
      queue: queue,
      sensors: MethodChannelWatchSensors(),
      account: account,
      queueStore: queueStore,
    ),
  ));
}

/// 쉐어런 워치 앱. 휴대폰 없이 단독으로 심박·걸음·GPS를 재고,
/// 6자리 코드로 연결한 계정에 기록을 올린다.
class ShareRunWatchApp extends StatelessWidget {
  const ShareRunWatchApp({super.key, this.flow = const RunFlow()});

  final Widget flow;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '쉐어런',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: flow,
      );
}

class RunFlow extends StatefulWidget {
  const RunFlow({
    super.key,
    this.queue,
    this.newId,
    this.sensors,
    this.account,
    this.queueStore,
    this.pollInterval = const Duration(seconds: 1),
    this.clock,
  });

  final SyncQueue? queue;
  final String Function()? newId;

  /// 없으면 센서 없이 화면 흐름만 돈다(시험).
  final WatchSensors? sensors;

  /// 없으면 연결 화면 없이 바로 시작 화면이다(시험).
  final WatchAccount? account;
  final QueueStore? queueStore;
  final Duration pollInterval;

  /// 시험에서 시간을 흘려보내려고 바꿔 끼운다.
  final DateTime Function()? clock;

  @override
  State<RunFlow> createState() => _RunFlowState();
}

class _RunFlowState extends State<RunFlow> {
  late final SyncQueue _queue = widget.queue ?? SyncQueue();
  late RunSession _session = RunSession(clock: widget.clock);
  Timer? _poller;
  double _lastKm = 0;
  var _pairing = false;
  var _skippedPairing = false;
  var _polling = false;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    if (account != null && account.isPaired) {
      unawaited(_upload());
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    unawaited(widget.sensors?.stop());
    super.dispose();
  }

  String _id() =>
      widget.newId?.call() ?? 'watch_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _start() async {
    final sensors = widget.sensors;
    if (sensors != null) {
      try {
        await sensors.requestPermissions();
        await sensors.start();
      } catch (_) {
        // 센서를 못 켜도 달리기는 시작한다. 거리·심박은 0으로 남는다.
      }
      _lastKm = 0;
      _poller?.cancel();
      _poller = Timer.periodic(widget.pollInterval, (_) => _poll());
    }
    if (!mounted) return;
    setState(_session.start);
  }

  Future<void> _poll() async {
    final sensors = widget.sensors;
    if (sensors == null || _polling) return;
    _polling = true;
    try {
      final snap = await sensors.read();
      if (!mounted) return;
      setState(() {
        // 일시정지 중에 늘어난 거리는 기준만 옮기고 버린다.
        _session.replaceRoute(snap.route);
        _session.addDistance(snap.distanceKm - _lastKm);
        _lastKm = snap.distanceKm;
        if (snap.heartRate > 0) _session.addHeartRate(snap.heartRate);
        _session.setSteps(snap.steps);
      });
    } catch (_) {
      // 한 번 못 읽어도 다음 주기에 다시 읽는다.
    } finally {
      _polling = false;
    }
  }

  Future<void> _finish() async {
    _poller?.cancel();
    _poller = null;
    // 마지막 값까지 받은 뒤 센서를 끈다.
    await _poll();
    try {
      await widget.sensors?.stop();
    } catch (_) {}
    _session.finish();
    final run = buildPendingRun(
      activityId: _id(),
      distanceKm: _session.distanceKm,
      movingTime: _session.movingTime,
      heartRates: _session.heartRates,
      startedAt: _session.startedAt!,
      endedAt: _session.endedAt!,
      totalSteps: _session.steps,
      gpsRoute: _session.route,
      paceSamples: _session.paceSamples,
    );
    if (run != null) {
      _queue.add(run);
      await widget.queueStore?.save(_queue);
    }
    if (mounted) setState(() {});
    unawaited(_upload());
  }

  Future<void> _upload() async {
    final account = widget.account;
    if (account == null) return;
    final uploader = SyncUploader(
      account: account,
      queue: _queue,
      onChanged: () async => widget.queueStore?.save(_queue),
    );
    final sent = await uploader.flush(deviceId: await account.deviceId());
    if (sent > 0 && mounted) setState(() {});
  }

  Future<String?> _pair(String code) async {
    final account = widget.account!;
    try {
      await account.pair(code);
    } on PairingRejected catch (e) {
      return e.message;
    } on PairingUnavailable catch (e) {
      return e.message;
    }
    if (!mounted) return null;
    setState(() => _pairing = false);
    unawaited(_upload());
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    switch (_session.phase) {
      case RunPhase.idle:
        if (account != null && (_pairing || (!account.isPaired && !_skippedPairing))) {
          return PairingFace(
            onSubmit: _pair,
            onSkip: () => setState(() {
              _pairing = false;
              _skippedPairing = true;
            }),
          );
        }
        return StartFace(
          targetKm: _session.targetKm,
          onStart: _start,
          linkedName: account != null && account.isPaired ? account.nickname : null,
          onLongPress: account == null ? null : () => setState(() => _pairing = true),
        );
      case RunPhase.running:
        return RunningFace(session: _session, onTap: () => setState(_session.pause));
      case RunPhase.paused:
        return PausedFace(onResume: () => setState(_session.resume), onFinish: _finish);
      case RunPhase.finished:
        return SummaryFace(
          session: _session,
          pendingCount: _queue.length,
          onDone: () => setState(() => _session = RunSession(clock: widget.clock)),
        );
    }
  }
}
