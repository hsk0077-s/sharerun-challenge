import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../pedometer/kst_calendar.dart';
import '../firestore_stamp_landmark_source.dart';
import '../stamp_landmark.dart';
import '../stamp_landmark_catalog.dart';
import '../stamp_tour_progress_store.dart';

export '../stamp_landmark.dart';

@immutable
class StampTourState {
  const StampTourState({
    required this.landmarks,
    required this.walkMissionCompleted,
    required this.walkDistanceKm,
    required this.claiming,
    required this.walkOfficialDiaPending,
    required this.pendingOfficialRewardIds,
    this.currentPosition,
    this.lastError,
  });

  final List<StampLandmark> landmarks;
  final bool walkMissionCompleted;
  final double walkDistanceKm;
  final bool claiming;
  final bool walkOfficialDiaPending;
  final Set<String> pendingOfficialRewardIds;
  final Position? currentPosition;
  final String? lastError;

  List<StampLandmark> get officialLandmarks =>
      landmarks.where((landmark) => landmark.origin.isOfficial).toList();

  int get officialVisitedCount =>
      officialLandmarks.where((landmark) => landmark.isVisited).length;

  int get visitedCount =>
      landmarks.where((landmark) => landmark.isVisited).length;

  bool get stampMissionCompleted =>
      officialLandmarks.isNotEmpty &&
      officialLandmarks.every((landmark) => landmark.isVisited);

  bool get officialStampDiaPending =>
      officialLandmarks.any(
        (landmark) =>
            landmark.isVisited && pendingOfficialRewardIds.contains(landmark.id),
      );

  String get stampMissionTitle =>
      '우리 동네 랜드마크 스탬프 찍기 ($officialVisitedCount/${officialLandmarks.length})';

  factory StampTourState.initial() {
    return const StampTourState(
      landmarks: SeedStampLandmarkCatalog.seoulDemo,
      walkMissionCompleted: false,
      walkDistanceKm: 0,
      claiming: false,
      walkOfficialDiaPending: false,
      pendingOfficialRewardIds: {},
    );
  }

