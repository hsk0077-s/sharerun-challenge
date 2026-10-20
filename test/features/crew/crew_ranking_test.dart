import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/crew/crew_ranking.dart';

void main() {
  test('서버 순위 JSON을 읽는다', () {
    final ranking = CrewRanking.fromJson({
      'month': '2026-10',
      'min_members': 5,
      'ranked_crews': 2,
      'top': [
        {
          'rank': 1,
          'name': 'A',
          'average_km': 9.0,
          'distance_km': 90.0,
          'member_count': 10,
        },
      ],
      'mine': {
        'rank': 2,
        'name': 'B',
        'average_km': 5.0,
        'distance_km': 30.0,
        'member_count': 6,
      },
      'my_distance_km': 30.0,
      'my_member_count': 6,
      'my_eligible': true,
      'best_rank': 3,
    });
    expect(ranking.top.single.name, 'A');
    expect(ranking.mine!.rank, 2);
    expect(ranking.bestRank, 3);
    expect(ranking.myLine, '이번 달 2위 · 1인 평균 5.0km');
  });

  test('순위에 못 오른 크루는 이유를 듣는다', () {
    final small = CrewRanking.fromJson({
      'min_members': 5,
      'my_member_count': 2,
      'my_eligible': false,
    });
    expect(small.mine, isNull);
    expect(small.myLine, '크루원이 5명 이상이면 순위에 올라요. (지금 2명)');

    final idle = CrewRanking.fromJson({
      'min_members': 5,
      'my_member_count': 8,
      'my_eligible': true,
    });
    expect(idle.myLine, '이번 달에 달리면 순위에 올라요.');
  });
}
