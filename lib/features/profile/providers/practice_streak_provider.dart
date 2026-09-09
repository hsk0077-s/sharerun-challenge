import 'dart:async' show Completer, unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/economy_constants.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../../wallet/providers/wallet_provider.dart';

/// 워킹 챌린지 완주 스트릭 — `last_streak_date` / `streak_count`.
@immutable
class PracticeStreakState {
  const PracticeStreakState({
    this.count = 0,
    this.lastDate = '',
    this.ready = false,
    this.diaRewardPending = false,
  });

  final int count;
  final String lastDate;
  final bool ready;
  final bool diaRewardPending;

  PracticeStreakState copyWith({
    int? count,
    String? lastDate,
    bool? ready,
    bool? diaRewardPending,
  }) {
    return PracticeStreakState(
      count: count ?? this.count,
      lastDate: lastDate ?? this.lastDate,
      ready: ready ?? this.ready,
      diaRewardPending: diaRewardPending ?? this.diaRewardPending,
    );
  }
}

class PracticeStreakNotifier extends Notifier<PracticeStreakState> {
  static const lastDateKey = 'last_streak_date';
  static const countKey = 'streak_count';

  Completer<void> _ready = Completer<void>();
  var _recording = false;

  @override
  PracticeStreakState build() {
    _ready = Completer<void>();
    ref.onDispose(() {
      if (!_ready.isCompleted) _ready.complete();
    });
    unawaited(_hydrate());
    return const PracticeStreakState();
  }

  /// 워킹 챌린지 완주 — 오늘 첫 완주일 때만 `streak_count` +1.
  Future<void> completeChallenge() async {
    await _ready.future;
    if (_recording) return;
    _recording = true;
    try {
      await _recordWalkingComplete();
    } finally {
      _recording = false;
    }
  }

  void consumeDiaReward() {
    if (!state.diaRewardPending) return;
    state = state.copyWith(diaRewardPending: false);
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = PedometerKstClock.dateKey();
      var count = prefs.getInt(countKey) ?? 0;
      final lastDate = prefs.getString(lastDateKey) ?? '';

      // 전날(또는 오늘) 완주가 없으면 연속 일수 초기화.
      if (lastDate.isEmpty || _daysBetween(lastDate, today) >= 2) {
        count = 0;
        await prefs.setInt(countKey, 0);
      }

      state = PracticeStreakState(
        count: count < 0 ? 0 : count,
        lastDate: lastDate,
        ready: true,
      );
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  Future<void> _recordWalkingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final today = PedometerKstClock.dateKey();
    var count = state.ready ? state.count : (prefs.getInt(countKey) ?? 0);
    var lastDate =
        state.ready ? state.lastDate : (prefs.getString(lastDateKey) ?? '');

    if (lastDate.isEmpty || _daysBetween(lastDate, today) >= 2) {
      count = 0;
    }
    if (lastDate == today) {
      state = PracticeStreakState(
        count: count,
        lastDate: lastDate,
        ready: true,
        diaRewardPending: state.diaRewardPending,
      );
      return;
    }

    count += 1;
    lastDate = today;
    await prefs.setInt(countKey, count);
    await prefs.setString(lastDateKey, lastDate);

    var diaRewardPending = false;
    if (count > 0 && count % EconomyConstants.streakBonusDays == 0) {
      ref
          .read(walletProvider.notifier)
          .creditDia(EconomyConstants.streakBonusDia);
      diaRewardPending = true;
    }

    state = PracticeStreakState(
      count: count,
      lastDate: lastDate,
      ready: true,
      diaRewardPending: diaRewardPending,
    );
  }

  int _daysBetween(String lastYmd, String todayYmd) {
    if (lastYmd.isEmpty) return 0;
    final last = DateTime.tryParse(lastYmd);
    final today = DateTime.tryParse(todayYmd);
    if (last == null || today == null) return 0;
    return today.difference(last).inDays;
  }
}

final practiceStreakProvider =
    NotifierProvider<PracticeStreakNotifier, PracticeStreakState>(
  PracticeStreakNotifier.new,
);