  StampTourState copyWith({
    List<StampLandmark>? landmarks,
    bool? walkMissionCompleted,
    double? walkDistanceKm,
    bool? claiming,
    bool? walkOfficialDiaPending,
    Set<String>? pendingOfficialRewardIds,
    Position? currentPosition,
    String? lastError,
    bool clearError = false,
  }) {
    return StampTourState(
      landmarks: landmarks ?? this.landmarks,
      walkMissionCompleted: walkMissionCompleted ?? this.walkMissionCompleted,
      walkDistanceKm: walkDistanceKm ?? this.walkDistanceKm,
      claiming: claiming ?? this.claiming,
      walkOfficialDiaPending:
          walkOfficialDiaPending ?? this.walkOfficialDiaPending,
      pendingOfficialRewardIds:
          pendingOfficialRewardIds ?? this.pendingOfficialRewardIds,
      currentPosition: currentPosition ?? this.currentPosition,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final stampLandmarkCatalogProvider = Provider<StampLandmarkCatalog>((ref) {
  return StampLandmarkCatalog(
    remote: FirestoreStampLandmarkSource(ref.watch(firestoreServiceProvider)),
  );
});

final stampTourProvider =
    NotifierProvider<StampTourNotifier, StampTourState>(StampTourNotifier.new);

class StampTourNotifier extends Notifier<StampTourState> {
  static const unlockRadiusMeters = 50.0;
  static const walkMissionKm = 1.0;
  static const walkRewardId = 'walk';

  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  Future<void>? _hydrateFuture;
  var _hydrated = false;
  var _nearbyLoaded = false;

  @override
  StampTourState build() {
    ref.onDispose(() {
      _positionSub?.cancel();
      _positionSub = null;
    });
    Future.microtask(() async {
      await _ensureHydrated();
      if (!_isLive) return;
      await startTracking();
    });
    return StampTourState.initial();
  }

  bool get _isLive => ref.mounted;

  Future<void> _ensureHydrated() {
    return _hydrateFuture ??= _hydrateCatalogAndProgress();
  }

  Future<void> _hydrateCatalogAndProgress() async {
    try {
      final catalog = await ref.read(stampLandmarkCatalogProvider).load(
            uid: ref.read(authStateChangesProvider).asData?.value?.uid,
          );
      final progress = await const StampTourProgressStore().read(
        todayKey: KstCalendar.dateKey(),
      );
      if (!_isLive) return;
      final landmarks = (catalog.isEmpty
              ? SeedStampLandmarkCatalog.seoulDemo
              : catalog)
          .map(
            (landmark) => landmark.copyWith(
              isVisited: progress.visitedLandmarkIds.contains(landmark.id),
            ),
          )
          .toList();
      state = state.copyWith(
        landmarks: landmarks,
        walkMissionCompleted: progress.walkMissionCompleted,
        walkDistanceKm: progress.walkDistanceKm,
        walkOfficialDiaPending: progress.walkRewardClaimed,
        pendingOfficialRewardIds: Set<String>.from(progress.rewardedLandmarkIds),
      );
    } catch (e) {
      debugPrint('StampTour hydrate: $e');
    } finally {
      _hydrated = true;
    }
  }

  Future<void> _maybeLoadNearby(Position position) async {
    if (_nearbyLoaded) return;
    _nearbyLoaded = true;
    try {
      final extra = await ref.read(stampLandmarkCatalogProvider).nearby.fetchNearby(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (extra.isEmpty || !_isLive) return;
      final existing = state.landmarks.map((landmark) => landmark.id).toSet();
      final progress = await const StampTourProgressStore().read(
        todayKey: KstCalendar.dateKey(),
      );
      if (!_isLive) return;
      final merged = [
        ...state.landmarks,
        ...extra.where((landmark) => !existing.contains(landmark.id)).map(
              (landmark) => landmark.copyWith(
                isVisited: progress.visitedLandmarkIds.contains(landmark.id),
              ),
            ),
      ];
      state = state.copyWith(landmarks: merged);
      await _persistProgress();
    } catch (e) {
      debugPrint('StampTour nearby hook: $e');
    }
  }

  Future<void> _persistProgress() async {
    if (!_hydrated) return;
    try {
      final visited = state.landmarks
          .where((landmark) => landmark.isVisited)
          .map((landmark) => landmark.id)
          .toSet();
      await const StampTourProgressStore().write(
        StampTourProgress(
          visitedLandmarkIds: visited,
          rewardedLandmarkIds: Set<String>.from(state.pendingOfficialRewardIds),
          walkMissionCompleted: state.walkMissionCompleted,
          walkDistanceKm: state.walkDistanceKm,
          walkRewardClaimed: state.walkOfficialDiaPending,
          walkDateKey: KstCalendar.dateKey(),
        ),
      );
    } catch (e) {
      debugPrint('StampTour persist: $e');
    }
  }

  Future<void> startTracking() async {
    if (_positionSub != null) return;

    try {
      final granted = await _ensureLocationPermission();
      if (!_isLive) return;
      if (!granted) {
        state = state.copyWith(
          lastError: '위치 권한이 필요합니다. 설정에서 허용해 주세요.',
        );
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      ).listen(
        (position) {
          unawaited(_onPosition(position));
        },
        onError: (Object e) {
          debugPrint('StampTour GPS error: $e');
          if (!_isLive) return;
          state = state.copyWith(lastError: 'GPS 수신 중 오류가 발생했습니다.');
        },
      );
    } catch (e) {
      debugPrint('StampTour startTracking error: $e');
      if (!_isLive) return;
      state = state.copyWith(lastError: '위치 추적을 시작할 수 없습니다.');
    }
  }

  Future<void> _onPosition(Position position) async {
    if (!_isLive) return;
    var walkKm = state.walkDistanceKm;
    final previous = _lastPosition;
    if (previous != null) {
      final delta = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      if (delta.isFinite && delta > 0) {
        walkKm += delta / 1000.0;
      }
    }
    _lastPosition = position;

    var next = state.copyWith(
      currentPosition: position,
      walkDistanceKm: walkKm,
      clearError: true,
    );

    if (!next.walkMissionCompleted && walkKm >= walkMissionKm) {
      next = next.copyWith(walkMissionCompleted: true);
      state = next;
      await _persistProgress();
      await enqueueOfficialDiaPending(rewardId: walkRewardId);
    } else {
      state = next;
      await _persistProgress();
    }

    await _maybeLoadNearby(position);
    await checkLocationAndUnlock(position);
  }

  Future<void> checkLocationAndUnlock(Position currentPosition) async {
    final unlocked = await _unlockNearestIfInRange(currentPosition);
    if (unlocked == null) return;
    if (unlocked.awardsOfficialDia) {
      await enqueueOfficialDiaPending(rewardId: unlocked.id);
    }
  }

  /// Manual stamp-mission tap. Returns a user-facing snackbar message, or null.
  Future<String?> tryClaimStampMission() async {
    await _ensureHydrated();
    if (state.stampMissionCompleted) {
      return '모든 공식 랜드마크 스탬프를 이미 획득했습니다.';
    }

    final position = await _resolveCurrentPosition();
    if (position == null) {
      return '현재 위치를 확인할 수 없습니다. 위치 권한을 허용해 주세요.';
    }

    final unlocked = await _unlockNearestIfInRange(position);
    if (unlocked == null) {
      return '목표 랜드마크 반경 50m 이내로 접근해 주세요.';
    }

    if (unlocked.awardsOfficialDia) {
      await enqueueOfficialDiaPending(rewardId: unlocked.id);
      return '${unlocked.name} 스탬프 획득! ${AppStrings.stampTourOfficialDiaPending}';
    }
    return '${unlocked.name} 개인 스탬프 기록됨 (공식 DIA 없음)';
  }

  /// Manual walk-mission tap. Returns a user-facing snackbar message, or null.
  Future<String?> tryClaimWalkMission() async {
    await _ensureHydrated();
    if (state.walkMissionCompleted) {
      return '오늘의 1km 걷기 미션을 이미 완료했습니다.';
    }

    await _resolveCurrentPosition();
    if (state.walkDistanceKm >= walkMissionKm) {
      state = state.copyWith(walkMissionCompleted: true);
      await _persistProgress();
      await enqueueOfficialDiaPending(rewardId: walkRewardId);
      return '1km 걷기 미션 완료! ${AppStrings.stampTourOfficialDiaPending}';
    }

    final remain =
        (walkMissionKm - state.walkDistanceKm).clamp(0.0, walkMissionKm);
    return '아직 ${remain.toStringAsFixed(2)}km 더 걸어주세요.';
  }

  Future<StampLandmark?> _unlockNearestIfInRange(Position currentPosition) async {
    final updated = <StampLandmark>[];
    StampLandmark? unlocked;

    for (final landmark in state.landmarks) {
      if (landmark.isVisited) {
        updated.add(landmark);
        continue;
      }

      final meters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        landmark.latitude,
        landmark.longitude,
      );

      if (meters.isFinite && meters <= unlockRadiusMeters) {
        final visited = landmark.copyWith(isVisited: true);
        updated.add(visited);
        unlocked ??= visited;
      } else {
        updated.add(landmark);
      }
    }

    if (unlocked != null) {
      state = state.copyWith(
        landmarks: updated,
        currentPosition: currentPosition,
        clearError: true,
      );
      await _persistProgress();
    } else {
      state = state.copyWith(currentPosition: currentPosition);
    }
    return unlocked;
  }

  Future<Position?> _resolveCurrentPosition() async {
    if (state.currentPosition != null) {
      return state.currentPosition;
    }
    try {
      final granted = await _ensureLocationPermission();
      if (!granted) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      state = state.copyWith(currentPosition: position);
      return position;
    } catch (e) {
      debugPrint('StampTour getCurrentPosition error: $e');
      return null;
    }
  }

  /// Official DIA is server-owned. Client persists a pending claim and does
  /// not fake a minted wallet credit while `addDiamondBalance` is a stub.
  ///
  /// Future seam: replace this body with a callable / Cloud Function that
  /// mints DIA for `officialSeed` / `officialRemote` / `nearbyAuto` only,
  /// then flip pending → minted. Personal (`userProposal` / `crewProposal`)
  /// stamps must never enter this queue.
  Future<void> enqueueOfficialDiaPending({required String rewardId}) async {
    await _ensureHydrated();
    if (rewardId.isEmpty) return;
    final pending = Set<String>.from(state.pendingOfficialRewardIds);
    var walkPending = state.walkOfficialDiaPending;
    if (rewardId == walkRewardId) {
      walkPending = true;
    } else {
      pending.add(rewardId);
    }
    state = state.copyWith(
      pendingOfficialRewardIds: pending,
      walkOfficialDiaPending: walkPending,
      claiming: true,
      clearError: true,
    );
    try {
      await _persistProgress();
    } catch (e) {
      debugPrint('enqueueOfficialDiaPending: $e');
      if (_isLive) {
        state = state.copyWith(lastError: '공식 DIA 대기 기록에 실패했습니다.');
      }
    } finally {
      if (_isLive) {
        state = state.copyWith(claiming: false);
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
