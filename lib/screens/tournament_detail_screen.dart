import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../core/widgets/async_value_section.dart';
import '../data/models/tournament_model.dart';
import '../data/models/tournament_participation_model.dart';
import '../data/models/user_model.dart';
import '../features/run_tracking/utils/run_start_preflight.dart';
import '../features/tournaments/providers/local_joined_ids_provider.dart';
import '../features/tournaments/utils/tournament_join_flow.dart';
import '../features/tournaments/widgets/sponsor_rolling_banner.dart';
import 'sponsor_payment_screen.dart';

class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({
    required this.tournamentId,
    super.key,
  });

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participations =
        ref.watch(joinedTournamentParticipationsProvider).value ?? const [];
    TournamentParticipationModel? participation;
    for (final item in participations) {
      if (item.tournament.id == tournamentId) {
        participation = item;
        break;
      }
    }

    if (participation != null) {
      return _JoinedTournamentDetail(
        participation: participation,
        profile: ref.watch(activeUserProfileProvider).value,
      );
    }

    final tournamentAsync = ref.watch(tournamentByIdProvider(tournamentId));
    final authUser = ref.watch(authStateChangesProvider).value;
    final userTier = ref.watch(activeUserTierProvider).value ?? 1;
    final joinedIds = ref.watch(effectiveJoinedTournamentIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Detail')),
      body: AsyncValueSection<TournamentModel?>(
        asyncValue: tournamentAsync,
        dataBuilder: (context, room) {
          if (room == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text('대회를 찾을 수 없습니다.'),
            );
          }

          final isJoined = joinedIds.contains(room.id);
          final canJoin = authUser != null &&
              room.isRecruiting &&
              !room.lockedForTier(userTier) &&
              !room.isFull &&
              !isJoined;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SponsorRollingBanner(messages: room.sponsorBillboardMessages),
              _TournamentInfoCard(
                room: room,
                entryFeeShare: room.entryFeeShare,
                participantStatus: isJoined ? 'joined' : null,
              ),
              const SizedBox(height: 24),
              if (canJoin)
                FilledButton.icon(
                  onPressed: () => joinTournamentWithPreflight(
                    context: context,
                    ref: ref,
                    tournament: room,
                  ),
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: Text('Join with ${room.entryFeeShare} Share'),
                )
              else if (authUser == null)
                const Text('로그인 후 참가할 수 있습니다.')
              else if (room.lockedForTier(userTier))
                const Text('현재 티어에서는 참가할 수 없습니다.')
              else if (room.isFull)
                const Text('정원이 가득 찼습니다.')
              else if (!room.isRecruiting)
                const Text('모집이 종료된 대회입니다.')
              else if (isJoined)
                const Text('이미 참가한 대회입니다.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '${RouteNames.tournament}?tournamentId=${room.id}',
                ),
                icon: const Icon(Icons.list_rounded),
                label: const Text('대회 목록에서 보기'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JoinedTournamentDetail extends StatelessWidget {
  const _JoinedTournamentDetail({
    required this.participation,
    required this.profile,
  });

  final TournamentParticipationModel participation;
  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    final room = participation.tournament;

    return Scaffold(
      appBar: AppBar(title: Text(room.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SponsorRollingBanner(messages: room.sponsorBillboardMessages),
          _TournamentInfoCard(
            room: room,
            entryFeeShare: participation.entryFeeShare,
            participantStatus: participation.isRefunded
                ? 'refunded'
                : participation.participantStatus,
            joinedAt: participation.joinedAt,
          ),
          const SizedBox(height: 16),
          Text(
            'Verified finish reward: +${room.winnerRewardValue} Value',
            style: const TextStyle(
              color: AppColors.neonLime,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text('Donation pool: ${room.donationValue} Value'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => startRunWithPreflight(
              context: context,
              profile: profile,
            ),
            icon: const Icon(Icons.directions_run_rounded),
            label: const Text('러닝 시작하기'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(
              RouteNames.sponsorPayment,
              extra: SponsorPaymentArgs(
                tournamentId: room.id,
                tournamentTitle: room.title,
              ),
            ),
            icon: const Icon(Icons.campaign_rounded),
            label: const Text('스폰서 후원하기'),
          ),
        ],
      ),
    );
  }
}

class _TournamentInfoCard extends StatelessWidget {
  const _TournamentInfoCard({
    required this.room,
    required this.entryFeeShare,
    this.participantStatus,
    this.joinedAt,
  });

  final TournamentModel room;
  final int entryFeeShare;
  final String? participantStatus;
  final DateTime? joinedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sponsor: ${room.sponsorName}'),
          const SizedBox(height: 8),
          Text('Status: ${room.status.name}'),
          const SizedBox(height: 8),
          Text('Target: ${room.targetDistanceKm.toStringAsFixed(1)} km'),
          const SizedBox(height: 8),
          Text('Entry: $entryFeeShare Share'),
          if (participantStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              participantStatus == 'refunded'
                  ? 'Refund: BEP refund processed'
                  : 'Participant status: $participantStatus',
            ),
          ],
          if (joinedAt != null) ...[
            const SizedBox(height: 8),
            Text('Joined: ${_formatDate(joinedAt!)}'),
          ],
          const SizedBox(height: 8),
          Text(room.recruitmentSummary),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year}.${value.month.toString().padLeft(2, '0')}.'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
