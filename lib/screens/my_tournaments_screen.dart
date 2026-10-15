import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/theme/theme.dart';
import '../core/widgets/async_value_section.dart';
import '../features/challenge/widgets/challenge_look.dart';
import '../data/models/tournament_participation_model.dart';

class MyTournamentsScreen extends ConsumerWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(joinedTournamentParticipationsProvider);
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    final inTabs = DefaultTabController.maybeOf(context) != null;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.page,
        inTabs ? tokens.spacing.xs : tokens.spacing.page,
        tokens.spacing.page,
        96,
      ),
      children: [
        if (!inTabs) ...[
          Text(
            'My Tournaments',
            style: textTheme.headlineSmall?.copyWith(color: tokens.colors.ink),
          ),
          SizedBox(height: tokens.spacing.xs),
        ],
        Text(
          '참가한 대회 방과 참가 상태를 확인하세요.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.colors.muted),
        ),
        AsyncValueSection<List<TournamentParticipationModel>>(
          asyncValue: participationsAsync,
          dataBuilder: (context, participations) {
            if (participations.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: tokens.spacing.md),
                child: SrcSurfaceCard(
                  padding: EdgeInsets.all(tokens.spacing.md + 2),
                  child: Text(
                    '아직 참가한 대회가 없습니다.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.colors.muted,
                    ),
                  ),
                ),
              );
            }

            final active = participations
                .where((p) => !p.tournament.isTerminal)
                .toList();
            final past = participations
                .where((p) => p.tournament.isTerminal)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (active.isNotEmpty) ...[
                  const ChallengeSectionLabel('참가 중'),
                  for (final p in active) _row(context, p),
                ],
                if (past.isNotEmpty) ...[
                  const ChallengeSectionLabel('지난 대회'),
                  for (final p in past) _row(context, p),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// 지도의 한 줄 모양: 동그란 아이콘 + 제목/설명 + 오른쪽 상태.
  Widget _row(BuildContext context, TournamentParticipationModel p) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final done = p.tournament.isTerminal;
    return InkWell(
      onTap: () => context.push(
        RouteNames.tournamentRoomDetail(p.tournament.id),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.colors.outline)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tokens.colors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.emoji_events_outlined : Icons.directions_run,
                size: 20,
                color: tokens.colors.accent,
              ),
            ),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.tournament.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: tokens.colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${p.entryFeeShare} Share entry · '
                    '${p.tournament.recruitmentSummary}',
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              p.isRefunded ? 'Refunded' : 'Joined',
              style: textTheme.labelLarge?.copyWith(
                color: p.isRefunded
                    ? tokens.colors.muted
                    : tokens.colors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
