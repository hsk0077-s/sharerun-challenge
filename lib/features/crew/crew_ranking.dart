import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crew_membership.dart';

/// 순위표의 한 줄. 서버가 계산한 값이다.
@immutable
class CrewRankRow {
  const CrewRankRow({
    required this.rank,
    required this.name,
    required this.averageKm,
    required this.distanceKm,
    required this.memberCount,
  });

  final int rank;
  final String name;

  /// 크루원 1인당 평균 거리(이번 달).
  final double averageKm;
  final double distanceKm;
  final int memberCount;

  factory CrewRankRow.fromJson(Map<String, dynamic> json) => CrewRankRow(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        averageKm: (json['average_km'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      );
}

/// 이번 달 크루 순위와 내 크루의 자리. 순위값은 이번 달 크루 거리 ÷ 크루원 수다.
@immutable
class CrewRanking {
  const CrewRanking({
    required this.month,
    required this.minMembers,
    required this.rankedCrews,
    required this.top,
    required this.mine,
    required this.myDistanceKm,
    required this.myMemberCount,
    required this.myEligible,
    required this.bestRank,
  });

  final String month;

  /// 이만큼 이상 모여야 순위에 오른다.
  final int minMembers;
  final int rankedCrews;
  final List<CrewRankRow> top;

  /// 순위에 오른 내 크루. 아니면 null.
  final CrewRankRow? mine;
  final double myDistanceKm;
  final int myMemberCount;
  final bool myEligible;

  /// 역대 최고 순위. 없으면 0.
  final int bestRank;

  factory CrewRanking.fromJson(Map<String, dynamic> json) {
    final top = json['top'];
    final mine = json['mine'];
    return CrewRanking(
      month: json['month'] as String? ?? '',
      minMembers: (json['min_members'] as num?)?.toInt() ?? 5,
      rankedCrews: (json['ranked_crews'] as num?)?.toInt() ?? 0,
      top: [
        if (top is List)
          for (final r in top)
            if (r is Map<String, dynamic>) CrewRankRow.fromJson(r),
      ],
      mine: mine is Map<String, dynamic> ? CrewRankRow.fromJson(mine) : null,
      myDistanceKm: (json['my_distance_km'] as num?)?.toDouble() ?? 0,
      myMemberCount: (json['my_member_count'] as num?)?.toInt() ?? 0,
      myEligible: json['my_eligible'] == true,
      bestRank: (json['best_rank'] as num?)?.toInt() ?? 0,
    );
  }

  /// 내 크루 한 줄 설명. 순위에 못 오른 이유도 말해 준다.
  String get myLine {
    final rank = mine;
    if (rank != null) {
      return '이번 달 ${rank.rank}위 · 1인 평균 ${rank.averageKm.toStringAsFixed(1)}km';
    }
    if (!myEligible) {
      return '크루원이 $minMembers명 이상이면 순위에 올라요. (지금 $myMemberCount명)';
    }
    return '이번 달에 달리면 순위에 올라요.';
  }
}

/// 서버에 닿을 수 없거나 크루가 없으면 null이라 순위 줄은 보이지 않는다.
final crewRankingProvider = FutureProvider.autoDispose<CrewRanking?>((ref) async {
  final api = ref.watch(crewApiProvider);
  final mine = await ref.watch(myCrewProvider.future);
  if (api == null || mine == null) return null;
  try {
    return await api.crewRanking();
  } catch (_) {
    return null;
  }
});
