import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/strings/app_strings.dart';
import '../../pedometer/kst_calendar.dart';
import '../../profile/user_profile_notifier.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../stamp_tour_progress_store.dart';

@immutable
class StampLandmark {
  const StampLandmark({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isVisited,
    this.diamondReward = 1,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isVisited;
  final int diamondReward;

  StampLandmark copyWith({bool? isVisited}) {
    return StampLandmark(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      isVisited: isVisited ?? this.isVisited,
      diamondReward: diamondReward,
    );
  }
}

@immutable
class StampTourState {
  const StampTourState({
    required this.landmarks,
    required this.walkMissionCompleted,
    required this.walkDistanceKm,
    required this.claiming,
    this.currentPosition,
    this.lastError,
  });

  final List<StampLandmark> landmarks;
  final bool walkMissionCompleted;
  final double walkDistanceKm;
  final bool claiming;
  final Position? currentPosition;
  final String? lastError;

  int get visitedCount =>
      landmarks.where((landmark) => landmark.isVisited).length;

  bool get stampMissionCompleted => visitedCount >= landmarks.length;

  String get stampMissionTitle =>
      '우리 동네 랜드마크 스탬프 찍기 ($visitedCount/${landmarks.length})';

  factory StampTourState.initial() {
    return StampTourState(
      landmarks: const [
        StampLandmark(
          id: 'gangbyeon',
          name: AppStrings.stampTourLandmarkGangbyeon,
          // Yeouido Hangang Park vicinity
          latitude: 37.5283,
          longitude: 126.9326,
          isVisited: false,
          diamondReward: 1,
        ),
        StampLandmark(
          id: 'namsan',
          name: AppStrings.stampTourLandmarkNamsan,
          latitude: 37.5512,
          longitude: 126.9882,
          isVisited: false,
          diamondReward: 1,
        ),
        StampLandmark(
          id: 'modoil',
          name: AppStrings.stampTourLandmarkModoil,
          // Seoul Forest / park stand-in
          latitude: 37.5443,
          longitude: 127.0374,
          isVisited: false,
          diamondReward: 1,
        ),
      ],
      walkMissionCompleted: false,
      walkDistanceKm: 0,
      claiming: false,
    );
  }

  StampTourState copyWith({
    List<StampLandmark>? landmarks,
    bool? walkMissionCompleted,
    double? walkDistanceKm,
    bool? claiming,
    Position? currentPosition,
    String? lastError,
    bool clearError = false,
  }) {
    return StampTourState(
      landmarks: landmarks ?? this.landmarks,
      walkMissionCompleted: walkMissionCompleted ?? this.walkMissionCompleted,
      walkDistanceKm: walkDistanceKm ?? this.walkDistanceKm,
      claiming: claiming ?? this.claiming,
      currentPosition: currentPosition ?? this.currentPosition,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final stampTourProvider =
    NotifierProvider<StampTourNotifier, StampTourState>(StampTourNotifier.new);

class StampTourNotifier extends Notifier<StampTourState> {
  static const _unlockRadiusMeters = 50.0;
  static const _walkMissionKm = 1.0;

  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  final Set<String> _rewardedLandmarkIds = <String>{};
  var _walkRewardClaimed = false;
  var _hydrated = false;

  @override
  StampTourState build() {
    ref.onDispose(() {
      _positionSub?.cancel();
      _positionSub = null;
    });
    Future.microtask(() async {
      await _hydratePersistedProgress();
      await startTracking();
    });
    return StampTourState.initial();
  }

  Future<void> _hydratePersistedProgress() async {
    try {
      final progress = await const StampTourProgressStore().read(
        todayKey: KstCalendar.dateKey(),
      );
      _rewardedLandmarkIds
        ..clear()
        ..addAll(progress.rewardedLandmarkIds);
      _walkRewardClaimed = progress.walkRewardClaimed;
      final landmarks = state.landmarks
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
      );
      _hydrated = true;
    } catch (e) {
      debugPrint('StampTour hydrate: $e');
      _hydrated = true;
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
          rewardedLandmarkIds: Set<String>.from(_rewardedLandmarkIds),
          walkMissionCompleted: state.walkMissionCompleted,
          walkDistanceKm: state.walkDistanceKm,
          walkRewardClaimed: _walkRewardClaimed,
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
          state = state.copyWith(lastError: 'GPS 수신 중 오류가 발생했습니다.');
        },
      );
    } catch (e) {
      debugPrint('StampTour startTracking error: $e');
      state = state.copyWith(lastError: '위치 추적을 시작할 수 없습니다.');
    }
  }

  Future<void> _onPosition(Position position) async {
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

    if (!next.walkMissionCompleted && walkKm >= _walkMissionKm) {
      next = next.copyWith(walkMissionCompleted: true);
      state = next;
      await _persistProgress();
      if (!_walkRewardClaimed) {
        _walkRewardClaimed = true;
        await claimDiamondReward(diamondAmount: 1);
      }
    } else {
      state = next;
      await _persistProgress();
    }

    await checkLocationAndUnlock(position);
  }

  Future<void> checkLocationAndUnlock(Position currentPosition) async {
    final unlocked = await _unlockNearestIfInRange(currentPosition);
    if (unlocked == null) return;
    if (!_rewardedLandmarkIds.contains(unlocked.id)) {
      _rewardedLandmarkIds.add(unlocked.id);
      await claimDiamondReward(diamondAmount: unlocked.diamondReward);
    }
  }

  /// Manual stamp-mission tap. Returns a user-facing snackbar message, or null.
  Future<String?> tryClaimStampMission() async {
    if (state.stampMissionCompleted) {
      return '모든 랜드마크 스탬프를 이미 획득했습니다.';
    }

    final position = await _resolveCurrentPosition();
    if (position == null) {
      return '현재 위치를 확인할 수 없습니다. 위치 권한을 허용해 주세요.';
    }

    final unlocked = await _unlockNearestIfInRange(position);
    if (unlocked == null) {
      return '목표 랜드마크 반경 50m 이내로 접근해 주세요.';
    }

    if (!_rewardedLandmarkIds.contains(unlocked.id)) {
      _rewardedLandmarkIds.add(unlocked.id);
      await claimDiamondReward(diamondAmount: unlocked.diamondReward);
    }
    return '${unlocked.name} 스탬프 획득! 다이아몬드 +${unlocked.diamondReward}';
  }

  /// Manual walk-mission tap. Returns a user-facing snackbar message, or null.
  Future<String?> tryClaimWalkMission() async {
    if (state.walkMissionCompleted) {
      return '오늘의 1km 걷기 미션을 이미 완료했습니다.';
    }

    await _resolveCurrentPosition();
    if (state.walkDistanceKm >= _walkMissionKm) {
      state = state.copyWith(walkMissionCompleted: true);
      await _persistProgress();
      if (!_walkRewardClaimed) {
        _walkRewardClaimed = true;
        await claimDiamondReward(diamondAmount: 1);
      }
      return '1km 걷기 미션 완료! 다이아몬드 +1';
    }

    final remain =
        (_walkMissionKm - state.walkDistanceKm).clamp(0.0, _walkMissionKm);
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

      if (meters.isFinite && meters <= _unlockRadiusMeters) {
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

  /// Credits local wallet DIA immediately so stamp claims are not a no-op.
  Future<void> claimDiamondReward({required int diamondAmount}) async {
    if (diamondAmount <= 0 || state.claiming) return;

    state = state.copyWith(claiming: true, clearError: true);
    try {
      ref.read(walletProvider.notifier).creditDia(diamondAmount);
      await ref.read(userProfileNotifierProvider.notifier).writeTransactionReceipt(
            title: '스탬프 투어 DIA 보상',
            amount: diamondAmount,
            assetType: 'DIA',
          );
      await _persistProgress();
    } catch (e) {
      debugPrint('claimDiamondReward error: $e');
      state = state.copyWith(lastError: '다이아몬드 보상 저장에 실패했습니다.');
    } finally {
      state = state.copyWith(claiming: false);
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
