import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../features/tournaments/utils/sponsor_display.dart';
import '../app/theme/app_colors.dart';
import '../core/strings/app_strings.dart';
import '../core/widgets/async_value_section.dart';
import '../l10n/remaining_surface.dart';
import '../data/models/tournament_model.dart';
import '../data/models/tournament_participation_model.dart';
import '../data/models/user_model.dart';
import '../features/run_tracking/utils/run_start_preflight.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/tournaments/providers/company_tournament_providers.dart';
import '../features/tournaments/providers/local_joined_ids_provider.dart';
import '../features/tournaments/utils/prize_display.dart';
import '../features/tournaments/utils/prize_race_entry.dart';
import '../features/tournaments/utils/tournament_join_flow.dart';
import '../features/tournaments/utils/tournament_join_gate.dart';
import '../features/tournaments/widgets/sponsor_rolling_banner.dart';
import 'sponsor_payment_screen.dart';
import '../core/config/app_env.dart';

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

    final configAsync = ref.watch(companyTournamentConfigProvider);

    if (participation != null) {
      return _JoinedTournamentDetail(
        participation: participation,
        profile: ref.watch(activeUserProfileProvider).value,
        prizeLine: prizePoolLine(
          room: participation.tournament,
          configLoading: configAsync.isLoading,
          config: configAsync.asData?.value,
        ),
      );
    }

    final tournamentAsync = ref.watch(tournamentByIdProvider(tournamentId));
    final authUser = ref.watch(authStateChangesProvider).value;
    final userTier = ref.watch(activeUserTierProvider).value ?? 1;
    final joinedIds = ref.watch(effectiveJoinedTournamentIdsProvider);
    final extraEntryTickets =
        ref.watch(serverShopInventoryProvider).asData?.value.extraEntryCount ??
            0;
    final freeTickets =
        ref.watch(activeWalletProvider).asData?.value.freeTicketBalance ?? 0;
    ref.watch(signupFreeTicketGrantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          RemainingSurface.tr(context, 'tournament_detail.title', '대회 상세'),
        ),
      ),
      body: AsyncValueSection<TournamentModel?>(
        asyncValue: tournamentAsync,
        dataBuilder: (context, room) {
          if (room == null) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                RemainingSurface.tr(
                  context,
                  'tournament_detail.body',
                  '대회를 찾을 수 없습니다.',
                ),
              ),
            );
          }

          final isJoined = joinedIds.contains(room.id);
          final canJoin = TournamentJoinGate.canAttemptJoin(
            signedIn: authUser != null,
            alreadyJoined: isJoined,
            tournament: room,
            userTier: userTier,
            extraEntryTickets: extraEntryTickets,
          );
          final withTicket = TournamentJoinGate.extraEntryCanOpen(room);
          final quote = resolvePrizeRaceQuote(
            tournament: room,
            configLoading: configAsync.isLoading,
            config: configAsync.asData?.value,
          );
          final prizeReady = quote == null || quote.ready;
          final ticketChoice = quote?.canUseTickets(freeTickets) ?? false;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SponsorRollingBanner(messages: room.sponsorBillboardMessages),
              _TournamentInfoCard(
                room: room,
                entryFeeShare: room.entryFeeShare,
                feeText: quote?.costLabel(freeTickets),
                rulesText: quote?.rulesLabel,
                participantStatus: isJoined ? 'joined' : null,
              ),
              const SizedBox(height: 12),
              Text(
                prizePoolLine(
                  room: room,
                  configLoading: configAsync.isLoading,
                  config: configAsync.asData?.value,
                ),
              ),
              const SizedBox(height: 24),
              if (canJoin && prizeReady)
                FilledButton.icon(
                  onPressed: () => joinTournamentWithPreflight(
                    context: context,
                    ref: ref,
                    tournament: room,
                    prizeEntryShare:
                        quote != null && quote.ready ? quote.entryShare : null,
                    prizeTicketCost: quote?.ticketCost ?? 0,
                    freeTicketBalance: freeTickets,
                  ),
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: Text(
                    withTicket
                        ? RemainingSurface.tr(
                            context,
                            'tournament_detail.body.2',
                            '추가 참가권으로 참가',
                          )
                        : quote != null
                            ? quote.shareJoinLabel
                            : RemainingSurface.tr(
                                context,
                                'tournament_detail.body.3',
                                '${room.entryFeeShare} SHARE로 참가',
                                {'room.entryFeeShare': room.entryFeeShare},
                              ),
                  ),
                ),
              if (canJoin && ticketChoice) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => joinTournamentWithPreflight(
                    context: context,
                    ref: ref,
                    tournament: room,
                    entryMethod: 'ticket',
                    prizeEntryShare: quote!.entryShare,
                    prizeTicketCost: quote.ticketCost,
                    freeTicketBalance: freeTickets,
                  ),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: Text(quote!.ticketJoinLabel),
                ),
              ],
              if (canJoin && quote?.tierTicketJoinLabel != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => joinTournamentWithPreflight(
                    context: context,
                    ref: ref,
                    tournament: room,
                    entryMethod: 'tier_ticket',
                    prizeEntryShare: quote!.entryShare,
                  ),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: Text(quote!.tierTicketJoinLabel!),
                ),
              ],
              if (canJoin && quote != null && !quote.ready)
                Text(quote.shareJoinLabel)
              else if (authUser == null)
                Text(
                  RemainingSurface.tr(
                    context,
                    'tournament_detail.body.4',
                    '로그인 후 참가할 수 있습니다.',
                  ),
                )
              else if (room.lockedForTier(userTier))
                Text(
                  RemainingSurface.tr(
                    context,
                    'tournament_detail.body.5',
                    '현재 티어에서는 참가할 수 없습니다.',
                  ),
                )
              else if (room.isFull)
                Text(
                  RemainingSurface.tr(
                    context,
                    'tournament_detail.body.6',
                    '정원이 가득 찼습니다.',
                  ),
                )
              else if (!room.isRecruiting)
                Text(
                  RemainingSurface.tr(
                    context,
                    'tournament_detail.body.7',
                    '모집이 종료된 대회입니다.',
                  ),
                )
              else if (isJoined)
                Text(
                  RemainingSurface.tr(
                    context,
                    'tournament_detail.button',
                    '이미 참가한 대회입니다.',
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '${RouteNames.tournament}?tournamentId=${room.id}',
                ),
                icon: const Icon(Icons.list_rounded),
                label: Text(
                  RemainingSurface.tr(
                    context,
                    'tournament_detail.button.2',
                    '대회 목록에서 보기',
                  ),
                ),
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
    required this.prizeLine,
  });

  final TournamentParticipationModel participation;
  final UserModel? profile;
  final String prizeLine;

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
            ticketRewardLabel: participation.ticketRewardLabel,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.winnerRewardNoConversion,
            style: const TextStyle(
              color: AppColors.neonLime,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(prizeLine),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => startRunWithPreflight(
              context: context,
              profile: profile,
            ),
            icon: const Icon(Icons.directions_run_rounded),
            label: Text(
              RemainingSurface.tr(
                context,
                'tournament_detail.button.3',
                '러닝 시작하기',
              ),
            ),
          ),
          if (AppEnv.sponsorPaymentsVisible) ...[
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
              label: Text(
                RemainingSurface.tr(
                  context,
                  'tournament_detail.body.8',
                  '스폰서 후원하기',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TournamentInfoCard extends StatelessWidget {
  const _TournamentInfoCard({
    required this.room,
    required this.entryFeeShare,
    this.feeText,
    this.rulesText,
    this.participantStatus,
    this.joinedAt,
    this.ticketRewardLabel,
  });

  final TournamentModel room;
  final int entryFeeShare;
  final String? feeText;
  final String? rulesText;
  final String? participantStatus;
  final DateTime? joinedAt;
  final String? ticketRewardLabel;

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
          Text(
            RemainingSurface.tr(
              context,
              'tournament_detail.body.9',
              '후원: ${displaySponsorName(room.sponsorName)}',
              {
                'displaySponsorName(room.sponsorName)':
                    displaySponsorName(room.sponsorName),
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            RemainingSurface.tr(
              context,
              'tournament_detail.body.10',
              '상태: ${_statusKo(room.status)}',
              {'_statusKo(room.status)': _statusKo(room.status)},
            ),
          ),
          const SizedBox(height: 8),
          Text(
            RemainingSurface.tr(
              context,
              'tournament_detail.body.11',
              '목표 거리: ${room.targetDistanceKm.toStringAsFixed(1)} km',
              {
                'room.targetDistanceKm.toStringAsFixed(1)':
                    room.targetDistanceKm.toStringAsFixed(1),
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(feeText == null
              ? RemainingSurface.tr(
                  context,
                  'tournament_detail.body.12',
                  '참가비: $entryFeeShare SHARE',
                  {'entryFeeShare': entryFeeShare},
                )
              : RemainingSurface.tr(
                  context,
                  'tournament_detail.body.13',
                  '참가비: $feeText',
                  {'feeText': feeText},
                )),
          if (rulesText != null) ...[
            const SizedBox(height: 8),
            Text(rulesText!),
          ],
          if (participantStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              participantStatus == 'refunded'
                  ? RemainingSurface.tr(
                      context,
                      'tournament_detail.body.14',
                      '모집 인원이 차지 않아 참가비를 돌려드렸어요.',
                    )
                  : '참가 상태: ${participantStatus == 'joined' ? '참가 중' : participantStatus}',
            ),
          ],
          if (joinedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              RemainingSurface.tr(
                context,
                'tournament_detail.body.16',
                '참가일: ${_formatDate(joinedAt!)}',
                {'_formatDate(joinedAt!)': _formatDate(joinedAt!)},
              ),
            ),
          ],
          if (ticketRewardLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              ticketRewardLabel!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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

String _statusKo(TournamentStatus status) => switch (status) {
      TournamentStatus.recruiting =>
        RemainingSurface.trNow('tournament_detail.body.17', '모집 중'),
      TournamentStatus.active =>
        RemainingSurface.trNow('tournament_detail.body.18', '진행 중'),
      TournamentStatus.cancelled =>
        RemainingSurface.trNow('tournament_detail.body.19', '취소됨'),
      TournamentStatus.cancelledBepNotMet =>
        RemainingSurface.trNow('tournament_detail.body.20', '인원 미달로 취소됨'),
      TournamentStatus.completed =>
        RemainingSurface.trNow('tournament_detail.body.21', '종료'),
    };
