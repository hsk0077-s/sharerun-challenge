import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../core/widgets/async_value_section.dart';
import '../data/models/tournament_participation_model.dart';

class MyTournamentsScreen extends ConsumerWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(joinedTournamentParticipationsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('My Tournaments', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          '참가한 대회 방과 참가 상태를 확인하세요.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        AsyncValueSection<List<TournamentParticipationModel>>(
          asyncValue: participationsAsync,
          dataBuilder: (context, participations) {
            if (participations.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text('아직 참가한 대회가 없습니다.'),
              );
            }

            return Column(
              children: participations
                  .map(
                    (participation) => Card(
                      child: ListTile(
                        title: Text(participation.tournament.title),
                        subtitle: Text(
                          '${participation.entryFeeShare} Share entry · '
                          '${participation.tournament.recruitmentSummary}',
                        ),
                        trailing: Text(
                          participation.isRefunded ? 'Refunded' : 'Joined',
                          style: TextStyle(
                            color: participation.isRefunded
                                ? AppColors.textSecondary
                                : AppColors.neonLime,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => context.push(
                          RouteNames.tournamentRoomDetail(
                            participation.tournament.id,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
