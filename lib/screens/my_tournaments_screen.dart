import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/theme/theme.dart';
import '../core/widgets/async_value_section.dart';
import '../data/models/tournament_participation_model.dart';

class MyTournamentsScreen extends ConsumerWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(joinedTournamentParticipationsProvider);
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.all(tokens.spacing.page),
      children: [
        Text(
          'My Tournaments',
          style: textTheme.headlineSmall?.copyWith(color: tokens.colors.ink),
        ),
        SizedBox(height: tokens.spacing.xs),
        Text(
          '참가한 대회 방과 참가 상태를 확인하세요.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.colors.muted),
        ),
        SizedBox(height: tokens.spacing.page),
        AsyncValueSection<List<TournamentParticipationModel>>(
          asyncValue: participationsAsync,
          dataBuilder: (context, participations) {
            if (participations.isEmpty) {
              return SrcSurfaceCard(
                padding: EdgeInsets.all(tokens.spacing.md + 2),
                child: Text(
                  '아직 참가한 대회가 없습니다.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.colors.muted,
                  ),
                ),
              );
            }

            return Column(
              children: participations
                  .map(
                    (participation) => SrcSurfaceCard(
                      margin: EdgeInsets.only(bottom: tokens.spacing.sm),
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.xs,
                        vertical: tokens.spacing.xxs,
                      ),
                      child: ListTile(
                        title: Text(
                          participation.tournament.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: tokens.colors.ink,
                          ),
                        ),
                        subtitle: Text(
                          '${participation.entryFeeShare} Share entry · '
                          '${participation.tournament.recruitmentSummary}',
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.colors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          participation.isRefunded ? 'Refunded' : 'Joined',
                          style: textTheme.labelLarge?.copyWith(
                            color: participation.isRefunded
                                ? tokens.colors.muted
                                : tokens.colors.primary,
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
