import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crew/crew_membership.dart';

/// 이번 달 운영자 기부금과 지금 향하는 목표(서버 값). 모두에게 같은 숫자이고 한 사람의 기록은 없다.
/// VALUE는 원화로 바꾸지 않으므로 여기에 VALUE는 나오지 않는다.
@immutable
class FundingSummary {
  const FundingSummary({
    required this.totalWon,
    required this.goalWon,
    required this.stage,
    required this.stageCount,
    required this.capWon,
    required this.capReached,
  });

  final int totalWon;

  /// 지금 향하는 목표. 모든 단계를 채웠으면 0.
  final int goalWon;
  final int stage;
  final int stageCount;

  /// 이번 달 운영자 기부 한도. 모르면 0.
  final int capWon;
  final bool capReached;

  bool get allReached => goalWon <= 0;

  /// 지금 목표를 향한 진행(0~1). 이전 단계 목표는 이미 채운 것으로 본다.
  double get ratio => allReached ? 1 : (totalWon / goalWon).clamp(0.0, 1.0);

  factory FundingSummary.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return FundingSummary(
      totalWon: n('total_won'),
      goalWon: n('goal_won'),
      stage: n('stage'),
      stageCount: n('stage_count'),
      capWon: n('cap_won'),
      capReached: json['cap_reached'] == true,
    );
  }
}

/// 서버에 닿을 수 없으면(목 데이터·로그인 전·오류) null이라 카드는 "준비 중"으로 남는다.
final fundingSummaryProvider = FutureProvider.autoDispose<FundingSummary?>((ref) async {
  final api = ref.watch(crewApiProvider);
  if (api == null) return null;
  try {
    return await api.fundingSummary();
  } catch (_) {
    return null;
  }
});
