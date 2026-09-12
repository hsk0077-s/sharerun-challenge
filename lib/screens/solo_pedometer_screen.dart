import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/app_providers.dart';
import '../core/constants/economy_constants.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/pedometer/solo_pedometer_engine.dart';
import '../features/pedometer/solo_pedometer_foreground.dart';
import '../features/pedometer/debug_local_harvest.dart';
import '../features/pedometer/pedometer_day_rollover.dart';
import '../features/pedometer/pedometer_harvest_ledger.dart';
import '../features/pedometer/pedometer_step_truth.dart';
import '../features/pedometer/walking_challenge_notification_service.dart';
import '../features/pedometer/walking_look.dart';
import '../features/voice_coaching/voice_coaching_providers.dart';
import '../features/voice_coaching/widgets/voice_coaching_walk_banner.dart';
import '../features/profile/providers/practice_streak_provider.dart';
import '../features/profile/user_profile_notifier.dart';
import '../features/wallet/debug_economy_status.dart';
import '../features/wallet/debug_local_wallet_store.dart';
import '../features/wallet/providers/debug_local_share_history_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import 'my_wallet_screen.dart';

class PedometerData {
  const PedometerData({
    required this.steps,
    required this.km,
    required this.isMoving,
  });

  final int steps;
  final double km;
  final bool isMoving;
}

final pedometerStateProvider =
    StateNotifierProvider<PedometerNotifier, PedometerData>((ref) {
  return PedometerNotifier(ref);
});

class PedometerNotifier extends StateNotifier<PedometerData> {
  final Ref _ref;
  PedometerNotifier(this._ref)
      : super(const PedometerData(steps: 0, km: 0.0, isMoving: false)) {
    _ready = _loadPersistedData();
  }

  late final Future<void> _ready;

  /// SharedPreferences 복원(및 0보일 때 Firestore 원격 복원)이 끝날 때까지 대기.
  Future<void> ensureCloudRecovery() async {
    await _ready;
    await _loadPersistedData();
  }

  /// SharedPreferences(로컬) + Firestore(클라우드) 이중 복원 엔진
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getTodayKey();
      // 1. 먼저 로컬 SharedPreferences 확인
      int savedSteps = prefs.getInt('${todayKey}_steps') ?? 0;
      double savedKm = prefs.getDouble('${todayKey}_km') ?? 0.0;
      // 2. 만약 기기 변경 등으로 로컬 걸음수가 0보라면, 클라우드(Firestore)에서 오늘치 데이터 조회 및 복원
      if (savedSteps == 0) {
        final userProfile = _ref.read(userProfileProvider);
        final uid = userProfile.uid;
        if (uid.isNotEmpty) {
          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('daily_metrics')
              .doc(todayKey)
              .get();
          if (docSnapshot.exists) {
            final data = docSnapshot.data();
            if (data != null) {
              final latestLocal = prefs.getInt('${todayKey}_steps') ?? 0;
              if (latestLocal > 0) {
                savedSteps = latestLocal;
                savedKm = prefs.getDouble('${todayKey}_km') ?? savedKm;
              } else {
                savedSteps = (data['steps'] as num?)?.toInt() ?? 0;
                savedKm = (data['km'] as num?)?.toDouble() ?? 0.0;
                // 로컬 SharedPreferences에 클라우드 데이터 강제 주입
                await prefs.setInt('${todayKey}_steps', savedSteps);
                await prefs.setDouble('${todayKey}_km', savedKm);
                debugPrint(
                  '[CLOUD RECOVERY] 새 기기에서 오늘자 걸음 수 ($savedSteps보) 원격 복원 완료.',
                );
              }
            }
          }
        }
      }
      if (state.steps > savedSteps) {
        savedSteps = state.steps;
        savedKm = state.km;
      }
      state = PedometerData(
        steps: savedSteps,
        km: savedKm,
        isMoving: false,
      );
    } catch (e) {
      debugPrint('[PERSISTENCE] 로컬/원격 데이터 복원 실패: $e');
    }
  }

  /// 로컬 백업 완료 후 즉시 클라우드 Firestore 비동기 실시간 동기화
  Future<void> updateSteps(int steps, double km, {required bool isMoving}) async {
    state = PedometerData(steps: steps, km: km, isMoving: isMoving);
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getTodayKey();
      // 1) 로컬 저장소 즉시 영구 기록 (빠른 렌더링 유지)
      await prefs.setInt('${todayKey}_steps', steps);
      await prefs.setDouble('${todayKey}_km', km);
      await _updateWeeklyHistory(prefs, todayKey, steps);
      // 2) 클라우드 영구 백업 (기기 변경 대비)
      final userProfile = _ref.read(userProfileProvider);
      final uid = userProfile.uid;
      if (uid.isEmpty) return;
      // 비동기로 백그라운드에서 동기화하여 UI 스레드 지연을 원천 차단
      unawaited(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('daily_metrics')
            .doc(todayKey)
            .set({
          'steps': steps,
          'km': km,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((Object e) {
          debugPrint('[CLOUD SYNC ERR] Firestore 걸음 수 백업 실패: $e');
        }),
      );
    } catch (e) {
      debugPrint('[PERSISTENCE] 이중 동기화 실패: $e');
    }
  }

  String _getTodayKey() => PedometerKstClock.dateKey();

  Future<void> _updateWeeklyHistory(
    SharedPreferences prefs,
    String dateKey,
    int steps,
  ) async {
    List<String> history = prefs.getStringList('pedometer_weekly_history') ?? [];
    final existingIndex = history.indexWhere((item) => item.startsWith(dateKey));
    if (existingIndex != -1) {
      history[existingIndex] = '$dateKey:$steps';
    } else {
      history.add('$dateKey:$steps');
    }
    if (history.length > 7) {
      history.removeRange(0, history.length - 7);
    }
    await prefs.setStringList('pedometer_weekly_history', history);
  }
}

/// 다마고치형 웰니스 산책 — 티어별 차등 채굴 + Tap-to-Claim.
class SoloPedometerScreen extends ConsumerStatefulWidget {
  const SoloPedometerScreen({super.key});

  @override
  ConsumerState<SoloPedometerScreen> createState() =>
      _SoloPedometerScreenState();
}

