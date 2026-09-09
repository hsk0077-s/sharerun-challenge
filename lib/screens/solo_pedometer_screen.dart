import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/app_providers.dart';
import '../core/constants/economy_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/pedometer/solo_pedometer_engine.dart';
import '../features/pedometer/solo_pedometer_foreground.dart';
import '../features/pedometer/walking_challenge_notification_service.dart';
import '../features/profile/providers/practice_streak_provider.dart';
import '../features/profile/user_profile_notifier.dart';
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
  Timer? _goldenPushDebounce;

  UserTier get _tier =>
      ref.read(activeUserTierStructProvider) ?? UserTier.unratedFallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoloPedometerForeground.onLiveSteps = _onIsolateSteps;
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
      _pedoSub = Pedometer.stepCountStream.listen(
        _onPedometerEvent,
        onError: (Object error, StackTrace stack) {
          debugPrint('Pedometer.stepCountStream: $error\n$stack');
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
        debugPrint('initPedometerSystem pedestrianStatus: $e\n$st');
      } catch (e, st) {
        debugPrint('initPedometerSystem pedestrianStatus: $e\n$st');
      }
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
      _scheduleGoldenPushes();
    } on PlatformException catch (e, st) {
      debugPrint('initPedometerSystem PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('initPedometerSystem: $e\n$st');
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
        return;
      }
      _sessionDelta = math.max(0, raw - _baselineSteps);
      if (!mounted) return;
      _setMoving(true);
      _stillTimer?.cancel();
      _stillTimer = Timer(const Duration(seconds: 3), () {
        _setMoving(false);
      });
      _applyOsSteps(_healthBase + _sessionDelta);
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
        _ensureDailyRollover(sensorTotal: math.max(_steps, 0));
      }
      _kstDayKey = todayKey;
      if (total != null) {
        if (rolled) {
          return;
        }
        var next = math.max(total, _steps);
        next = math.max(next, await SoloPedometerForeground.liveSteps());
        _healthBase = next;
        _sessionDelta = 0;
        _baselineReady = false;
        _applyOsSteps(next);
        return;
      }
      if (_steps > 0) {
        unawaited(
          ref.read(pedometerStateProvider.notifier).updateSteps(
                _steps,
                _km,
                isMoving: _isMoving,
              ),
        );
      }
    } on PlatformException catch (e, st) {
      debugPrint('syncBackgroundSteps PlatformException: $e\n$st');
    } catch (e, st) {
      debugPrint('syncBackgroundSteps: $e\n$st');
    } finally {
      _syncing = false;
    }
  }

  void _ensureDailyRollover({required int sensorTotal}) {
    final todayIso = PedometerKstClock.dateKey();
    if (_lastSavedDate == todayIso) return;
    if (_lastSavedDate.isEmpty) {
      _lastSavedDate = todayIso;
      unawaited(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastSavedDate', _lastSavedDate);
          await prefs.setInt('stepOffset', _stepOffset);
        } catch (e) {
          debugPrint('_ensureDailyRollover stamp: $e');
        }
      }());
      return;
    }
    _stepOffset = sensorTotal;
    _steps = 0;
    _km = 0.0;
    _collectedShareCoins = 0.0;
    _claimedSteps = 0;
    _hasReceivedMilestone1 = false;
    _hasReceivedMilestone2 = false;
    _hasReceivedMilestone3 = false;
    _hasReceivedBonus = false;
    _lastSavedDate = todayIso;
    _kstDayKey = PedometerKstClock.dateKey();
    _streakReportedForDay = '';
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
      await prefs.setInt('$prefix.steps', _steps);
      await prefs.setDouble('$prefix.km', _km);
      final ymd = PedometerKstClock.dateKey();
      await prefs.setInt(PedometerKstClock.backupStepsKey(ymd), _steps);
      await prefs.setDouble(PedometerKstClock.backupKmKey(ymd), _km);
    } catch (e) {
      debugPrint('_persistDailyResetState: $e');
    }
  }

  void _applyOsSteps(int steps) {
    if (!mounted) return;
    _ensureDailyRollover(sensorTotal: math.max(steps, _steps));
    final effective = (steps - _stepOffset).clamp(0, 999999);
    if (effective <= _steps) return;
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
  }

  void _onIsolateSteps(int steps) {
    if (!mounted) return;
    _ensureDailyRollover(sensorTotal: math.max(steps, _steps));
    if (steps <= _steps) return;
    _healthBase = steps;
    _sessionDelta = 0;
    _baselineReady = false;
    _applyOsSteps(steps);
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
      unawaited(_pullLiveStepsFromService());
      unawaited(syncBackgroundSteps());
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
    final uid = ref.read(userProfileProvider).uid;
    final key = PedometerKstClock.dateKey();
    return 'solo_pedo_${uid}_$key';
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
      _ensureDailyRollover(
        sensorTotal: math.max(_steps, 0) + _stepOffset,
      );
      if (!mounted) return;
      final sameKstDay = _lastSavedDate == todayKey;
      setState(() {
        _isOffsetCaptured = true;
        _isClaimedDataLoaded = true;
        if (sameKstDay) {
          _claimedSteps = prefs.getInt('${todayKey}_claimed_steps') ??
              _claimedSteps;
          _collectedShareCoins =
              prefs.getDouble('collected_share_coins') ?? _collectedShareCoins;
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
    final diffSteps = steps - _claimedSteps;
    return diffSteps > 0 ? diffSteps * 0.01 : 0.0;
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
      final savedClaimed = _prefToInt(prefs.get('$prefix.claimedSteps'));
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
        if (km > _km) _km = km;
        _kstDayKey = todayKey;
        _weekSteps = week;
        if (_selectedDayKey.isEmpty) _selectedDayKey = todayKey;
        _isNotificationEnabled = notifOn;
        _claimedSteps = savedClaimed.clamp(0, steps);
        _hasReceivedMilestone1 = savedMilestone1;
        _hasReceivedMilestone2 = savedMilestone2;
        _hasReceivedMilestone3 = savedMilestone3;
        _hasReceivedBonus = savedBonus;
        _collectedShareCoins = savedCollected.toDouble();
        _lastSavedDate = savedLastDate;
        _stepOffset = savedOffset;
      });
      _ensureDailyRollover(sensorTotal: math.max(steps, savedOffset));
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
      await prefs.setInt('$prefix.claimedSteps', _claimedSteps);
      await prefs.setDouble(
        '$prefix.pendingShare',
        _computePendingShare(steps),
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
    SoloPedometerForeground.onLiveSteps = null;
    WidgetsBinding.instance.removeObserver(this);
    _stillTimer?.cancel();
    _goldenPushDebounce?.cancel();
    unawaited(_pedoSub?.cancel());
    unawaited(_statusSub?.cancel());
    unawaited(_engine.dispose());
    super.dispose();
  }

  void _refreshPendingShare(int steps) {
    _updatePendingAmount();
    unawaited(_syncForegroundNotification(steps));
  }

  Future<void> _onHarvestCoins() async {
    if (_harvestInFlight) return;
    final pedometerState = ref.read(pedometerStateProvider);
    final liveSteps = math.max(pedometerState.steps, _steps);
    final diffSteps = liveSteps - _claimedSteps;
    final int toClaim = (diffSteps * 0.01).floor();
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
    final todayKey = _getTodayKey();
    final userProfile = ref.read(userProfileProvider);
    final uid = userProfile.uid;
    setState(() {
      _collectedShareCoins += toClaim;
      _claimedSteps = liveSteps;
    });
    ref.read(walkingPendingShareProvider.notifier).state = 0.0;
    unawaited(_syncForegroundNotification(liveSteps));
    try {
      if (uid.isNotEmpty) {
        await ref.read(walletRepositoryProvider).harvestPedometerShare(
              claimedSteps: liveSteps,
            );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${todayKey}_claimed_steps', _claimedSteps);
      await prefs.setDouble('collected_share_coins', _collectedShareCoins);
      try {
        final prefix = await _prefPrefix();
        await prefs.setInt('$prefix.claimedSteps', _claimedSteps);
        await prefs.setDouble('$prefix.pendingShare', 0.0);
        await prefs.setDouble('$prefix.collectedShare', _collectedShareCoins);
      } catch (_) {}
      debugPrint('[HARVEST SUCCESS] +$toClaim SHARE claimedSteps=$liveSteps');
    } catch (e) {
      debugPrint('[HARVEST] secured credit failed: $e');
      if (mounted) {
        setState(() {
          _collectedShareCoins = previousCollected;
          _claimedSteps = previousClaimed;
        });
        _updatePendingAmount();
      }
    } finally {
      _harvestInFlight = false;
    }
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
    final buddySize = MediaQuery.sizeOf(context).shortestSide * 0.30;
    final weekDays = PedometerKstClock.thisWeekDays();
    final selectedKey =
        _selectedDayKey.isEmpty ? PedometerKstClock.dateKey() : _selectedDayKey;
    final diffSteps = effectiveSteps - _claimedSteps;
    final currentPendingShare = diffSteps > 0 ? (diffSteps * 0.01) : 0.0;
    final pendingCoinsInt = currentPendingShare.floor();
    final hasPendingCoins = pendingCoinsInt >= 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goHomeSafe();
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [running.walkCanvasStart, running.walkCanvasEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF333D4B),
                      ),
                      tooltip: '뒤로',
                      onPressed: () {
                        // 로그인 화면 역행 방지 및 홈 화면 안전 다이렉트 랜딩
                        _goHomeSafe();
                      },
                    ),
                    Expanded(
                      child: Text(
                        '워킹챌린지',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.header1.copyWith(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHybridProgressGauge(
                              tier: running,
                              currentKm: effectiveKm,
                              currentSteps: effectiveSteps,
                              characterSize: buddySize * 0.42,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _comma(effectiveSteps),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.header1.copyWith(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                letterSpacing: -1.4,
                              ),
                            ),
                            Text(
                              '걸음',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textGrey,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _TodayKmBadge(km: effectiveKm),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _KcalBadge(
                                    kcal: effectiveSteps * 0.045,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTodayMiningChip(),
                            const SizedBox(height: 12),
                            _buildPendingCoinJarSection(
                              currentPendingShare: currentPendingShare,
                              hasPendingCoins: hasPendingCoins,
                              pendingCoinsInt: pendingCoinsInt,
                            ),
                            const SizedBox(height: 14),
                            _WeekJournalCard(
                              days: weekDays,
                              stepsByKey: weekSteps,
                              selectedKey: selectedKey,
                              todayKey: todayKey,
                              stepOffset: 0,
                              onSelect: _onSelectWeekDay,
                            ),
                            const SizedBox(height: 12),
                            _buildCumulativeShareAccountCard(),
                            const SizedBox(height: 10),
                            _TierBoardCard(tier: running),
                            if (running.isSnail) ...[
                              const SizedBox(height: 8),
                              Text(
                                '👼 3km만 걸어도 특별히 60 SHARE 혜택!',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppColors.tealAccent,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _BenefitNotifBanner(
                              enabled: _isNotificationEnabled,
                              onToggle: () => unawaited(
                                _setBenefitNotifEnabled(
                                  !_isNotificationEnabled,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTodayMiningChip() {
    final todayCollectedCoins = (_claimedSteps * 0.01).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '오늘의 채굴 : $todayCollectedCoins / 60 SHARE 🪙',
        style: const TextStyle(
          color: Color(0xFF00B09B),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCumulativeShareAccountCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 누적 셰어 통장 🏦',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8B95A1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_collectedShareCoins.toInt()} SHARE',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191F28),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _openMyWallet,
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xCC00D2B4),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCoinJarSection({
    required double currentPendingShare,
    required bool hasPendingCoins,
    required int pendingCoinsInt,
  }) {
    final isMaxDailyReached = (_claimedSteps * 0.01).toInt() >= 60;
    if (isMaxDailyReached) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D2B4), Color(0xFF00B09B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D2B4).withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              '오늘의 목표 달성!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '오늘 하루도 열심히 달리셨네요.\n고생하셨습니다. 내일 다시 걸어보죠! 🏃‍♂️✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
    return _PiggyBankCard(
      currentPendingShare: currentPendingShare,
      hasPendingCoins: hasPendingCoins,
      pendingCoinsInt: pendingCoinsInt,
      onClaim: () => unawaited(_onHarvestCoins()),
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
  }) {
    final finalProgress = _hybridProgress(
      tier: tier,
      currentKm: currentKm,
      currentSteps: currentSteps,
    );
    final percent = (finalProgress * 100).toInt();
    final charSize = characterSize.clamp(40.0, 50.0);
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
          style: AppTextStyles.agreementLabel.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: complete ? AppColors.tealAccent : const Color(0xFF333D4B),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: charSize + 14,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const barH = 14.0;
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
                    bottom: 0,
                    height: barH,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xFFD9D2C8)),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: trailT,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1B5E40),
                                    Color(0xFF2E8B57),
                                    Color(0xFF6FE3B2),
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
                    bottom: 0,
                    width: 2,
                    height: barH,
                    child: const ColoredBox(color: Color(0x886D4C41)),
                  ),
                  Positioned(
                    left: flagLeft,
                    bottom: barH - 2,
                    width: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '3km',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: const Color(0xFF2E7D4F),
                          ),
                        ),
                        const Icon(
                          Icons.flag_rounded,
                          size: 18,
                          color: Color(0xFFE53935),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: left,
                    bottom: barH,
                    width: charSize,
                    height: charSize,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/images/characters/chibi_snail_disappointed.png',
                        width: charSize,
                        height: charSize,
                        fit: BoxFit.contain,
                        color: tier.walkCanvasStart,
                        colorBlendMode: BlendMode.multiply,
                        filterQuality: FilterQuality.medium,
                      ),
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

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.header1.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TierBoardCard extends StatelessWidget {
  const _TierBoardCard({required this.tier});

  final UserTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '[${tier.koreanName}] 산책 중',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '목표 ${tier.targetKm.toStringAsFixed(1)}km',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.tealAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PiggyBankCard extends StatelessWidget {
  const _PiggyBankCard({
    required this.currentPendingShare,
    required this.hasPendingCoins,
    required this.pendingCoinsInt,
    required this.onClaim,
  });

  final double currentPendingShare;
  final bool hasPendingCoins;
  final int pendingCoinsInt;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF00D2B4).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '줍기 대기 : ${currentPendingShare.toStringAsFixed(2)} SHARE',
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.tealAccent,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: hasPendingCoins ? onClaim : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
                disabledBackgroundColor:
                    AppColors.tealAccent.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                hasPendingCoins
                    ? '$pendingCoinsInt SHARE 줍기'
                    : '코인 쌓이는 중...',
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayKmBadge extends StatelessWidget {
  const _TodayKmBadge({required this.km});

  final double km;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_run,
            size: 16,
            color: AppColors.tealAccent,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${km.toStringAsFixed(2)} km',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.tealAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KcalBadge extends StatelessWidget {
  const _KcalBadge({required this.kcal});

  final double kcal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: Color(0xFFFF7043),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${kcal.toStringAsFixed(1)} kcal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: const Color(0xFFE64A19),
              ),
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFF00D2B4).withValues(alpha: 0.08)
            : const Color(0xFF9E9E9E).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.notifications_active : Icons.notifications_off,
            size: 18,
            color: enabled ? const Color(0xFF00B09B) : AppColors.textGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              enabled
                  ? '워킹챌린지 혜택 알림 받는 중 🔔'
                  : '혜택 알림이 완전히 꺼져 있습니다 🔕',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: enabled ? AppColors.textBlack : AppColors.textGrey,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: enabled ? Colors.white : const Color(0xFF00D2B4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: enabled
                      ? const Color(0xFF00B09B)
                      : const Color(0xFF00D2B4),
                ),
              ),
              child: Text(
                enabled ? '알림 해지' : '알림 받기',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: enabled ? const Color(0xFF00B09B) : Colors.white,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주 분석 일지',
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.agreementBoxFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              selected == null
                  ? '날짜를 선택하면 그날의 걸음 수가 표시됩니다.'
                  : '${selected.month}월 ${selected.day}일의 누적 걸음수: ${_comma(displaySelectedSteps)}보',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.textBlack,
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
    final fill = complete
        ? AppColors.tealAccent
        : AppColors.surfaceWhite;
    final fg = complete ? AppColors.textWhite : AppColors.textBlack;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 62,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: selected
                ? AppColors.tealAccent
                : AppColors.borderLight.withValues(alpha: 0.8),
            width: selected ? 2 : 1,
          ),
          boxShadow: complete
              ? [
                  BoxShadow(
                    color: AppColors.tealAccent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: complete ? AppColors.textWhite : AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: AppTextStyles.agreementLabel.copyWith(
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
                  color: AppColors.angelGold.withValues(alpha: glow),
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
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3C4),
            AppColors.goldBadge,
            AppColors.angelGold,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.angelGold.withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.surfaceWhite, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        'S',
        style: AppTextStyles.header1.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 28,
          color: AppColors.textBlack,
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
