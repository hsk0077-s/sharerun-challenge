import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../data/models/company_tournament_config.dart';
import '../data/models/tournament_model.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/tournaments/providers/company_tournament_providers.dart';
import '../features/tournaments/providers/local_joined_ids_provider.dart';
import '../features/tournaments/utils/prize_race_entry.dart';
import '../features/tournaments/utils/tournament_join_flow.dart';
import '../features/tournaments/utils/tournament_join_gate.dart';
import 'sponsor_payment_screen.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  const TournamentScreen({this.initialTournamentId, super.key});

  final String? initialTournamentId;

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  final _scrollController = ScrollController();
  final _cardKeys = <String, GlobalKey>{};
  var _scrolledToInitial = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInitialTournament() {
    if (_scrolledToInitial) {
      return;
    }
    final tournamentId = widget.initialTournamentId;
    if (tournamentId == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final key = _cardKeys[tournamentId];
      final cardContext = key?.currentContext;
      if (cardContext == null) {
        return;
      }
      _scrolledToInitial = true;
      Scrollable.ensureVisible(
        cardContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tournamentRoomsProvider, (previous, next) {
      if (next.hasValue && widget.initialTournamentId != null) {
        _scrollToInitialTournament();
      }
    });
    final rooms = ref.watch(tournamentRoomsProvider).value ?? const [];
    if (widget.initialTournamentId != null && rooms.isNotEmpty) {
      _scrollToInitialTournament();
    }
    final userTier = ref.watch(activeUserTierProvider).value ?? 1;
    final authUser = ref.watch(authStateChangesProvider).value;
    final joinedIds = ref.watch(effectiveJoinedTournamentIdsProvider);
    final extraEntryTickets =
        ref.watch(serverShopInventoryProvider).asData?.value.extraEntryCount ??
            0;
    final configAsync = ref.watch(companyTournamentConfigProvider);
    final freeTickets =
        ref.watch(activeWalletProvider).asData?.value.freeTicketBalance ?? 0;
    ref.watch(signupFreeTicketGrantProvider);
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final onDonation = Theme.of(context).colorScheme.onTertiary;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.all(tokens.spacing.page),
      children: [
        SrcSurfaceCard(
          color: tokens.colors.donation.withValues(alpha: 0.16),
          borderColor: tokens.colors.donation.withValues(alpha: 0.45),
          padding: EdgeInsets.all(tokens.spacing.md + 2),
          child: Text(
            'Sponsor Boost: Every verified sweat drop funds real impact.',
            style: textTheme.titleSmall?.copyWith(
              color: onDonation,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tournament Rooms',
                style: textTheme.headlineSmall?.copyWith(
                  color: tokens.colors.ink,
                ),
              ),
            ),
            Chip(
              label: Text('My Tier $userTier'),
              backgroundColor: tokens.colors.primary.withValues(alpha: 0.16),
              side: BorderSide(color: tokens.colors.primary.withValues(alpha: 0.4)),
              labelStyle: textTheme.labelMedium?.copyWith(
                color: tokens.colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.push(RouteNames.myTournaments),
            icon: Icon(Icons.list_alt_rounded, color: tokens.colors.accent),
            label: Text(
              'My Tournaments (${joinedIds.length})',
              style: textTheme.labelLarge?.copyWith(
                color: tokens.colors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.md),
        for (final room in rooms)
          _roomCard(
            room: room,
            userTier: userTier,
            joined: joinedIds.contains(room.id),
            signedIn: authUser != null,
            extraEntryTickets: extraEntryTickets,
            configLoading: configAsync.isLoading,
            config: configAsync.asData?.value,
            freeTickets: freeTickets,
          ),
        if (rooms.isEmpty)
          SrcSurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'No tournament rooms yet',
                style: textTheme.titleSmall?.copyWith(color: tokens.colors.ink),
              ),
              subtitle: Text(
                'Seed Firestore tournaments to populate this list.',
                style: textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
              ),
            ),
          ),
      ],
    );
  }

  Widget _roomCard({
    required TournamentModel room,
    required int userTier,
    required bool joined,
    required bool signedIn,
    required int extraEntryTickets,
    required bool configLoading,
    required CompanyTournamentConfig? config,
    required int freeTickets,
  }) {
    final quote = resolvePrizeRaceQuote(
      tournament: room,
      configLoading: configLoading,
      config: config,
    );
    final ready = quote == null || quote.ready;
    return _TournamentRoomCard(
      key: _cardKeys.putIfAbsent(room.id, GlobalKey.new),
      room: room,
      userTier: userTier,
      highlighted: room.id == widget.initialTournamentId,
      isJoined: joined,
      canJoin: TournamentJoinGate.canAttemptJoin(
        signedIn: signedIn,
        alreadyJoined: joined,
        tournament: room,
        userTier: userTier,
        extraEntryTickets: extraEntryTickets,
      ),
      quote: quote,
      freeTickets: freeTickets,
      prizeReady: ready,
      showTicketJoin: quote?.canUseTickets(freeTickets) ?? false,
      tierTicketJoinLabel: quote?.tierTicketJoinLabel,
      onJoin: !signedIn
          ? null
          : () => joinTournamentWithPreflight(
                context: context,
                ref: ref,
                tournament: room,
                prizeEntryShare: quote != null && quote.ready ? quote.entryShare : null,
                prizeTicketCost: quote?.ticketCost ?? 0,
                freeTicketBalance: freeTickets,
              ),
      onTicketJoin: !signedIn || !(quote?.canUseTickets(freeTickets) ?? false)
          ? null
          : () => joinTournamentWithPreflight(
                context: context,
                ref: ref,
                tournament: room,
                entryMethod: 'ticket',
                prizeEntryShare: quote!.entryShare,
                prizeTicketCost: quote.ticketCost,
                freeTicketBalance: freeTickets,
              ),
      onTierTicketJoin: !signedIn || quote?.tierTicketJoinLabel == null
          ? null
          : () => joinTournamentWithPreflight(
                context: context,
                ref: ref,
                tournament: room,
                entryMethod: 'tier_ticket',
                prizeEntryShare: quote!.entryShare,
              ),
      onSponsor: () => context.push(
        RouteNames.sponsorPayment,
        extra: SponsorPaymentArgs(
          tournamentId: room.id,
          tournamentTitle: room.title,
        ),
      ),
    );
  }
}

