import 'dart:async';

import 'package:flutter/material.dart';

import 'core/run_session.dart';
import 'core/sync_queue.dart';
import 'core/sync_uploader.dart';
import 'core/watch_account.dart';
import 'core/run_draft.dart';
import 'core/watch_events.dart';
import 'core/watch_haptics.dart';
import 'core/watch_platform.dart';
import 'l10n/watch_copy.dart';
import 'screens/watch_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = MethodChannelStore();
  final account = WatchAccount(store: store, signingCert: readSigningCertSha1);
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
      events: MethodChannelWatchEvents(),
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
    this.events,
    this.tierName,
    this.tierCode,
    this.shareEarned,
    this.countdownStep = const Duration(seconds: 1),
    this.draftEvery = 15,
    this.retryEvery = const Duration(minutes: 1),
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

  /// 인터넷 연결 알림, 타일에서 바로 시작. 없으면 없는 대로 돈다(시험).
  final WatchEvents? events;

  /// 내 동물 티어 이름과 코드(시험용). 없으면 계정이 서버에서 받아 둔 티어 코드를 쓰고,
  /// 그것도 없으면(등급 전) 시작 화면의 티어 줄은 숨긴다.
  final String? tierName;
  final String? tierCode;

  /// 이번 달리기로 쌓인 SHARE. 워치에 SHARE 값을 내려 주는 길이 아직 없어 지금은 null이고,
  /// null이면 화면의 SHARE 표시는 숨긴다. 가짜 숫자를 넣지 않는다.
  final int? shareEarned;

  /// 시작을 누른 뒤 3·2·1 사이의 간격.
  final Duration countdownStep;

  /// 달리는 중 임시 기록을 저장하는 간격(초).
  final int draftEvery;

  /// 올리지 못한 기록이 있으면 이 간격으로 다시 올려 본다(앱이 켜져 있는 동안).
  final Duration retryEvery;

  @override
  State<RunFlow> createState() => _RunFlowState();
}

class _RunFlowState extends State<RunFlow> with WidgetsBindingObserver {
  late final SyncQueue _queue = widget.queue ?? SyncQueue();
  late RunSession _session = RunSession(clock: widget.clock);
  Timer? _poller;
  Timer? _ticker;
  Timer? _retry;
  Timer? _countdownTimer;
  int? _countdown;
  double _lastKm = 0;
  int _wholeKm = 0;
  int? _bannerKm;
  DateTime? _bannerUntil;
  int _focus = 0;
  int _tickCount = 0;
  String? _runId;
  var _pairing = false;
  var _skippedPairing = false;
  var _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final account = widget.account;
    if (account != null && account.isPaired) {
      unawaited(_upload());
    }
    unawaited(_recoverDraft());
    widget.events?.onNetworkAvailable(() => unawaited(_upload()));
    widget.events?.onAutostartRequested(_beginCountdown);
    unawaited(_checkAutostart());
    _retry = Timer.periodic(widget.retryEvery, (_) {
      if (_queue.length > 0) unawaited(_upload());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    _ticker?.cancel();
    _retry?.cancel();
    _countdownTimer?.cancel();
    unawaited(widget.sensors?.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 다시 앞으로 나오면 올리지 못한 기록을 올려 본다.
    if (state == AppLifecycleState.resumed && _queue.length > 0) {
      unawaited(_upload());
    }
  }

  DateTime _now() => (widget.clock ?? DateTime.now)();

  void _buzz(List<int> pattern) =>
      unawaited(widget.haptics?.pattern(pattern) ?? Future<void>.value());

  /// 달리는 도중 앱이 죽었다면 임시 기록을 올릴 기록으로 되살린다.
  Future<void> _recoverDraft() async {
    final store = widget.queueStore;
    if (store == null) return;
    final draft = await store.loadDraft();
    if (draft == null || _runId != null) return;
    final run = draft.toPendingRun();
    if (run != null) {
      _queue.add(run);
      await store.save(_queue);
    }
    await store.clearDraft();
    if (!mounted) return;
    setState(() {});
    unawaited(_upload());
  }

  /// 시계 타일로 열렸으면 바로 카운트다운을 시작한다.
  Future<void> _checkAutostart() async {
    final events = widget.events;
    if (events == null) return;
    final requested = await events.consumeAutostart();
    if (requested && mounted) _beginCountdown();
  }

  /// 1초마다 화면의 시각·경과 시간을 갱신하고, 1km 안내가 끝나면 지우고, 임시 기록을 저장한다.
  void _startTicker() {
    _ticker?.cancel();
    _tickCount = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final until = _bannerUntil;
      if (until != null && !_now().isBefore(until)) {
        _bannerKm = null;
        _bannerUntil = null;
      }
      _tickCount++;
      if (widget.draftEvery > 0 && _tickCount % widget.draftEvery == 0) {
        unawaited(_saveDraft());
      }
      setState(() {});
    });
  }

