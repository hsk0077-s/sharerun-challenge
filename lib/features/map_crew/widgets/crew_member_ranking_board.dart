import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/crew_member_ranking_model.dart';

class CrewMemberRankingBoard extends StatelessWidget {
  const CrewMemberRankingBoard({
    required this.members,
    super.key,
  });

  final List<CrewMemberRankingModel> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Card(
        child: ListTile(
          title: Text('크루원 랭킹 데이터 없음'),
          subtitle: Text('출석률·평균 페이스가 여기에 표시됩니다.'),
        ),
      );
    }

    final sorted = [...members]
      ..sort((a, b) => a.averagePaceSecondsPerKm.compareTo(b.averagePaceSecondsPerKm));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '크루원 출석률 & 평균 페이스',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          '출석률 높은 순 · 페이스 빠른 순으로 B2B 크루 성과를 추적합니다.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...sorted.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MemberCard(rank: index + 1, member: member),
          );
        }),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.rank,
    required this.member,
  });

  final int rank;
  final CrewMemberRankingModel member;

  @override
  Widget build(BuildContext context) {
    final attendanceColor = member.attendanceRate >= 90
        ? AppColors.neonLime
        : member.attendanceRate >= 80
            ? AppColors.electricBlue
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rank == 1
              ? AppColors.neonLime.withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                rank == 1 ? AppColors.neonLime : AppColors.electricBlue,
            foregroundColor: Colors.black,
            child: Text('$rank'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event_available_rounded,
                        size: 16, color: attendanceColor),
                    const SizedBox(width: 4),
                    Text(
                      '출석 ${member.attendanceRate.toStringAsFixed(0)}%',
                      style: TextStyle(color: attendanceColor, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.speed_rounded,
                        size: 16, color: AppColors.electricBlue),
                    const SizedBox(width: 4),
                    Text(
                      '${member.formattedPace}/km',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${member.weeklyDistanceKm.toStringAsFixed(1)}km',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