class _TournamentRoomCard extends StatelessWidget {
  const _TournamentRoomCard({
    required this.room,
    required this.userTier,
    required this.highlighted,
    required this.isJoined,
    required this.canJoin,
    required this.onJoin,
    required this.onSponsor,
    this.quote,
    this.onTicketJoin,
    this.onTierTicketJoin,
    this.freeTickets = 0,
    this.prizeReady = true,
    this.showTicketJoin = false,
    this.tierTicketJoinLabel,
    super.key,
  });

  final TournamentModel room;
  final int userTier;
  final bool highlighted;
  final bool isJoined;
  final bool canJoin;
  final VoidCallback? onJoin;
  final VoidCallback? onTicketJoin;
  final VoidCallback? onTierTicketJoin;
  final VoidCallback onSponsor;
  final PrizeRaceQuote? quote;
  final int freeTickets;
  final bool prizeReady;
  final bool showTicketJoin;
  final String? tierTicketJoinLabel;

  @override
  Widget build(BuildContext context) {
    final locked = room.lockedForTier(userTier);
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    return SrcSurfaceCard(
      margin: EdgeInsets.only(bottom: tokens.spacing.sm),
      padding: EdgeInsets.all(tokens.spacing.md),
      borderColor: highlighted
          ? tokens.colors.primary
          : tokens.colors.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: locked ? tokens.colors.muted : tokens.colors.primary,
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: Text(
                  room.title,
                  style: textTheme.titleLarge?.copyWith(
                    color: tokens.colors.ink,
                  ),
                ),
              ),
              Text(
                'Tier ${room.requiredTier}',
                style: textTheme.labelMedium?.copyWith(
                  color: tokens.colors.muted,
                ),
              ),
              if (isJoined) ...[
                SizedBox(width: tokens.spacing.xs),
                Chip(
                  label: const Text('Joined'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: tokens.colors.accent.withValues(alpha: 0.14),
                  side: BorderSide(
                    color: tokens.colors.accent.withValues(alpha: 0.4),
                  ),
                  labelStyle: textTheme.labelSmall?.copyWith(
                    color: tokens.colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: tokens.spacing.sm),
          Text(
            'Sponsor: ${room.sponsorName}',
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.colors.donation,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spacing.xxs + 2),
          Text(
            quote == null
                ? '${room.targetDistanceKm.toStringAsFixed(1)}km / '
                    '${room.entryFeeShare} Share entry / '
                    '${room.recruitmentSummary}'
                : '${room.targetDistanceKm.toStringAsFixed(1)}km / '
                    '${quote!.costLabel(freeTickets)} / '
                    '${room.recruitmentSummary}',
            style: textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            quote?.costLabel(freeTickets) ?? '${room.entryFeeShare} SHARE',
            style: textTheme.labelMedium?.copyWith(
              color: tokens.colors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (quote?.rulesLabel != null) ...[
            SizedBox(height: tokens.spacing.xxs),
            Text(
              quote!.rulesLabel!,
              style: textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
            ),
          ],
          SizedBox(height: tokens.spacing.xxs),
          Text(
            AppStrings.winnerRewardNoConversion,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.colors.donation,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            room.cashPrizePoolLabel ?? AppStrings.noCashPrizePool,
            style: textTheme.bodySmall?.copyWith(
              color: tokens.colors.donation,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canJoin && prizeReady ? onJoin : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.colors.primary,
                    foregroundColor: tokens.colors.onPrimary,
                    disabledBackgroundColor: tokens.colors.outline,
                    disabledForegroundColor: tokens.colors.muted,
                  ),
                  icon: Icon(locked ? Icons.lock_rounded : Icons.login_rounded),
                  label: Text(
                    locked
                        ? 'Lower-tier room locked'
                        : isJoined
                            ? 'Already joined'
                            : canJoin && (room.isFull || !room.isRecruiting)
                                ? '추가 참가권으로 참가'
                                : room.isFull
                                    ? 'Room full'
                                    : !room.isRecruiting
                                        ? 'Not recruiting'
                                        : quote != null
                                            ? quote!.shareJoinLabel
                                            : 'Join with Share',
                  ),
                ),
              ),
              SizedBox(width: tokens.spacing.sm),
              IconButton.filledTonal(
                onPressed: onSponsor,
                icon: Icon(
                  Icons.campaign_rounded,
                  color: tokens.colors.donation,
                ),
                tooltip: 'Sponsor this tournament',
                style: IconButton.styleFrom(
                  backgroundColor: tokens.colors.donation.withValues(alpha: 0.16),
                ),
              ),
            ],
          ),
          if (showTicketJoin && !isJoined && !locked) ...[
            SizedBox(height: tokens.spacing.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTicketJoin,
                icon: const Icon(Icons.confirmation_number_outlined),
                label: Text(quote?.ticketJoinLabel ?? '무료 참가권으로 참가'),
              ),
            ),
          ],
          if (tierTicketJoinLabel != null && !isJoined && !locked) ...[
            SizedBox(height: tokens.spacing.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTierTicketJoin,
                icon: const Icon(Icons.confirmation_number_outlined),
                label: Text(tierTicketJoinLabel!),
              ),
            ),
          ],
          SizedBox(height: tokens.spacing.xs),
          Text(
            'Sponsor options: direct fixed prize support or UNICEF donation.',
            style: textTheme.bodySmall?.copyWith(
              color: tokens.colors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