  Future<void> _saveDraft() async {
    final store = widget.queueStore;
    final id = _runId;
    final started = _session.startedAt;
    if (store == null || id == null || started == null) return;
    if (_session.phase != RunPhase.running && _session.phase != RunPhase.paused) return;
    await store.saveDraft(RunDraft(
      activityId: id,
      startedAt: started,
      savedAt: _now(),
      movingSeconds: _session.movingTime.inSeconds,
      distanceKm: _session.distanceKm,
      steps: _session.steps,
      heartRates: _session.heartRates,
      route: _session.route,
      paceSamples: _session.paceSamples,
    ));
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

  /// 시작을 누르면 3·2·1을 센다. 숫자마다 아주 짧은 진동, 시작 때 길게 한 번.
  void _beginCountdown() {
    if (_session.phase != RunPhase.idle || _countdown != null) return;
    setState(() => _countdown = 3);
    _buzz(WatchHaptics.countdown);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(widget.countdownStep, (timer) {
      final next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        _countdownTimer = null;
        if (!mounted) return;
        setState(() => _countdown = null);
        unawaited(_start());
      } else {
        setState(() => _countdown = next);
        _buzz(WatchHaptics.countdown);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    setState(() => _countdown = null);
  }

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
    _runId = _id();
    _wholeKm = 0;
    _bannerKm = null;
    _bannerUntil = null;
    _focus = 0;
    setState(_session.start);
    _buzz(WatchHaptics.go);
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
      activityId: _runId ?? _id(),
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
    // 올릴 기록으로 안전하게 저장했으니 임시 기록은 지운다.
    await widget.queueStore?.clearDraft();
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
    if (mounted && (sent > 0 || account.reconnectNeeded)) setState(() {});
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
    final countdown = _countdown;
    if (countdown != null && _session.phase == RunPhase.idle) {
      return CountdownFace(count: countdown, onCancel: _cancelCountdown);
    }
    switch (_session.phase) {
      case RunPhase.idle:
        if (account != null &&
            (_pairing || account.reconnectNeeded || (!account.isPaired && !_skippedPairing))) {
          return PairingFace(
            onSubmit: _pair,
            notice: account.reconnectNeeded
                ? watchUi(WidgetsBinding.instance.platformDispatcher.locale, 'reconnect')
                : null,
            onSkip: () {
              unawaited(account.dismissReconnect());
              setState(() {
                _pairing = false;
                _skippedPairing = true;
              });
            },
          );
        }
        return StartFace(
          onStart: _beginCountdown,
          tierName: widget.tierName,
          tierCode: widget.tierCode ?? account?.tierCode,
          pendingCount: _queue.length,
          onLongPress: account == null ? null : () => setState(() => _pairing = true),
        );
      case RunPhase.running:
      case RunPhase.paused:
        return RunPager(
          session: _session,
          paused: _session.phase == RunPhase.paused,
          now: _now(),
          passedKm: _bannerKm,
          focus: _focus,
          shareEarned: widget.shareEarned,
          tierCode: widget.tierCode ?? account?.tierCode,
          onCycle: () => setState(() => _focus = (_focus + 1) % RunningFace.metricCount),
          onPause: _pause,
          onResume: _resume,
          onFinish: _finish,
        );
      case RunPhase.finished:
        return SummaryFace(
          session: _session,
          shareEarned: widget.shareEarned,
          onDone: () => setState(() {
            _session = RunSession(clock: widget.clock);
            _bannerKm = null;
            _bannerUntil = null;
            _runId = null;
          }),
        );
    }
  }
}

/// 가운데가 달리는 화면이고, 오른쪽으로 밀면(왼쪽 가장자리에서 오른쪽으로) 경로 화면,
/// 왼쪽으로 밀면 조작 화면이다. 조작 화면으로 넘어가면 일시정지,
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
    this.focus = 0,
    this.onCycle,
    this.shareEarned,
    this.tierCode,
  });

  final int? shareEarned;
  final String? tierCode;
  final RunSession session;
  final bool paused;
  final DateTime now;
  final int? passedKm;
  final int focus;
  final VoidCallback? onCycle;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  static const routePage = 0;
  static const runPage = 1;
  static const controlsPage = 2;

  @override
  State<RunPager> createState() => _RunPagerState();
}

class _RunPagerState extends State<RunPager> {
  late final PageController _controller = PageController(
    initialPage: widget.paused ? RunPager.controlsPage : RunPager.runPage,
  );

  @override
  void didUpdateWidget(RunPager old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused && _controller.hasClients) {
      unawaited(_controller.animateToPage(
        widget.paused ? RunPager.controlsPage : RunPager.runPage,
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
          if (page == RunPager.controlsPage && !widget.paused) widget.onPause();
          if (page != RunPager.controlsPage && widget.paused) widget.onResume();
        },
        children: [
          RouteFace(session: widget.session),
          RunningFace(
            session: widget.session,
            now: widget.now,
            passedKm: widget.passedKm,
            focus: widget.focus,
            onCycle: widget.onCycle,
            shareEarned: widget.shareEarned,
            tierCode: widget.tierCode,
          ),
          ControlsFace(onResume: widget.onResume, onFinish: widget.onFinish),
        ],
      );
}