class _SoloPedometerScreenState extends ConsumerState<SoloPedometerScreen>
    with WidgetsBindingObserver, PedometerHealthLifecycle {
  final _engine = SoloPedometerEngine();
  final _health = Health();
  StreamSubscription<StepCount>? _pedoSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  Timer? _stillTimer;

  var _steps = 0;
  var _km = 0.0;
  var _isMoving = false;
  var _collectedShareCoins = 0.0;
  var _claimedSteps = 0;
  var _stepOffset = 0;
  var _isOffsetCaptured = false;
  var _lastSavedDate = '';
  var _isClaimedDataLoaded = false;
  var _walletShareFloor = 0;
  var _isNotificationEnabled = true;
  final _claimingIds = <int>{};
  final _claimedTenths = <int>{};
  var _unclaimedCoins = <FloatingCoin>[];
  var _flyingCoins = <FloatingCoin>[];
  var _syncing = false;
  var _healthBase = 0;
  var _baselineSteps = 0;
  var _baselineReady = false;
  var _sessionDelta = 0;
  var _kstDayKey = '';
  var _weekSteps = <String, int>{};
  var _selectedDayKey = '';
  var _streakReportedForDay = '';
  var _hasReceivedMilestone1 = false;
  var _hasReceivedMilestone2 = false;
  var _hasReceivedMilestone3 = false;
  var _hasReceivedBonus = false;
  var _rewardGrantInFlight = false;
  var _harvestInFlight = false;
  var _mascotPickupNonce = 0;
  Timer? _goldenPushDebounce;
  Timer? _healthPollTimer;
  var _pedoRebindInFlight = false;
  DateTime? _lastPedoRebindAt;

  UserTier get _tier =>
      ref.read(activeUserTierStructProvider) ?? UserTier.unratedFallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoloPedometerForeground.addLiveStepsListener(_onIsolateSteps);
    unawaited(() async {
      await _restoreTodayFromPrefs();
      await _loadClaimedData();
    }());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initForegroundTask();
      unawaited(initPedometerSystem());
    });
  }

  Future<void> initPedometerSystem() async {
    try {
      await _restoreTodayFromPrefs();
      if (!mounted) return;
      await _restoreClaims();
      try {
        await Permission.activityRecognition.request();
      } on PlatformException catch (e, st) {
        debugPrint('initPedometerSystem activityRecognition: $e\n$st');
      }
      try {
        await Permission.sensors.request();
      } on PlatformException catch (e, st) {
        debugPrint('initPedometerSystem sensors: $e\n$st');
      } catch (e, st) {
        debugPrint('initPedometerSystem sensors: $e\n$st');
      }
      if (!mounted) return;
      try {
        await _health.configure();
        await _health.requestAuthorization(const [HealthDataType.STEPS]);
      } on PlatformException catch (e, st) {
        debugPrint('initPedometerSystem requestAuthorization: $e\n$st');
      }
      if (!mounted) return;
      await syncBackgroundSteps();
      if (!mounted) return;
      await _loadClaimedData();
      if (!mounted) return;
      await _listenOsPedometer(reason: 'init');
      if (!mounted) return;
      if (_isNotificationEnabled) {
        unawaited(
          SoloPedometerForeground.start(
            steps: _steps,
            targetKm: _tier.targetKm,
            healthBase: _healthBase,
            claimedSteps: _claimedSteps,
            pendingShare: _computePendingShare(_steps),
          ),
        );
      }
      unawaited(_pullLiveStepsFromService());
      _healthPollTimer?.cancel();
      _healthPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        unawaited(syncBackgroundSteps(requestIfMissing: false));
      });
      _scheduleGoldenPushes();
      unawaited(_announceWalkingCoachStart());
    } on PlatformException catch (e, st) {
      debugPrint('initPedometerSystem PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('initPedometerSystem: $e\n$st');
    }
  }

  /// Re-bind TYPE_STEP_COUNTER after background, USB `flutter run` detach, or
  /// EventChannel `FlutterJNI was detached` (channels `step_count` /
  /// `step_detection`). A dead subscription is why shake stopped while Health
  /// Connect still returned ~1,834.
  Future<void> _listenOsPedometer({required String reason}) async {
    if (!mounted || _pedoRebindInFlight) return;
    final now = DateTime.now();
    if (!PedometerStepTruth.shouldRebindSensor(
      now: now,
      lastRebindAt: _lastPedoRebindAt,
      force: reason == 'init' || reason == 'resume',
    )) {
      return;
    }
    _pedoRebindInFlight = true;
    _lastPedoRebindAt = now;
    try {
      await _pedoSub?.cancel();
      await _statusSub?.cancel();
      _pedoSub = null;
      _statusSub = null;
      _baselineReady = false;
      _sessionDelta = 0;
      debugPrint(
        '${PedometerStepTruth.sourceLog(
          source: 'sensor-rebind',
          daily: _steps,
          offset: _stepOffset,
          healthBase: _healthBase,
          ui: _steps,
        )} reason=$reason',
      );
      _pedoSub = Pedometer.stepCountStream.listen(
        _onPedometerEvent,
        onError: (Object error, StackTrace stack) {
          debugPrint('Pedometer.stepCountStream: $error\n$stack');
          unawaited(_listenOsPedometer(reason: 'stream-error'));
        },
        onDone: () {
          debugPrint('${PedometerStepTruth.logPrefix} source=sensor-done');
          unawaited(_listenOsPedometer(reason: 'stream-done'));
        },
        cancelOnError: false,
      );
      try {
        _statusSub = Pedometer.pedestrianStatusStream.listen(
          _onPedestrianStatus,
          onError: (Object error, StackTrace stack) {
            debugPrint('Pedometer.pedestrianStatusStream: $error\n$stack');
          },
          cancelOnError: false,
        );
      } on PlatformException catch (e, st) {
        debugPrint('_listenOsPedometer pedestrianStatus: $e\n$st');
      } catch (e, st) {
        debugPrint('_listenOsPedometer pedestrianStatus: $e\n$st');
      }
    } on PlatformException catch (e, st) {
      debugPrint('_listenOsPedometer PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('_listenOsPedometer: $e\n$st');
    } finally {
      _pedoRebindInFlight = false;
    }
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    try {
      final status = event.status.toLowerCase();
      _setMoving(status == 'walking' || status == 'running');
    } on PlatformException catch (e, st) {
      debugPrint('_onPedestrianStatus PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('_onPedestrianStatus: $e\n$st');
    }
  }

  void _setMoving(bool moving) {
    if (!mounted) return;
    if (_isMoving == moving) return;
    setState(() => _isMoving = moving);
  }

  void _onPedometerEvent(StepCount event) {
    try {
      final raw = event.steps;
      if (!_baselineReady) {
        _baselineSteps = raw;
        _baselineReady = true;
        debugPrint(
          PedometerStepTruth.sourceLog(
            source: 'sensor-baseline',
            daily: _steps,
            raw: raw,
            offset: _stepOffset,
            healthBase: _healthBase,
            sessionDelta: 0,
            ui: _steps,
          ),
        );
      } else {
        _sessionDelta = math.max(0, raw - _baselineSteps);
      }
      if (!mounted) return;
      _setMoving(true);
      _stillTimer?.cancel();
      _stillTimer = Timer(const Duration(seconds: 3), () {
        _setMoving(false);
      });
      final next = PedometerStepTruth.fromSensorEvent(
        raw: raw,
        healthBase: _healthBase,
        sessionDelta: _sessionDelta,
        stepOffset: _stepOffset,
      );
      debugPrint(
        PedometerStepTruth.sourceLog(
          source: 'sensor',
          daily: next,
          raw: raw,
          offset: _stepOffset,
          healthBase: _healthBase,
          sessionDelta: _sessionDelta,
          ui: _steps,
        ),
      );
      _applyDailySteps(next, source: 'sensor');
    } on PlatformException catch (e, st) {
      debugPrint('_onPedometerEvent PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('_onPedometerEvent: $e\n$st');
    }
  }

  @override
  Future<void> syncBackgroundSteps({bool requestIfMissing = true}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      if (requestIfMissing) {
        await Permission.activityRecognition.request();
      }
      final total = await PedometerKstClock.queryTodaySteps(
        _health,
        requestIfMissing: requestIfMissing,
      );
      if (!mounted) return;
      final todayKey = PedometerKstClock.dateKey();
      final rolled = _kstDayKey.isNotEmpty && _kstDayKey != todayKey;
      if (rolled) {
        _ensureDailyRollover(sensorTotal: math.max(_steps, 0) + _stepOffset);
      }
      _kstDayKey = todayKey;
      if (total != null) {
        if (rolled) {
          return;
        }
        var next = math.max(total, _steps);
        next = math.max(next, await SoloPedometerForeground.liveSteps());
        debugPrint(
          PedometerStepTruth.sourceLog(
            source: 'health',
            daily: next,
            raw: total,
            offset: _stepOffset,
            healthBase: _healthBase,
            sessionDelta: _sessionDelta,
            ui: _steps,
          ),
        );
        // Only re-anchor the pedometer session when Health raises the floor.
        // A periodic poll that always reset the baseline swallowed Samsung
        // shake/step events (first event after each poll became a no-op).
        if (next > _healthBase) {
          _healthBase = next;
          _sessionDelta = 0;
          _baselineReady = false;
        } else {
          _healthBase = math.max(_healthBase, total);
        }
        _applyDailySteps(next, source: 'health');
        unawaited(_syncForegroundNotification(math.max(next, _steps)));
        return;
      }
      debugPrint(
        PedometerStepTruth.sourceLog(
          source: 'health-miss',
          daily: _steps,
          offset: _stepOffset,
          healthBase: _healthBase,
          ui: _steps,
        ),
      );
      if (_steps > 0) {
        unawaited(
          ref.read(pedometerStateProvider.notifier).updateSteps(
                _steps,
                _km,
                isMoving: _isMoving,
              ),
        );
        unawaited(_syncForegroundNotification(_steps));
      }
    } on PlatformException catch (e, st) {
      debugPrint('syncBackgroundSteps PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('syncBackgroundSteps: $e\n$st');
    } finally {
      _syncing = false;
    }
  }

  bool _ensureDailyRollover({required int sensorTotal}) {
    final todayIso = PedometerDayRollover.todayKey();
    if (!PedometerDayRollover.canEvaluate(_lastSavedDate)) {
      return false;
    }
    if (!PedometerDayRollover.needsRollover(
      lastSavedDate: _lastSavedDate,
      todayKey: todayIso,
    )) {
      return false;
    }
    final plan = PedometerDayRollover.plan(
      todayKey: todayIso,
      sensorTotal: sensorTotal,
    );
    _stepOffset = plan.stepOffset;
    _steps = plan.steps;
    _km = plan.km;
    _collectedShareCoins = plan.collectedShare;
    _claimedSteps = plan.claimedSteps;
    _hasReceivedMilestone1 = plan.milestone1;
    _hasReceivedMilestone2 = plan.milestone2;
    _hasReceivedMilestone3 = plan.milestone3;
    _hasReceivedBonus = plan.bonus;
    _lastSavedDate = plan.dateKey;
    _kstDayKey = plan.dateKey;
    _streakReportedForDay = '';
    _claimedTenths.clear();
    _unclaimedCoins = const [];
    _flyingCoins = const [];
    if (mounted) {
      setState(() {
        _weekSteps = {..._weekSteps, _kstDayKey: 0};
      });
      unawaited(
        ref.read(pedometerStateProvider.notifier).updateSteps(
              0,
              0.0,
              isMoving: false,
            ),
      );
    }
    unawaited(_persistDailyResetState());
    ref.read(voiceCoachingControllerProvider).session.resetWalkDay();
    return true;
  }

  Future<void> _persistDailyResetState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastSavedDate', _lastSavedDate);
      await prefs.setInt('stepOffset', _stepOffset);
      await prefs.setInt('${_lastSavedDate}_step_offset', _stepOffset);
      await prefs.setDouble('collected_share_coins', _collectedShareCoins);
      await prefs.setBool('src_smart_push_fired_morning', false);
      await prefs.setBool('src_smart_push_fired_lunch', false);
      await prefs.setBool('src_smart_push_fired_evening', false);
      await prefs.setBool('src_smart_push_sniped_m1', false);
      await prefs.setBool('src_smart_push_sniped_m2', false);
      await prefs.setBool('src_smart_push_sniped_m3', false);
      await prefs.setString('src_smart_push_date', _lastSavedDate);
      final prefix = await _prefPrefix();
      await prefs.setBool('$prefix.hasReceivedMilestone1', false);
      await prefs.setBool('$prefix.hasReceivedMilestone2', false);
      await prefs.setBool('$prefix.hasReceivedMilestone3', false);
      await prefs.setBool('$prefix.hasReceivedBonus', false);
      await prefs.setDouble('$prefix.collectedShare', 0);
      await prefs.setInt('$prefix.claimedSteps', 0);
      await prefs.setInt('${_lastSavedDate}_claimed_steps', 0);
      await prefs.setInt(PedometerHarvestLedger.globalClaimedKey, 0);
      await prefs.setString(
        PedometerHarvestLedger.globalClaimedDateKey,
        _lastSavedDate,
      );
      await prefs.setInt('$prefix.steps', _steps);
      await prefs.setDouble('$prefix.km', _km);
      final ymd = PedometerKstClock.dateKey();
      await prefs.setInt(PedometerKstClock.backupStepsKey(ymd), _steps);
      await prefs.setDouble(PedometerKstClock.backupKmKey(ymd), _km);
    } catch (e) {
      debugPrint('_persistDailyResetState: $e');
    }
  }

  void _applyDailySteps(int steps, {required String source}) {
    if (!mounted) return;
    _ensureDailyRollover(
      sensorTotal: math.max(steps, _steps) + _stepOffset,
    );
    final effective = PedometerStepTruth.clampDaily(steps);
    debugPrint(
      PedometerStepTruth.sourceLog(
        source: 'apply-$source',
        daily: effective,
        offset: _stepOffset,
        healthBase: _healthBase,
        sessionDelta: _sessionDelta,
        ui: _steps,
      ),
    );
    if (effective <= _steps) return;
    final previousSteps = _steps;
    final previousKm = _km;
    final km = SoloPedometerEngine.kmFromSteps(effective);
    final todayKey = PedometerKstClock.dateKey();
    setState(() {
      _steps = effective;
      _km = km;
      _kstDayKey = todayKey;
      _weekSteps = {..._weekSteps, todayKey: effective};
      if (_selectedDayKey.isEmpty) _selectedDayKey = todayKey;
    });
    unawaited(
      ref.read(pedometerStateProvider.notifier).updateSteps(
            effective,
            km,
            isMoving: _isMoving,
          ),
    );
    _spawnCoinsForKm(km);
    _refreshPendingShare(effective);
    unawaited(_persistKm(km, steps: effective, syncRemote: false));
    unawaited(_syncForegroundNotification(effective));
    unawaited(_maybeGrantLockedRewards(effective));
    unawaited(
      ref.read(voiceCoachingControllerProvider).onWalkingProgress(
            previousSteps: previousSteps,
            currentSteps: effective,
            previousKm: previousKm,
            currentKm: km,
            targetKm: _tier.targetKm,
          ),
    );
  }

  void _onIsolateSteps(int steps) {
    if (!mounted) return;
    _ensureDailyRollover(
      sensorTotal: math.max(steps, _steps) + _stepOffset,
    );
    if (steps <= _steps) {
      unawaited(_syncForegroundNotification(_steps));
      return;
    }
    _healthBase = steps;
    _sessionDelta = 0;
    _baselineReady = false;
    _applyDailySteps(steps, source: 'isolate');
  }

  Future<void> _pullLiveStepsFromService() async {
    try {
      final live = await SoloPedometerForeground.liveSteps();
      if (!mounted) return;
      _onIsolateSteps(live);
    } on PlatformException catch (e, st) {
      debugPrint('_pullLiveStepsFromService PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('_pullLiveStepsFromService: $e\n$st');
    }
  }

  void initForegroundTask() {
    try {
      SoloPedometerForeground.initForegroundTask();
    } on PlatformException catch (e, st) {
      debugPrint('initForegroundTask PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('initForegroundTask: $e\n$st');
    }
  }

  Future<void> _syncForegroundNotification(int steps) async {
    try {
      _scheduleGoldenPushes();
      if (!_isNotificationEnabled) return;
      await SoloPedometerForeground.update(
        steps: steps,
        targetKm: _tier.targetKm,
        healthBase: _healthBase,
        claimedSteps: _claimedSteps,
        pendingShare: _computePendingShare(steps),
      );
    } on PlatformException catch (e, st) {
      debugPrint('_syncForegroundNotification PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('_syncForegroundNotification: $e\n$st');
    }
  }

  void _scheduleGoldenPushes() {
    _goldenPushDebounce?.cancel();
    _goldenPushDebounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      unawaited(
        WalkingChallengeNotificationService.syncDailyPushes(
          enabled: _isNotificationEnabled,
          nickname: ref.read(userNicknameProvider),
          pendingShare: _computePendingShare(
            math.max(ref.read(pedometerStateProvider).steps, _steps),
          ),
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _ensureDailyRollover(
        sensorTotal: math.max(_steps, 0) + _stepOffset,
      );
      unawaited(_listenOsPedometer(reason: 'resume'));
      unawaited(_pullLiveStepsFromService());
      unawaited(syncBackgroundSteps());
      unawaited(_syncForegroundNotification(_steps));
      if (_isNotificationEnabled) {
        unawaited(
          SoloPedometerForeground.ensureAlive(
            steps: _steps,
            targetKm: _tier.targetKm,
          ),
        );
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_persistKm(_km, steps: _steps, syncRemote: true));
      unawaited(_persistClaims());
    }
  }

  void _openMyWallet() {
    if (!mounted) return;
    MyWalletScreen.open(context);
  }

  void _goHomeSafe() {
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.go(RouteNames.mainDashboard);
      return;
    }
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }

  void _spawnCoinsForKm(double km) {
    // [2단 락] 거리 비례 무한 코인 스폰 잠금 — 완주/만보 보상만 지급.
    if (km < 0) return;
  }

  void _onClaim(FloatingCoin coin) {
    if (_claimingIds.contains(coin.tenthIndex) ||
        _claimedTenths.contains(coin.tenthIndex)) {
      return;
    }
    _claimingIds.add(coin.tenthIndex);
    HapticFeedback.heavyImpact();
    setState(() {
      _unclaimedCoins = _unclaimedCoins
          .where((c) => c.tenthIndex != coin.tenthIndex)
          .toList();
      _flyingCoins = [..._flyingCoins, coin];
    });
  }

  Future<void> _onFlyArrived(FloatingCoin coin) async {
    _claimedTenths.add(coin.tenthIndex);
    if (mounted) {
      setState(() {
        _flyingCoins =
            _flyingCoins.where((c) => c.tenthIndex != coin.tenthIndex).toList();
      });
    }
    try {
      // [2단 락] 코인 탭 1 SHARE 무한 지급 잠금.
      await _persistClaims();
    } finally {
      _claimingIds.remove(coin.tenthIndex);
    }
  }

  Future<String> _prefPrefix() async {
    final uid = _harvestUid();
    final key = PedometerKstClock.dateKey();
    return PedometerHarvestLedger.prefix(uid: uid, dateKey: key);
  }

  static int _prefToInt(Object? raw, [int fallback = 0]) {
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return fallback;
  }

  String _getTodayKey() => PedometerKstClock.dateKey();

  Future<void> _loadClaimedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getTodayKey();

      // [원천 초기화 가드 - 최초 1회만 전역 강제 리셋]
      final hasBeenReset = prefs.getBool('is_pedometer_reset_v3_done') ?? false;
      if (!hasBeenReset) {
        await prefs.remove('pedometer_weekly_history');
        await prefs.remove('${todayKey}_step_offset');
        await prefs.remove('${todayKey}_claimed_steps');
        await prefs.setDouble('collected_share_coins', 0.0);
        await prefs.setBool('is_pedometer_reset_v3_done', true);

        if (!mounted) return;
        setState(() {
          _collectedShareCoins = 0.0;
          _claimedSteps = 0;
          _stepOffset = 0;
          _isOffsetCaptured = false;
          _weekSteps = {};
          _isClaimedDataLoaded = true;
        });
        await _loadWeeklyHistory();
        _updatePendingAmount();
        return;
      }
      if (_lastSavedDate.isEmpty) {
        _lastSavedDate = prefs.getString('lastSavedDate') ?? '';
      }
      if (_lastSavedDate.isEmpty) {
        _lastSavedDate = todayKey;
        unawaited(prefs.setString(
          PedometerDayRollover.lastSavedDateKey,
          todayKey,
        ));
      }
      final prefix = await _prefPrefix();
      final rolled = _ensureDailyRollover(
        sensorTotal: math.max(_steps, 0) + _stepOffset,
      );
      if (!mounted) return;
      final sameKstDay = !rolled && _lastSavedDate == todayKey;
      setState(() {
        _isOffsetCaptured = true;
        _isClaimedDataLoaded = true;
        if (sameKstDay) {
          _claimedSteps = PedometerHarvestLedger.coalesceClaimed(
            current: _claimedSteps,
            fromTodayKey: _prefToInt(
              prefs.get(PedometerHarvestLedger.todayClaimedKey(todayKey)),
            ),
            fromPrefix: _prefToInt(prefs.get('$prefix.claimedSteps')),
            fromGlobal: PedometerHarvestLedger.claimedFromGlobal(
              storedDate:
                  prefs.getString(PedometerHarvestLedger.globalClaimedDateKey),
              storedClaimed: _prefToInt(
                prefs.get(PedometerHarvestLedger.globalClaimedKey),
              ),
              todayKey: todayKey,
            ),
            steps: _steps,
          );
          _collectedShareCoins =
              prefs.getDouble('collected_share_coins') ?? _collectedShareCoins;
        } else {
          _claimedSteps = 0;
          _collectedShareCoins = 0;
        }
      });
      _updatePendingAmount();
    } catch (e) {
      debugPrint('[PERSISTENCE] 데이터 로딩 실패: $e');
    }
  }

  Future<void> _loadWeeklyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final week = <String, int>{};
      for (final day in PedometerKstClock.thisWeekDays()) {
        week[day.key] =
            prefs.getInt(PedometerKstClock.backupStepsKey(day.key)) ?? 0;
      }
      if (!mounted) return;
      setState(() => _weekSteps = week);
    } catch (e) {
      debugPrint('_loadWeeklyHistory: $e');
    }
  }

  double _computePendingShare(int steps) {
    return PedometerHarvestLedger.pendingShareExact(
      steps: steps,
      claimedSteps: _claimedSteps,
    );
  }

  Future<void> _persistClaimedWatermark(int claimed) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();
    await prefs.setInt(
      PedometerHarvestLedger.todayClaimedKey(todayKey),
      claimed,
    );
    await prefs.setInt(PedometerHarvestLedger.globalClaimedKey, claimed);
    await prefs.setString(
      PedometerHarvestLedger.globalClaimedDateKey,
      todayKey,
    );
    try {
      final prefix = await _prefPrefix();
      await prefs.setInt('$prefix.claimedSteps', claimed);
      await prefs.setDouble(
        '$prefix.pendingShare',
        PedometerHarvestLedger.pendingShareExact(
          steps: math.max(_steps, claimed),
          claimedSteps: claimed,
        ),
      );
    } catch (_) {}
  }

  void _updatePendingAmount() {
    if (!_isClaimedDataLoaded) return;
    if (!mounted) return;
    final steps = math.max(ref.read(pedometerStateProvider).steps, _steps);
    ref.read(walkingPendingShareProvider.notifier).state =
        _computePendingShare(steps);
  }

  Future<void> _persistStepOffset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_getTodayKey()}_step_offset', _stepOffset);
    } catch (e) {
      debugPrint('_persistStepOffset: $e');
    }
  }

  Future<void> _restoreTodayFromPrefs() async {
    try {
      await ref.read(pedometerStateProvider.notifier).ensureCloudRecovery();
      final prefs = await SharedPreferences.getInstance();
      final todayKey = PedometerKstClock.dateKey();
      final primarySteps =
          prefs.getInt(PedometerKstClock.backupStepsKey(todayKey)) ?? 0;
      final primaryKm =
          prefs.getDouble(PedometerKstClock.backupKmKey(todayKey)) ?? 0;
      final prefix = await _prefPrefix();
      final legacySteps = prefs.getInt('$prefix.steps') ?? 0;
      final legacyKm = prefs.getDouble('$prefix.km') ?? 0;
      final savedMicro = _prefToInt(prefs.get('$prefix.microShare'));
      final savedClaimedPrefix = _prefToInt(prefs.get('$prefix.claimedSteps'));
      final savedClaimedToday = _prefToInt(
        prefs.get(PedometerHarvestLedger.todayClaimedKey(todayKey)),
      );
      final savedClaimedGlobal = PedometerHarvestLedger.claimedFromGlobal(
        storedDate: prefs.getString(PedometerHarvestLedger.globalClaimedDateKey),
        storedClaimed: _prefToInt(
          prefs.get(PedometerHarvestLedger.globalClaimedKey),
        ),
        todayKey: todayKey,
      );
      final savedChallengeReward =
          prefs.getBool('$prefix.hasReceivedChallengeReward') ?? false;
      final savedBonusReward =
          prefs.getBool('$prefix.hasReceivedBonusReward') ?? false;
      final savedMilestone1 =
          prefs.getBool('$prefix.hasReceivedMilestone1') ?? savedChallengeReward;
      final savedMilestone2 =
          prefs.getBool('$prefix.hasReceivedMilestone2') ?? savedChallengeReward;
      final savedMilestone3 =
          prefs.getBool('$prefix.hasReceivedMilestone3') ?? savedChallengeReward;
      final savedBonus =
          prefs.getBool('$prefix.hasReceivedBonus') ?? savedBonusReward;
      final storedCoins = prefs.get('collected_share_coins');
      final savedCollected = _prefToInt(
        prefs.get('$prefix.collectedShare'),
        _prefToInt(storedCoins, savedMicro),
      );
      final notifOn = prefs.getBool('walking_challenge_benefit_notif') ?? true;
      final savedLastDate = prefs.getString('lastSavedDate') ?? '';
      final savedOffset = prefs.getInt('stepOffset') ?? 0;
      if (!mounted) return;
      final restoredSteps = math.max(primarySteps, legacySteps);
      final restoredKm = math.max(primaryKm, legacyKm);
      final km = restoredKm > 0
          ? restoredKm
          : SoloPedometerEngine.kmFromSteps(restoredSteps);
      final steps = restoredSteps > 0
          ? restoredSteps
          : (km > 0
              ? (km * 1000 / EconomyConstants.pedometerStrideMeters).round()
              : 0);
      final week = <String, int>{};
      for (final day in PedometerKstClock.thisWeekDays()) {
        week[day.key] =
            prefs.getInt(PedometerKstClock.backupStepsKey(day.key)) ?? 0;
      }
      week[todayKey] = math.max(week[todayKey] ?? 0, steps);
      setState(() {
        if (steps > _steps) _steps = steps;
        if (steps > _healthBase) _healthBase = steps;
        if (km > _km) _km = km;
        _kstDayKey = todayKey;
        _weekSteps = week;
        if (_selectedDayKey.isEmpty) _selectedDayKey = todayKey;
        _isNotificationEnabled = notifOn;
        _claimedSteps = PedometerHarvestLedger.coalesceClaimed(
          current: _claimedSteps,
          fromTodayKey: savedClaimedToday,
          fromPrefix: savedClaimedPrefix,
          fromGlobal: savedClaimedGlobal,
          steps: steps,
        );
        _hasReceivedMilestone1 = savedMilestone1;
        _hasReceivedMilestone2 = savedMilestone2;
        _hasReceivedMilestone3 = savedMilestone3;
        _hasReceivedBonus = savedBonus;
        _collectedShareCoins = savedCollected.toDouble();
        _lastSavedDate = savedLastDate;
        _stepOffset = savedOffset;
      });
      if (_lastSavedDate.isEmpty) {
        _lastSavedDate = todayKey;
        unawaited(() async {
          try {
            await prefs.setString(
              PedometerDayRollover.lastSavedDateKey,
              todayKey,
            );
          } catch (e) {
            debugPrint('_restoreTodayFromPrefs stamp: $e');
          }
        }());
      }
      final rolled = _ensureDailyRollover(
        sensorTotal: math.max(steps, savedOffset),
      );
      if (rolled) {
        _claimedSteps = 0;
        _collectedShareCoins = 0;
        _hasReceivedMilestone1 = false;
        _hasReceivedMilestone2 = false;
        _hasReceivedMilestone3 = false;
        _hasReceivedBonus = false;
      }
      _refreshPendingShare(_steps);
      if (_steps > 0 || _km > 0) {
        unawaited(
          ref.read(pedometerStateProvider.notifier).updateSteps(
                _steps,
                _km,
                isMoving: _isMoving,
              ),
        );
        unawaited(
          _persistKm(_km, steps: _steps, syncRemote: false),
        );
        unawaited(_syncForegroundNotification(_steps));
      }
      unawaited(_maybeGrantLockedRewards(_steps));
    } on PlatformException catch (e, st) {
      debugPrint('_restoreTodayFromPrefs PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('_restoreTodayFromPrefs: $e\n$st');
    }
  }

  Future<void> _restoreClaims() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = await _prefPrefix();
      final raw = prefs.getString('$prefix.claimed') ?? '';
      if (!mounted) return;
      setState(() {
        _claimedTenths
          ..clear()
          ..addAll(
            raw
                .split(',')
                .map((e) => int.tryParse(e.trim()))
                .whereType<int>(),
          );
      });
      _spawnCoinsForKm(_km);
    } catch (_) {}
  }

  Future<void> _persistClaims() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = await _prefPrefix();
      await prefs.setString(
        '$prefix.claimed',
        _claimedTenths.join(','),
      );
    } catch (_) {}
  }

  Future<void> _persistKm(
    double km, {
    required bool syncRemote,
    required int steps,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ymd = PedometerKstClock.dateKey();
      await prefs.setInt(PedometerKstClock.backupStepsKey(ymd), steps);
      await prefs.setDouble(PedometerKstClock.backupKmKey(ymd), km);
      final prefix = await _prefPrefix();
      await prefs.setDouble('$prefix.km', km);
      await prefs.setInt('$prefix.steps', steps);
      final claimed = PedometerHarvestLedger.coalesceClaimed(
        current: _claimedSteps,
        fromTodayKey:
            prefs.getInt(PedometerHarvestLedger.todayClaimedKey(ymd)) ?? 0,
        fromPrefix: _prefToInt(prefs.get('$prefix.claimedSteps')),
        fromGlobal: PedometerHarvestLedger.claimedFromGlobal(
          storedDate: prefs.getString(PedometerHarvestLedger.globalClaimedDateKey),
          storedClaimed:
              prefs.getInt(PedometerHarvestLedger.globalClaimedKey) ?? 0,
          todayKey: ymd,
        ),
        steps: steps,
      );
      await prefs.setInt('$prefix.claimedSteps', claimed);
      await prefs.setInt(
        PedometerHarvestLedger.todayClaimedKey(ymd),
        claimed,
      );
      await prefs.setInt(PedometerHarvestLedger.globalClaimedKey, claimed);
      await prefs.setString(
        PedometerHarvestLedger.globalClaimedDateKey,
        ymd,
      );
      await prefs.setDouble(
        '$prefix.pendingShare',
        PedometerHarvestLedger.pendingShareExact(
          steps: steps,
          claimedSteps: claimed,
        ),
      );
      await prefs.setDouble('$prefix.collectedShare', _collectedShareCoins);
      await prefs.setBool(
        '$prefix.hasReceivedMilestone1',
        _hasReceivedMilestone1,
      );
      await prefs.setBool(
        '$prefix.hasReceivedMilestone2',
        _hasReceivedMilestone2,
      );
      await prefs.setBool(
        '$prefix.hasReceivedMilestone3',
        _hasReceivedMilestone3,
      );
      await prefs.setBool(
        '$prefix.hasReceivedBonus',
        _hasReceivedBonus,
      );
      if (!syncRemote) return;
      final uid = ref.read(userProfileProvider).uid;
      if (uid.isEmpty) return;
      await ref.read(userRepositoryProvider).updateRetentionFields(
            uid: uid,
            dailyDistance: km,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    SoloPedometerForeground.removeLiveStepsListener(_onIsolateSteps);
    WidgetsBinding.instance.removeObserver(this);
    _stillTimer?.cancel();
    _goldenPushDebounce?.cancel();
    _healthPollTimer?.cancel();
    unawaited(_pedoSub?.cancel());
    unawaited(_statusSub?.cancel());
    unawaited(_engine.dispose());
    super.dispose();
  }

  Future<void> _announceWalkingCoachStart() async {
    await ref.read(voiceCoachingEnabledProvider.notifier).ensureLoaded();
    if (!mounted) return;
    await ref.read(voiceCoachingControllerProvider).onWalkingOpened();
  }

  void _refreshPendingShare(int steps) {
    _updatePendingAmount();
    unawaited(_syncForegroundNotification(steps));
  }

  String _harvestUid() {
    final authUid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (authUid.isNotEmpty) return authUid;
    return ref.read(userProfileProvider).uid;
  }

  Future<void> _onHarvestCoins() async {
    if (_harvestInFlight) return;
    final pedometerState = ref.read(pedometerStateProvider);
    final liveSteps = math.max(pedometerState.steps, _steps);
    final int toClaim = PedometerHarvestLedger.pendingShareFloor(
      steps: liveSteps,
      claimedSteps: _claimedSteps,
    );
    if (toClaim <= 0) return;
    _harvestInFlight = true;
    final previousClaimed = _claimedSteps;
    final previousCollected = _collectedShareCoins;
    try {
      HapticFeedback.heavyImpact();
    } on PlatformException catch (e, st) {
      debugPrint('harvest haptic PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('harvest haptic: $e\n$st');
    }
    if (!mounted) {
      _harvestInFlight = false;
      return;
    }
    setState(() {
      _claimedSteps = liveSteps;
      _mascotPickupNonce += 1;
    });
    ref.read(walkingPendingShareProvider.notifier).state = 0.0;
    unawaited(_syncForegroundNotification(liveSteps));
    // Persist the watermark before the API returns so back-navigation
    // cannot restore the old pending floor and harvest it again.
    await _persistClaimedWatermark(liveSteps);
    final uid = _harvestUid();
    try {
      if (uid.isEmpty) {
        throw StateError('로그인이 필요합니다.');
      }
      final result = await ref.read(walletRepositoryProvider).harvestPedometerShare(
            claimedSteps: liveSteps,
          );
      final credited = result.creditedShare(fallback: toClaim);
      final minted = result.mintedShare && credited > 0;
      if (minted || result.shareBalance != null) {
        ref.read(walletProvider.notifier).applyShareFromServer(
              shareBalance: result.shareBalance,
              shareCredited: minted ? credited : 0,
            );
      }
      ref.read(debugEconomyStatusProvider.notifier).markJenaOk();
      await _persistHarvestWalletUi(
        uid: uid,
        credited: minted ? credited : 0,
        source: 'jena',
      );
      if (minted || credited > 0) {
        unawaited(
          ref.read(voiceCoachingControllerProvider).onHarvestCompleted(),
        );
      }
    } catch (e) {
      debugPrint('[HARVEST] secured credit failed: $e');
      if (DebugLocalHarvest.shouldCreditOnJenaFailure(
        debugMode: kDebugMode,
        toClaim: toClaim,
      )) {
        ref.read(debugEconomyStatusProvider.notifier).markJenaFail();
        ref.read(walletProvider.notifier).applyShareFromServer(
              shareCredited: toClaim,
            );
        final walletShare = ref.read(walletProvider).shareBalance;
        try {
          await ref.read(walletRepositoryProvider).creditLocalDebugHarvestShare(
                uid: uid,
                shareBalance: walletShare,
              );
        } catch (writeError) {
          debugPrint(
            '${DebugLocalHarvest.logPrefix} harvest Firestore write failed: '
            '$writeError',
          );
        }
        await _persistHarvestWalletUi(
          uid: uid,
          credited: toClaim,
          source: 'local',
        );
        unawaited(
          ref.read(voiceCoachingControllerProvider).onHarvestCompleted(),
        );
      } else if (mounted) {
        setState(() {
          _collectedShareCoins = previousCollected;
          _claimedSteps = previousClaimed;
        });
        _updatePendingAmount();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('셰어 줍기에 실패했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.'),
          ),
        );
        await _persistClaimedWatermark(previousClaimed);
      } else {
        _collectedShareCoins = previousCollected;
        _claimedSteps = previousClaimed;
        await _persistClaimedWatermark(previousClaimed);
      }
    } finally {
      _harvestInFlight = false;
    }
  }

  /// Push harvest SHARE into Home/`walletProvider` + durable debug ledger.
  Future<void> _persistHarvestWalletUi({
    required String uid,
    required int credited,
    required String source,
  }) async {
    final walletShare = ref.read(walletProvider).shareBalance;
    if (mounted) {
      setState(() {
        _collectedShareCoins = walletShare.toDouble();
      });
    } else {
      _collectedShareCoins = walletShare.toDouble();
    }
    await _persistClaimedWatermark(_claimedSteps);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('collected_share_coins', _collectedShareCoins);
      final prefix = await _prefPrefix();
      await prefs.setDouble('$prefix.collectedShare', _collectedShareCoins);
      await prefs.setDouble('$prefix.pendingShare', 0.0);
      if (kDebugMode && uid.isNotEmpty && credited > 0) {
        await DebugLocalWalletStore.recordHarvestCredit(
          prefs: prefs,
          uid: uid,
          shareBalanceAfter: walletShare,
          credited: credited,
        );
        ref.read(debugLocalShareHistoryProvider.notifier).replace(
              DebugLocalWalletStore.cachedHistory(uid),
            );
      }
    } catch (e) {
      debugPrint('${DebugLocalHarvest.logPrefix} durable persist failed: $e');
    }
    debugPrint(
      DebugLocalHarvest.resultLog(
        credited: credited > 0,
        amount: credited,
        source: source,
        walletShare: walletShare,
      ),
    );
  }

  Future<void> _setBenefitNotifEnabled(bool enabled) async {
    try {
      HapticFeedback.lightImpact();
    } on PlatformException catch (e, st) {
      debugPrint('notif toggle haptic: $e\n$st');
    } catch (e, st) {
      debugPrint('notif toggle haptic: $e\n$st');
    }
    if (!mounted) return;
    setState(() => _isNotificationEnabled = enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('walking_challenge_benefit_notif', enabled);
    } catch (_) {}
    try {
      if (enabled) {
        await SoloPedometerForeground.start(
          steps: _steps,
          targetKm: _tier.targetKm,
          healthBase: _healthBase,
          claimedSteps: _claimedSteps,
          pendingShare: _computePendingShare(_steps),
        );
      } else {
        await SoloPedometerForeground.stop();
      }
      _scheduleGoldenPushes();
    } on PlatformException catch (e, st) {
      debugPrint('notif toggle service PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('notif toggle service: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final live = ref.watch(pedometerStateProvider);
    final running =
        ref.watch(activeUserTierStructProvider) ?? UserTier.unratedFallback;
    final todayKey = PedometerKstClock.dateKey();
    if (_lastSavedDate.isNotEmpty && _lastSavedDate != todayKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_lastSavedDate == PedometerKstClock.dateKey()) return;
        _ensureDailyRollover(
          sensorTotal: math.max(live.steps, _steps) + _stepOffset,
        );
      });
    }
    final effectiveSteps = math.max(live.steps, _steps).clamp(0, 999999);
    final weekSteps = {
      ..._weekSteps,
      todayKey: math.max(_weekSteps[todayKey] ?? 0, effectiveSteps),
    };
    final effectiveKm =
        double.parse((effectiveSteps * 0.00075).toStringAsFixed(2));
    final buddySize = MediaQuery.sizeOf(context).shortestSide * 0.42;
    final weekDays = PedometerKstClock.thisWeekDays();
    final selectedKey =
        _selectedDayKey.isEmpty ? PedometerKstClock.dateKey() : _selectedDayKey;
    final currentPendingShare = PedometerHarvestLedger.pendingShareExact(
      steps: effectiveSteps,
      claimedSteps: _claimedSteps,
    );
    final pendingCoinsInt = PedometerHarvestLedger.pendingShareFloor(
      steps: effectiveSteps,
      claimedSteps: _claimedSteps,
    );
    final hasPendingCoins = pendingCoinsInt >= 1;
    final isMaxDailyReached = PedometerHarvestLedger.pendingShareFloor(
          steps: _claimedSteps,
          claimedSteps: 0,
        ) >=
        60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goHomeSafe();
      },
      child: Scaffold(
        backgroundColor: WalkingLook.pageMist,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: WalkingLook.pageGradient,
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _WalkingHeroCanvas(
                        title: '워킹챌린지',
                        onBack: _goHomeSafe,
                        gauge: _buildHybridProgressGauge(
                          tier: running,
                          currentKm: effectiveKm,
                          currentSteps: effectiveSteps,
                          characterSize: buddySize,
                          moving: _isMoving,
                          pickupNonce: _mascotPickupNonce,
                        ),
                        stepCount: _comma(effectiveSteps),
                        km: effectiveKm,
                        kcal: effectiveSteps * 0.045,
                        pendingShare: currentPendingShare,
                        tierLabel: '[${running.koreanName}] 산책 중',
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spacing.page,
                        tokens.spacing.md,
                        tokens.spacing.page,
                        tokens.spacing.sm,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _buildCumulativeShareAccountCard(),
                            SizedBox(height: tokens.spacing.sm),
                            _WeekJournalCard(
                              days: weekDays,
                              stepsByKey: weekSteps,
                              selectedKey: selectedKey,
                              todayKey: todayKey,
                              stepOffset: 0,
                              onSelect: _onSelectWeekDay,
                            ),
                            if (running.isSnail) ...[
                              SizedBox(height: tokens.spacing.sm),
                              Text(
                                '👼 3km만 걸어도 특별히 60 SHARE 혜택!',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: tokens.colors.accent,
                                ),
                              ),
                            ],
                            SizedBox(height: tokens.spacing.md),
                            _BenefitNotifBanner(
                              enabled: _isNotificationEnabled,
                              onToggle: () => unawaited(
                                _setBenefitNotifEnabled(
                                  !_isNotificationEnabled,
                                ),
                              ),
                            ),
                            SizedBox(height: tokens.spacing.sm),
                            const VoiceCoachingWalkBanner(),
                            SizedBox(height: tokens.spacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _WalkingHarvestDock(
                isMaxDailyReached: isMaxDailyReached,
                currentPendingShare: currentPendingShare,
                hasPendingCoins: hasPendingCoins,
                pendingCoinsInt: pendingCoinsInt,
                onClaim: () => unawaited(_onHarvestCoins()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCumulativeShareAccountCard() {
    // Spendable SHARE — same ledger as Home 나의 지갑. Do not show local
    // milestone `_collectedShareCoins` (that is the 20 SHARE desync).
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final walletShare = ref.watch(walletProvider).shareBalance;
    final todayCollectedCoins = PedometerHarvestLedger.pendingShareFloor(
      steps: _claimedSteps,
      claimedSteps: 0,
    );
    return SrcSurfaceCard(
      key: const Key('walking-share-account'),
      color: AppColors.glassFill,
      borderColor: const Color(0x14FFFFFF),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.lg,
        tokens.spacing.md,
        tokens.spacing.md,
        tokens.spacing.md,
      ),
      onTap: _openMyWallet,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 누적 셰어 통장 🏦',
                  style: textTheme.labelMedium?.copyWith(
                    color: tokens.colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs),
                Text(
                  '$walletShare SHARE',
                  key: const Key('walking-share-balance'),
                  style: textTheme.displaySmall?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -1.1,
                    color: tokens.colors.accent,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs),
                Text(
                  '오늘의 채굴 : $todayCollectedCoins / 60 SHARE 🪙',
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.account_balance_wallet_rounded,
            color: tokens.colors.accent.withValues(alpha: 0.72),
            size: 28,
          ),
        ],
      ),
    );
  }

  double _hybridProgress({
    required UserTier tier,
    required double currentKm,
    required int currentSteps,
  }) {
    final progressKm =
        tier.targetKm <= 0 ? 0.0 : currentKm / tier.targetKm;
    final progressSteps =
        tier.targetSteps <= 0 ? 0.0 : currentSteps / tier.targetSteps;
    final finalProgress =
        math.max(progressKm, progressSteps).clamp(0.0, 1.0);
    if (finalProgress.isNaN || finalProgress.isInfinite) return 0.0;
    return finalProgress.toDouble();
  }

  bool _isWalkingChallengeComplete({
    required UserTier tier,
    required double currentKm,
    required int currentSteps,
  }) {
    return _hybridProgress(
          tier: tier,
          currentKm: currentKm,
          currentSteps: currentSteps,
        ) >=
        1.0;
  }

  Future<void> _persistRewardLocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = await _prefPrefix();
      await prefs.setBool(
        '$prefix.hasReceivedMilestone1',
        _hasReceivedMilestone1,
      );
      await prefs.setBool(
        '$prefix.hasReceivedMilestone2',
        _hasReceivedMilestone2,
      );
      await prefs.setBool(
        '$prefix.hasReceivedMilestone3',
        _hasReceivedMilestone3,
      );
      await prefs.setBool(
        '$prefix.hasReceivedBonus',
        _hasReceivedBonus,
      );
      await prefs.setDouble('$prefix.collectedShare', _collectedShareCoins);
      await prefs.setDouble('collected_share_coins', _collectedShareCoins);
    } catch (e) {
      debugPrint('_persistRewardLocks: $e');
    }
  }

  Future<bool> _creditLockedShare(int amount) async {
    if (mounted) {
      setState(() => _collectedShareCoins += amount);
    } else {
      _collectedShareCoins += amount;
    }
    await _persistRewardLocks();
    if (!mounted) return false;
    await ref.read(userProfileProvider.notifier).creditShare(amount);
    return mounted;
  }

  /// 구간 마일스톤 3회 + 만보 보너스, 각 20 SHARE 1회.
  Future<void> _maybeGrantLockedRewards(int currentSteps) async {
    if (!mounted || _rewardGrantInFlight) return;
    _rewardGrantInFlight = true;
    try {
      final km = SoloPedometerEngine.kmFromSteps(currentSteps);
      if (!_hasReceivedMilestone1 && currentSteps >= 1500) {
        _hasReceivedMilestone1 = true;
        if (!await _creditLockedShare(20)) return;
      }
      if (!_hasReceivedMilestone2 && currentSteps >= 3000) {
        _hasReceivedMilestone2 = true;
        if (!await _creditLockedShare(20)) return;
      }
      if (!_hasReceivedMilestone3 &&
          (currentSteps >= 4500 || km >= 3.0)) {
        _hasReceivedMilestone3 = true;
        if (!await _creditLockedShare(20)) return;
        final today = PedometerKstClock.dateKey();
        if (_streakReportedForDay != today) {
          _streakReportedForDay = today;
          unawaited(
            ref.read(practiceStreakProvider.notifier).completeChallenge(),
          );
        }
      }
      if (!_hasReceivedBonus && currentSteps >= 10000) {
        _hasReceivedBonus = true;
        if (!await _creditLockedShare(20)) return;
      }
    } catch (e, st) {
      debugPrint('_maybeGrantLockedRewards: $e\n$st');
    } finally {
      _rewardGrantInFlight = false;
    }
  }

  Widget _buildHybridProgressGauge({
    required UserTier tier,
    required double currentKm,
    required int currentSteps,
    required double characterSize,
    required bool moving,
    required int pickupNonce,
  }) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final finalProgress = _hybridProgress(
      tier: tier,
      currentKm: currentKm,
      currentSteps: currentSteps,
    );
    final percent = (finalProgress * 100).toInt();
    final charSize = characterSize.clamp(78.0, 96.0);
    final complete = _isWalkingChallengeComplete(
      tier: tier,
      currentKm: currentKm,
      currentSteps: currentSteps,
    );
    final trailT = (currentSteps / 10000.0).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          '목표 달성률: $percent%',
          textAlign: TextAlign.center,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: complete ? WalkingLook.harvestHi : WalkingLook.onHero,
          ),
        ),
        SizedBox(height: tokens.spacing.xs),
        SizedBox(
          width: double.infinity,
          height: charSize + 36,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const barH = 10.0;
              const checkpointT = 4500 / 10000.0;
              final maxLeft =
                  (constraints.maxWidth - charSize).clamp(0.0, 4000.0);
              final left = maxLeft * trailT;
              final flagLeft = (constraints.maxWidth * checkpointT - 14)
                  .clamp(0.0, constraints.maxWidth);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 4,
                    height: barH,
                    child: ClipRRect(
                      borderRadius: tokens.radii.capsule,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: WalkingLook.onHero.withValues(alpha: 0.18),
                          ),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: trailT,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF7EE0C8),
                                    Color(0xFFB8F3DE),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth * checkpointT - 1)
                        .clamp(0.0, constraints.maxWidth),
                    bottom: 4,
                    width: 2,
                    height: barH,
                    child: ColoredBox(
                      color: WalkingLook.onHero.withValues(alpha: 0.45),
                    ),
                  ),
                  Positioned(
                    left: flagLeft,
                    bottom: barH + 2,
                    width: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '3km',
                          textAlign: TextAlign.center,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: WalkingLook.onHero,
                          ),
                        ),
                        const Icon(
                          Icons.flag_rounded,
                          size: 16,
                          color: WalkingLook.harvestHi,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: left,
                    bottom: barH,
                    width: charSize,
                    height: charSize,
                    child: WalkingMascot(
                      tier: tier,
                      size: charSize,
                      moving: moving,
                      pickupNonce: pickupNonce,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _onSelectWeekDay(String key) {
    try {
      HapticFeedback.heavyImpact();
    } on PlatformException catch (e, st) {
      debugPrint('week day haptic PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('week day haptic: $e\n$st');
    }
    if (!mounted) return;
    setState(() => _selectedDayKey = key);
  }

  static String _comma(int n) {
    final raw = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
      buf.write(raw[i]);
    }
    return n < 0 ? '-$buf' : '$buf';
  }
}

class _WalkingHeroCanvas extends StatelessWidget {
  const _WalkingHeroCanvas({
    required this.title,
    required this.onBack,
    required this.gauge,
    required this.stepCount,
    required this.km,
    required this.kcal,
    required this.pendingShare,
    required this.tierLabel,
  });

  final String title;
  final VoidCallback onBack;
  final Widget gauge;
  final String stepCount;
  final double km;
  final double kcal;
  final double pendingShare;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: WalkingLook.heroGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: _WalkingHeroBloom()),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.page,
                tokens.spacing.xxs,
                tokens.spacing.page,
                tokens.spacing.xl,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: WalkingLook.onHero,
                        ),
                        tooltip: '뒤로',
                        onPressed: onBack,
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: WalkingLook.onHero,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spacing.xxl + tokens.spacing.md),
                    ],
                  ),
                  Text(
                    tierLabel,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: WalkingLook.onHeroMuted,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sm),
                  gauge,
                  SizedBox(height: tokens.spacing.sm),
                  Text(
                    stepCount,
                    key: const Key('walking-step-count'),
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall?.copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: -2.2,
                      color: WalkingLook.onHero,
                    ),
                  ),
                  Text(
                    '걸음',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: WalkingLook.onHeroMuted,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.md),
                  Row(
                    children: [
                      Expanded(child: _HeroStatChip(label: '${km.toStringAsFixed(2)} km')),
                      SizedBox(width: tokens.spacing.xs),
                      Expanded(
                        child: _HeroStatChip(
                          label: '${kcal.toStringAsFixed(1)} kcal',
                        ),
                      ),
                      SizedBox(width: tokens.spacing.xs),
                      Expanded(
                        child: _HeroStatChip(
                          label: '${pendingShare.toStringAsFixed(2)} SHARE',
                          emphasize: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkingHeroBloom extends StatelessWidget {
  const _WalkingHeroBloom();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.15),
            radius: 0.85,
            colors: [
              const Color(0x66F6D56B),
              WalkingLook.heroLift.withValues(alpha: 0.28),
              Colors.transparent,
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.label,
    this.emphasize = false,
  });

  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.xs,
        vertical: tokens.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: WalkingLook.onHero.withValues(alpha: emphasize ? 0.20 : 0.12),
        borderRadius: tokens.radii.capsule,
        border: Border.all(
          color: emphasize
              ? WalkingLook.harvestHi.withValues(alpha: 0.55)
              : WalkingLook.onHero.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: emphasize ? WalkingLook.harvestHi : WalkingLook.onHero,
            ),
      ),
    );
  }
}

