import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/strings/app_strings.dart';
import '../l10n/remaining_surface.dart';
import '../l10n/surface_rest.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../core/theme/theme.dart';
import '../features/shop/widgets/store_look.dart';
import '../data/models/company_tournament_config.dart';
import '../data/models/tournament_model.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/tournaments/providers/company_tournament_providers.dart';
import '../features/tournaments/providers/local_joined_ids_provider.dart';
import '../features/tournaments/utils/prize_display.dart';
import '../features/tournaments/utils/sponsor_display.dart';
import '../features/tournaments/utils/prize_race_entry.dart';
import '../features/tournaments/utils/tournament_join_flow.dart';
import '../features/tournaments/utils/tournament_join_gate.dart';
import 'sponsor_payment_screen.dart';
import '../core/config/app_env.dart';

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
    final c = context.srcTokens.colors;
    final myTier = ref.watch(activeUserTierStructProvider);
    final myAnimal = myTier == null || myTier.isSnail ? null : myTier.animal;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Row(
          children: [
            const StoreTag('TOURNAMENT'),
            const Spacer(),
            Text(
              RemainingSurface.tr(
                context,
                'tournament.body',
                '내 티어 $userTier',
                {'userTier': userTier},
              ),
              style: storeText(13, c.primary, w: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          RemainingSurface.tr(
            context,
            'tournament.body.2',
            '검증된 달리기 1km마다 100원이 기부돼요.',
          ),
          style: storeText(14, c.donation, w: FontWeight.w700, h: 1.4),
        ),
        const SizedBox(height: 4),
        Text(
          RemainingSurface.tr(
            context,
            'tournament.body.3',
            '회사(운영자) 자금으로 기부할 예정이며 월 한도가 있어요. 기부처는 협의 중이고 정해지면 알려 드려요.',
          ),
          style: storeText(12, c.muted, h: 1.4),
        ),
        const SizedBox(height: 6),
        _MyTournamentsLine(
          count: joinedIds.length,
          onTap: () {
            final tabs = DefaultTabController.maybeOf(context);
            if (tabs != null) {
              tabs.animateTo(2);
            } else {
              context.push(RouteNames.myTournaments);
            }
          },
        ),
        ..._sections(
          rooms: rooms,
          myAnimal: myAnimal,
          card: (room) => _roomCard(
            room: room,
            userTier: userTier,
            joined: joinedIds.contains(room.id),
            signedIn: authUser != null,
            extraEntryTickets: extraEntryTickets,
            configLoading: configAsync.isLoading,
            config: configAsync.asData?.value,
            freeTickets: freeTickets,
          ),
        ),
        if (rooms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Text(
                  RemainingSurface.tr(
                    context,
                    'tournament.body.4',
                    '아직 열린 대회가 없어요',
                  ),
                  style: storeText(16, c.ink, w: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  RemainingSurface.tr(
                    context,
                    'tournament.body.5',
                    '새 대회가 열리면 여기에 나타나요.',
                  ),
                  style: storeText(13, c.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 대회를 "티어 대회 / 자유 대회 / 그 밖의 대회" 세 구역으로 나눠 보여 준다.
  /// 내 등급과 같은 티어 대회가 맨 위에 온다. 비어 있는 구역은 보이지 않는다.
  List<Widget> _sections({
    required List<TournamentModel> rooms,
    required TierAnimal? myAnimal,
    required Widget Function(TournamentModel room) card,
  }) {
    final groups = TournamentSections.group(rooms, myAnimal);
    final shown = [
      groups.tier.isNotEmpty,
      groups.free.isNotEmpty,
      groups.other.isNotEmpty,
    ].where((v) => v).length;
    return [
      if (groups.tier.isNotEmpty) ...[
        _SectionHeader(
          title: RemainingSurface.tr(context, 'tournament.body.6', '티어 대회'),
          note: myAnimal == null
              ? RemainingSurface.tr(
                  context,
                  'tournament.body.7',
                  '등급을 받으면 참가할 수 있어요',
                )
              : myGradeLabel(
                  Localizations.localeOf(context),
                  animalLabel(Localizations.localeOf(context), myAnimal.code),
                ),
        ),
        for (final room in groups.tier) card(room),
      ],
      if (groups.free.isNotEmpty) ...[
        _SectionHeader(
          title: RemainingSurface.tr(context, 'tournament.body.8', '자유 대회'),
          note: RemainingSurface.tr(
            context,
            'tournament.body.9',
            '누구나 참가 · 승급 점수 절반',
          ),
        ),
        for (final room in groups.free) card(room),
      ],
      if (groups.other.isNotEmpty) ...[
        _SectionHeader(
          title: shown > 1
              ? RemainingSurface.tr(context, 'tournament.body.10', '그 밖의 대회')
              : '대회',
        ),
        for (final room in groups.other) card(room),
      ],
    ];
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
      prizeLine: prizePoolLine(
        room: room,
        configLoading: configLoading,
        config: config,
      ),
      prizeReady: ready,
      showTicketJoin: quote?.canUseTickets(freeTickets) ?? false,
      tierTicketJoinLabel: quote?.tierTicketJoinLabel,
      onJoin: !signedIn
          ? null
          : () => joinTournamentWithPreflight(
                context: context,
                ref: ref,
                tournament: room,
                prizeEntryShare:
                    quote != null && quote.ready ? quote.entryShare : null,
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
  _TournamentRoomCard({
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
    String? prizeLine,
    this.prizeReady = true,
    this.showTicketJoin = false,
    this.tierTicketJoinLabel,
    super.key,
  }) : prizeLine = prizeLine ?? AppStrings.noCashPrizePool;

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
  final String prizeLine;
  final bool prizeReady;
  final bool showTicketJoin;
  final String? tierTicketJoinLabel;

  @override
  Widget build(BuildContext context) {
    final locked = room.lockedForTier(userTier);
    final c = context.srcTokens.colors;
    final feeText =
        quote?.costLabel(freeTickets) ?? '${room.entryFeeShare} SHARE';
    final joinLabel = locked
        ? RemainingSurface.tr(
            context,
            'tournament.body.11',
            '낮은 등급 대회는 참가할 수 없어요',
          )
        : isJoined
            ? RemainingSurface.tr(context, 'tournament.body.12', '이미 참가했어요')
            : canJoin && (room.isFull || !room.isRecruiting)
                ? '추가 참가권으로 참가'
                : room.isFull
                    ? '정원이 가득 찼어요'
                    : !room.isRecruiting
                        ? RemainingSurface.tr(
                            context,
                            'tournament.body.13',
                            '모집이 끝났어요',
                          )
                        : quote != null
                            ? quote!.shareJoinLabel
                            : '${room.entryFeeShare} SHARE로 참가';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? c.primary : c.outline,
          width: highlighted ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StoreTag(
                'TIER ${room.requiredTier}',
                color: locked ? c.muted : c.primary,
              ),
              const Spacer(),
              if (isJoined)
                Text('참가 중',
                    style: storeText(13, c.primary, w: FontWeight.w900)),
              if (locked)
                Icon(Icons.lock_outline_rounded, size: 16, color: c.muted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            room.title,
            style: storeText(
              24,
              locked ? c.muted : c.ink,
              w: FontWeight.w900,
              h: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            RemainingSurface.tr(
              context,
              'tournament.body.14',
              '후원  ${displaySponsorName(room.sponsorName)}',
              {
                'displaySponsorName(room.sponsorName)':
                    displaySponsorName(room.sponsorName),
              },
            ),
            style: storeText(13, c.donation, w: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoomStat(
                value: '${room.targetDistanceKm.toStringAsFixed(1)}km',
                label: RemainingSurface.tr(context, 'tournament.body.15', '목표 거리'),
              ),
              const SizedBox(width: 8),
              _RoomStat(
                value: feeText,
                label: RemainingSurface.tr(context, 'tournament.body.16', '참가비'),
                highlight: true,
              ),
              const SizedBox(width: 8),
              _RoomStat(
                value: room.recruitmentSummary,
                label: RemainingSurface.tr(context, 'tournament.body.17', '모집'),
              ),
            ],
          ),
          if (quote?.rulesLabel != null) ...[
            const SizedBox(height: 10),
            Text(quote!.rulesLabel!, style: storeText(12, c.muted, h: 1.4)),
          ],
          const SizedBox(height: 12),
          Text(
            AppStrings.winnerRewardNoConversion,
            style: storeText(13, c.donation, w: FontWeight.w800, h: 1.4),
          ),
          const SizedBox(height: 2),
          Text(prizeLine, style: storeText(12, c.donation, h: 1.4)),
          const SizedBox(height: 16),
          StorePillButton(
            label: joinLabel,
            icon: locked ? Icons.lock_rounded : null,
            onPressed: canJoin && prizeReady ? onJoin : null,
          ),
          if (showTicketJoin && !isJoined && !locked)
            _RoomLinkLine(
              label: quote?.ticketJoinLabel ??
                  RemainingSurface.tr(context, 'tournament.button', '무료 참가권으로 참가'),
              onTap: onTicketJoin,
            ),
          if (tierTicketJoinLabel != null && !isJoined && !locked)
            _RoomLinkLine(label: tierTicketJoinLabel!, onTap: onTierTicketJoin),
          if (AppEnv.sponsorPaymentsVisible)
            _RoomLinkLine(
              label: RemainingSurface.tr(context, 'tournament.body.18', '이 대회 후원하기'),
              icon: Icons.campaign_rounded,
              onTap: onSponsor,
            ),
        ],
      ),
    );
  }
}

class _RoomStat extends StatelessWidget {
  const _RoomStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        decoration: BoxDecoration(
          color: c.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: storeText(
                14,
                highlight ? c.primary : c.ink,
                w: FontWeight.w900,
                h: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: storeText(11, c.muted)),
          ],
        ),
      ),
    );
  }
}

/// 카드 아래의 한 줄 링크. 아래 선 없이 글자와 화살표만.
class _RoomLinkLine extends StatelessWidget {
  const _RoomLinkLine({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Icon(icon ?? Icons.confirmation_number_outlined,
                size: 18, color: c.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: storeText(13, c.muted, h: 1.35)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _MyTournamentsLine extends StatelessWidget {
  const _MyTournamentsLine({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.outline)),
        ),
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 20, color: c.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                RemainingSurface.tr(
                  context,
                  'tournament.body.19',
                  '내 대회 ($count)',
                  {'count': count},
                ),
                style: storeText(16, c.ink, w: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

/// 구역 제목. 오른쪽에 짧은 설명이 붙을 수 있다.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: storeText(15, c.ink, w: FontWeight.w900)),
          if (note != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: storeText(12, c.muted, w: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 대회 목록을 구역으로 나누는 순수 함수. 시험하기 쉽게 따로 뒀다.
abstract final class TournamentSections {
  static ({
    List<TournamentModel> tier,
    List<TournamentModel> free,
    List<TournamentModel> other,
  }) group(List<TournamentModel> rooms, TierAnimal? myAnimal) {
    final mine = myAnimal == null ? 0 : myAnimal.index + 1;
    final tier = rooms.where((r) => r.isTierTournament).toList()
      ..sort((a, b) {
        // 내 등급 대회가 먼저, 그다음 낮은 등급 순.
        int rank(TournamentModel r) => r.tierAnimal == mine ? 0 : r.tierAnimal;
        return rank(a).compareTo(rank(b));
      });
    return (
      tier: tier,
      free: rooms.where((r) => r.isFreeTournament).toList(),
      other: rooms
          .where((r) => !r.isTierTournament && !r.isFreeTournament)
          .toList(),
    );
  }
}
