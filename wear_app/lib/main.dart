import 'dart:async';

import 'package:flutter/material.dart';

import 'core/run_session.dart';
import 'core/sync_queue.dart';
import 'core/sync_uploader.dart';
import 'core/watch_account.dart';
import 'core/watch_haptics.dart';
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
      haptics: MethodChannelWatchHaptics(),
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
    this.haptics,
    this.tierName,
    this.tierCode,
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

  /// 진동. 없으면 진동 없이 돈다(시험).
  final WatchHaptics? haptics;

  /// 내 동물 티어 이름과 코드. 아직 워치에 티어 값을 내려 주는 길이 없어 지금은 비어 있고,
  /// 비어 있으면 시작 화면의 티어 줄은 숨긴다.
  final String? tierName;
  final String? tierCode;

  @override
  State<RunFlow> createState() => _RunFlowState();
}

class _RunFlowState extends State<RunFlow> {
  late final SyncQueue _queue = widget.queue ?? SyncQueue();
  late RunSession _session = RunSession(clock: widget.clock);
  Timer? _poller;
  Timer? _ticker;
  double _lastKm = 0;
  int _wholeKm = 0;
  int? _bannerKm;
  DateTime? _bannerUntil;
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
    _ticker?.cancel();
    unawaited(widget.sensors?.stop());
    super.dispose();
  }

  DateTime _now() => (widget.clock ?? DateTime.now)();

  void _buzz(List<int> pattern) => unawaited(widget.haptics?.pattern(pattern) ?? Future<void>.value());

  /// 1초마다 화면의 시각·경과 시간을 갱신하고, 1km 안내가 끝나면 지운다.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final until = _bannerUntil;
      if (until != null && !_now().isBefore(until)) {
        _bannerKm = null;
        _bannerUntil = null;
      }
      setState(() {});
    });
  }

  void _pause() {
    if (_session.phase != RunPhase.running) return;
    setState(_session.pause);
    _buzz(WatchHaptics.tick);
  }

  void _resume() {
    if (_session.phase != RunPhase.paused) return;
    setState(_session.resume);
    _buzz(WatchHaptics.tick);
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
    _wholeKm = 0;
    _bannerKm = null;
    _bannerUntil = null;
    setState(_session.start);
    _startTicker();
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
        // 1km를 지날 때마다 긴 진동 1회와 잠깐 안내.
        final whole = _session.distanceKm.floor();
        if (whole > _wholeKm) {
          _wholeKm = whole;
          _bannerKm = whole;
          _bannerUntil = _now().add(const Duration(seconds: 5));
          _buzz(WatchHaptics.kmPassed);
        }
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
    _ticker?.cancel();
    _ticker = null;
    _buzz(WatchHaptics.finished);
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
          onStart: _start,
          tierName: widget.tierName,
          tierCode: widget.tierCode,
          onLongPress: account == null ? null : () => setState(() => _pairing = true),
        );
      case RunPhase.running:
      case RunPhase.paused:
        return RunPager(
          session: _session,
          paused: _session.phase == RunPhase.paused,
          now: _now(),
          passedKm: _bannerKm,
          onPause: _pause,
          onResume: _resume,
          onFinish: _finish,
        );
      case RunPhase.finished:
        return SummaryFace(
          session: _session,
          pendingCount: _queue.length,
          onDone: () => setState(() {
            _session = RunSession(clock: widget.clock);
            _bannerKm = null;
            _bannerUntil = null;
          }),
        );
    }
  }
}

/// 달리는 중 화면과 조작 화면을 옆으로 넘긴다. 조작 화면으로 넘어가면 일시정지,
/// 달리는 화면으로 돌아오거나 재개를 누르면 다시 달린다.
class RunPager extends StatefulWidget {
  const RunPager({
    super.key,
    required this.session,
    required this.paused,
    required this.now,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    this.passedKm,
  });

  final RunSession session;
  final bool paused;
  final DateTime now;
  final int? passedKm;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  State<RunPager> createState() => _RunPagerState();
}

class _RunPagerState extends State<RunPager> {
  late final PageController _controller =
      PageController(initialPage: widget.paused ? 1 : 0);

  @override
  void didUpdateWidget(RunPager old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused && _controller.hasClients) {
      unawaited(_controller.animateToPage(
        widget.paused ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
        controller: _controller,
        onPageChanged: (page) {
          if (page == 1 && !widget.paused) widget.onPause();
          if (page == 0 && widget.paused) widget.onResume();
        },
        children: [
          RunningFace(
            session: widget.session,
            now: widget.now,
            passedKm: widget.passedKm,
          ),
          ControlsFace(onResume: widget.onResume, onFinish: widget.onFinish),
        ],
      );
}