class _WalkingHarvestDock extends StatelessWidget {
  const _WalkingHarvestDock({
    required this.isMaxDailyReached,
    required this.currentPendingShare,
    required this.hasPendingCoins,
    required this.pendingCoinsInt,
    required this.onClaim,
  });

  final bool isMaxDailyReached;
  final double currentPendingShare;
  final bool hasPendingCoins;
  final int pendingCoinsInt;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    if (isMaxDailyReached) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.page,
            tokens.spacing.sm,
            tokens.spacing.page,
            tokens.spacing.sm,
          ),
          child: Container(
            key: const Key('walking-goal-complete'),
            padding: EdgeInsets.all(tokens.spacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [WalkingLook.heroMid, WalkingLook.heroLift],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: tokens.radii.panel,
              boxShadow: WalkingLook.glassLift,
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 36)),
                SizedBox(height: tokens.spacing.xs),
                Text(
                  '오늘의 목표 달성!',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: WalkingLook.onHero,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs),
                Text(
                  '오늘 하루도 열심히 달리셨네요.\n고생하셨습니다. 내일 다시 걸어보죠! 🏃‍♂️✨',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: WalkingLook.onHero,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: tokens.colors.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colors.surface,
          boxShadow: AppShadows.nav,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.page,
              tokens.spacing.sm,
              tokens.spacing.page,
              tokens.spacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '줍기 대기 : ${currentPendingShare.toStringAsFixed(2)} SHARE',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tokens.colors.donation,
                  ),
                ),
                SizedBox(height: tokens.spacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: WalkingHarvestCta(
                    hasPendingCoins: hasPendingCoins,
                    pendingCoinsInt: pendingCoinsInt,
                    onPressed: hasPendingCoins ? onClaim : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitNotifBanner extends StatelessWidget {
  const _BenefitNotifBanner({
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      color: tokens.colors.surface,
      borderColor: tokens.colors.outline.withValues(alpha: 0.7),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.sm,
        tokens.spacing.sm,
        tokens.spacing.xs,
        tokens.spacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.notifications_active : Icons.notifications_off,
            size: 18,
            color: enabled ? tokens.colors.accent : tokens.colors.muted,
          ),
          SizedBox(width: tokens.spacing.xs),
          Expanded(
            child: Text(
              enabled
                  ? '워킹챌린지 혜택 알림 받는 중 🔔'
                  : '혜택 알림이 완전히 꺼져 있습니다 🔕',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: enabled ? tokens.colors.ink : tokens.colors.muted,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.sm,
                vertical: tokens.spacing.xxs + 2,
              ),
              decoration: BoxDecoration(
                color: enabled ? tokens.colors.surface : tokens.colors.primary,
                borderRadius: tokens.radii.capsule,
                border: Border.all(
                  color: enabled ? tokens.colors.accent : tokens.colors.primary,
                ),
              ),
              child: Text(
                enabled ? '알림 해지' : '알림 받기',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: enabled
                      ? tokens.colors.accent
                      : tokens.colors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekJournalCard extends StatelessWidget {
  const _WeekJournalCard({
    required this.days,
    required this.stepsByKey,
    required this.selectedKey,
    required this.todayKey,
    required this.stepOffset,
    required this.onSelect,
  });

  final List<({int year, int month, int day, String key})> days;
  final Map<String, int> stepsByKey;
  final String selectedKey;
  final String todayKey;
  final int stepOffset;
  final ValueChanged<String> onSelect;

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _completeSteps = 5000;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    ({int year, int month, int day, String key})? selected;
    for (final day in days) {
      if (day.key == selectedKey) {
        selected = day;
        break;
      }
    }
    selected ??= days.isEmpty ? null : days.first;
    final rawSelectedSteps =
        selected == null ? 0 : (stepsByKey[selected.key] ?? 0);
    final displaySelectedSteps = selected == null
        ? 0
        : (selected.key == todayKey
            ? (rawSelectedSteps - stepOffset).clamp(0, 999999)
            : rawSelectedSteps);

    return SrcSurfaceCard(
      color: AppColors.glassFill,
      borderColor: const Color(0x14FFFFFF),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md,
        tokens.spacing.md,
        tokens.spacing.md,
        tokens.spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주 분석 일지',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: tokens.colors.ink,
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) SizedBox(width: tokens.spacing.xs),
                  Builder(
                    builder: (context) {
                      final dateKey = days[i].key;
                      final rawSteps = stepsByKey[dateKey] ?? 0;
                      final steps = dateKey == todayKey
                          ? (rawSteps - stepOffset).clamp(0, 999999)
                          : rawSteps;
                      return _WeekDayCircle(
                        label: _labels[i.clamp(0, _labels.length - 1)],
                        day: days[i],
                        selected: dateKey == selectedKey,
                        complete: steps >= _completeSteps,
                        onTap: () => onSelect(dateKey),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm,
              vertical: tokens.spacing.sm,
            ),
            decoration: BoxDecoration(
              color: WalkingLook.pageMist,
              borderRadius: tokens.radii.card,
            ),
            child: Text(
              selected == null
                  ? '날짜를 선택하면 그날의 걸음 수가 표시됩니다.'
                  : '${selected.month}월 ${selected.day}일의 누적 걸음수: ${_comma(displaySelectedSteps)}보',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: tokens.colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _comma(int n) {
    final raw = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
      buf.write(raw[i]);
    }
    return n < 0 ? '-$buf' : '$buf';
  }
}

class _WeekDayCircle extends StatelessWidget {
  const _WeekDayCircle({
    required this.label,
    required this.day,
    required this.selected,
    required this.complete,
    required this.onTap,
  });

  final String label;
  final ({int year, int month, int day, String key}) day;
  final bool selected;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final fill = complete ? WalkingLook.heroMid : tokens.colors.surface;
    final fg = complete ? WalkingLook.onHero : tokens.colors.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 62,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: tokens.radii.capsule,
          border: Border.all(
            color: selected ? tokens.colors.accent : tokens.colors.outline,
            width: selected ? 2 : 1,
          ),
          boxShadow: complete
              ? [
                  BoxShadow(
                    color: WalkingLook.heroMid.withValues(alpha: 0.28),
                    blurRadius: 10,
                    spreadRadius: 0.4,
                  ),
                ]
              : AppShadows.rest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: complete ? WalkingLook.onHeroMuted : tokens.colors.muted,
              ),
            ),
            SizedBox(height: tokens.spacing.xxs / 2),
            Text(
              '${day.day}',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1.1,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCoinChip extends StatelessWidget {
  const _FloatingCoinChip({
    required this.animation,
    required this.onTap,
  });

  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final lift = (animation.value - 0.5) * 22;
        final glow = 0.35 + animation.value * 0.25;
        return Transform.translate(
          offset: Offset(0, lift),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tokens.colors.donation.withValues(alpha: glow),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const _GoldCoinFace(),
        ),
      ),
    );
  }
}

class _GoldCoinFace extends StatelessWidget {
  const _GoldCoinFace();

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldBadge,
            tokens.colors.donation,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.colors.donation.withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: tokens.colors.surface, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        'S',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              color: tokens.colors.ink,
            ),
      ),
    );
  }
}

class _ClaimFlight extends StatefulWidget {
  const _ClaimFlight({
    super.key,
    required this.begin,
    required this.onArrived,
  });

  final Alignment begin;
  final VoidCallback onArrived;

  @override
  State<_ClaimFlight> createState() => _ClaimFlightState();
}

class _ClaimFlightState extends State<_ClaimFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Alignment> _align;
  late final Animation<double> _scale;
  var _notified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    );
    _align = AlignmentTween(
      begin: widget.begin,
      end: const Alignment(0.92, -0.92),
    ).animate(curve);
    _scale = Tween<double>(begin: 1, end: 0.12).animate(curve);
    _controller.forward().whenComplete(_notify);
  }

  void _notify() {
    if (_notified) return;
    _notified = true;
    widget.onArrived();
  }

  @override
  void dispose() {
    _notify();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: _align.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: const IgnorePointer(child: _GoldCoinFace()),
    );
  }
}
