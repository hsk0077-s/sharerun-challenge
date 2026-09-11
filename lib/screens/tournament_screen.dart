import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
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

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.electricBlue, AppColors.neonLime],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Text(
            'Sponsor Boost: Every verified sweat drop funds real impact.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tournament Rooms',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Chip(label: Text('My Tier $userTier')),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.push(RouteNames.myTournaments),
            icon: const Icon(Icons.list_alt_rounded),
            label: Text('My Tournaments (${joinedIds.length})'),
          ),
        ),
        const SizedBox(height: 16),
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
          const Card(
            child: ListTile(
              title: Text('No tournament rooms yet'),
              subtitle: Text('Seed Firestore tournaments to populate this list.'),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlighted
            ? const BorderSide(color: AppColors.neonLime, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: locked ? AppColors.textSecondary : AppColors.neonLime,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    room.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('Tier ${room.requiredTier}'),
                if (isJoined)
                  const Chip(
                    label: Text('Joined'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Sponsor: ${room.sponsorName}'),
            const SizedBox(height: 6),
            Text(
              '${room.targetDistanceKm.toStringAsFixed(1)}km / '
              '${room.entryFeeShare} Share entry / '
              '${room.recruitmentSummary}',
            ),
            const SizedBox(height: 8),
            Text(
              '과금 없이 목표 달성 시: +${room.winnerRewardValue} 밸류 지급',
              style: const TextStyle(
                color: AppColors.neonLime,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Donation pool: ${room.donationValue} Value',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canJoin ? onJoin : null,
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
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: onSponsor,
                  icon: const Icon(Icons.campaign_rounded),
                  tooltip: 'Sponsor this tournament',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sponsor options: direct fixed prize support or UNICEF donation.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
