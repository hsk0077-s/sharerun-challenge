import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/theme/theme.dart';
import '../data/models/tournament_model.dart';
import '../features/tournaments/providers/local_joined_ids_provider.dart';
import '../features/tournaments/utils/tournament_join_flow.dart';
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
          _TournamentRoomCard(
            key: _cardKeys.putIfAbsent(room.id, GlobalKey.new),
            room: room,
            userTier: userTier,
            highlighted: room.id == widget.initialTournamentId,
            isJoined: joinedIds.contains(room.id),
            canJoin: authUser != null &&
                room.isRecruiting &&
                !room.lockedForTier(userTier) &&
                !room.isFull &&
                !joinedIds.contains(room.id),
            onJoin: authUser == null
                ? null
                : () => joinTournamentWithPreflight(
                      context: context,
                      ref: ref,
                      tournament: room,
                    ),
            onSponsor: () => context.push(
              RouteNames.sponsorPayment,
              extra: SponsorPaymentArgs(
                tournamentId: room.id,
                tournamentTitle: room.title,
              ),
            ),
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
    super.key,
  });

  final TournamentModel room;
  final int userTier;
  final bool highlighted;
  final bool isJoined;
  final bool canJoin;
  final VoidCallback? onJoin;
  final VoidCallback onSponsor;

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
            '${room.targetDistanceKm.toStringAsFixed(1)}km / '
            '${room.entryFeeShare} Share entry / '
            '${room.recruitmentSummary}',
            style: textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            '${room.entryFeeShare} SHARE',
            style: textTheme.labelMedium?.copyWith(
              color: tokens.colors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spacing.xxs),
          Text(
            '과금 없이 목표 달성 시: +${room.winnerRewardValue} 밸류 지급',
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.colors.donation,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Donation pool: ${room.donationValue} Value',
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
                  onPressed: canJoin ? onJoin : null,
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
                            : room.isFull
                                ? 'Room full'
                                : room.isRecruiting
                                    ? 'Join with Share'
                                    : 'Not recruiting',
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
