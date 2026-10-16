import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/router/route_names.dart';
import '../core/challenge/challenge_entry_fee.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../features/shop/widgets/store_look.dart';
import '../data/models/tournament_model.dart';
import '../features/challenge/providers/challenge_room_providers.dart';
import '../features/pedometer/walking_challenge_share.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/shop/widgets/server_item_use_button.dart';
import '../features/tournaments/utils/tournament_join_flow.dart';
import 'live_running_screen.dart';

/// 대회방 상세정보 및 기부처 선택 화면 (Screen 9).
class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({super.key, this.roomId});

  /// Differentiates beginner 1km vs intermediate 3km room content.
  final String? roomId;

  Future<void> _onShare(BuildContext buttonContext, String roomTitle) async {
    final title = roomTitle.trim();
    if (title.isEmpty) return;
    try {
      await WalkingChallengeShare.openSystemSheet(
        text: '쉐어런 $title 방에 같이 도전해요!\n#쉐어런 #ShareRun',
        subject: '쉐어런 챌린지 초대',
        sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
      );
    } catch (e, st) {
      debugPrint('WalkingChallengeShare.room: $e\n$st');
    }
  }

  void _onDonationTap() {
    debugPrint('버튼 클릭됨');
  }

  @override
  Widget build(BuildContext context) {
    final copy = _ChallengeDetailCopy.forRoom(roomId);

    final c = context.srcTokens.colors;
    String after(String text) {
      final i = text.indexOf(':');
      return i < 0 ? text : text.substring(i + 1).trim();
    }

    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: storeText(22, c.ink, w: FontWeight.w900, h: 1.05),
                  ),
                ),
                const SizedBox(height: 4),
                StoreTag(label),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/challenge_track.jpg',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, 0.4),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.88),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  key: const Key('challenge-detail-back'),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.16),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                Builder(
                                  builder: (buttonContext) => IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.16),
                                    ),
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => unawaited(
                                      _onShare(buttonContext, copy.title),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 22,
                          right: 22,
                          bottom: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StoreTag(
                                'ROOM · ${copy.badge.toUpperCase()}',
                                color: c.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                copy.title,
                                style: storeText(
                                  30,
                                  Colors.white,
                                  w: FontWeight.w900,
                                  h: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                copy.entryFee,
                                style: storeText(14, Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          stat(after(copy.distance), 'DISTANCE'),
                          const SizedBox(width: 10),
                          stat(after(copy.timeRemaining), 'TIME LEFT'),
                          const SizedBox(width: 10),
                          stat(after(copy.recruitment), 'RECRUIT'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _HighlightBox(
                        prize: copy.prize,
                        donation: copy.donation,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: _HeroImageSection(
                          badge: copy.badge,
                          radiusMeters: copy.radiusMeters,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _onDonationTap,
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: c.outline),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  copy.donationTarget,
                                  style: storeText(
                                    14,
                                    c.ink,
                                    w: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: c.muted,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              copy.valueTip,
                              style: storeText(
                                12,
                                c.primary,
                                w: FontWeight.w600,
                                h: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ServerItemUseButton(
                    itemId: ServerShopInventory.cprId,
                    label: AppStrings.challengeDetailCprUse,
                    emptyHint: AppStrings.challengeDetailCprBuyHint,
                    maxUses: AppStrings.challengeDetailCprMaxPerRace,
                    alignment: Alignment.centerRight,
                  ),
                  const SizedBox(height: 8),
                  _ChallengeJoinPayButton(
                    key: ValueKey<String>('join-${roomId ?? 'default'}'),
                    roomId: roomId,
                    joinLabel: copy.joinLabel,
                    title: copy.title,
                    entryFeeShare: copy.entryFeeShare,
                    targetDistanceKm: copy.radiusMeters / 1000,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeDetailCopy {
  const _ChallengeDetailCopy({
    required this.title,
    required this.entryFee,
    required this.badge,
    required this.prize,
    required this.donation,
    required this.distance,
    required this.timeRemaining,
    required this.recruitment,
    required this.donationTarget,
    required this.valueTip,
    required this.joinLabel,
    required this.radiusMeters,
    required this.entryFeeShare,
  });

  final String title;
  final String entryFee;
  final String badge;
  final String prize;
  final String donation;
  final String distance;
  final String timeRemaining;
  final String recruitment;
  final String donationTarget;
  final String valueTip;
  final String joinLabel;
  final double radiusMeters;
  final int entryFeeShare;

  static const _beginnerRoomIds = <String>{
    RouteNames.beginner1kmRoomId,
    'beginner-1km-room-01',
  };

  factory _ChallengeDetailCopy.forRoom(String? roomId) {
    final isBeginner = roomId != null && _beginnerRoomIds.contains(roomId);
    if (isBeginner) {
      const fee = ChallengeEntryFee.beginner1kmShare;
      return const _ChallengeDetailCopy(
        title: '1km 초보 챌린지',
        entryFee: AppStrings.dashboardChallenge1Sub,
        badge: '입문',
        prize: AppStrings.challengeDetailPrize,
        donation: AppStrings.challengeDetailDonation,
        distance: '거리: 1km',
        timeRemaining: AppStrings.challengeDetailTimeRemaining,
        recruitment: '모집 인원: 120 / 200명',
        donationTarget: AppStrings.challengeDetailDonationTarget,
        valueTip: AppStrings.challengeDetailValueTip,
        joinLabel: AppStrings.challengeDetailJoin,
        radiusMeters: 1000,
        entryFeeShare: fee,
      );
    }

    // Default / intermediate-3km-room → 중급 3km (longer = higher fee).
    const fee = ChallengeEntryFee.intermediate3kmShare;
    return const _ChallengeDetailCopy(
      title: AppStrings.challengeDetailTitle,
      entryFee: AppStrings.challengeDetailEntryFee,
      badge: AppStrings.challengeDetailGoldBadge,
      prize: AppStrings.challengeDetailPrize,
      donation: AppStrings.challengeDetailDonation,
      distance: AppStrings.challengeDetailDistance,
      timeRemaining: AppStrings.challengeDetailTimeRemaining,
      recruitment: AppStrings.challengeDetailRecruitment,
      donationTarget: AppStrings.challengeDetailDonationTarget,
      valueTip: AppStrings.challengeDetailValueTip,
      joinLabel: AppStrings.challengeDetailJoin,
      radiusMeters: 3000,
      entryFeeShare: fee,
    );
  }
}

class _ChallengeJoinPayButton extends ConsumerStatefulWidget {
  const _ChallengeJoinPayButton({
    super.key,
    required this.roomId,
    required this.joinLabel,
    required this.title,
    required this.entryFeeShare,
    required this.targetDistanceKm,
  });

  final String? roomId;
  final String joinLabel;
  final String title;
  final int entryFeeShare;
  final double targetDistanceKm;

  @override
  ConsumerState<_ChallengeJoinPayButton> createState() =>
      _ChallengeJoinPayButtonState();
}

class _ChallengeJoinPayButtonState
    extends ConsumerState<_ChallengeJoinPayButton> {
  var _busy = false;

  TournamentModel _resolveRoom() {
    final id = widget.roomId;
    if (id != null && id.isNotEmpty) {
      final rooms = ref.read(tournamentListProvider).asData?.value;
      if (rooms != null) {
        for (final room in rooms) {
          if (room.id == id) return room;
        }
      }
    }
    return TournamentModel(
      id: (id != null && id.isNotEmpty) ? id : 'demo-intermediate-3km',
      title: widget.title,
      targetDistanceKm: widget.targetDistanceKm,
      entryFeeShare: widget.entryFeeShare,
      winnerRewardValue: 0,
      donationValue: 0,
      minParticipantsBep: 10,
      maxParticipants: 200,
      participantCount: 1,
      requiredTier: 1,
      status: TournamentStatus.recruiting,
      sponsorName: 'UNICEF',
    );
  }

  Future<void> _onJoin() async {
    if (_busy) return;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final joined = await joinTournamentWithPreflight(
        context: context,
        ref: ref,
        tournament: _resolveRoom(),
      );
      if (!joined) return;
      await navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LiveRunningScreen(roomId: widget.roomId),
        ),
      );
    } catch (e, st) {
      debugPrint('[JOIN] button: $e\n$st');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryMint,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _onJoin,
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: Center(
            child: Text(
              widget.joinLabel,
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.nightOnLime,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImageSection extends StatefulWidget {
  const _HeroImageSection({
    required this.badge,
    required this.radiusMeters,
  });

  final String badge;
  final double radiusMeters;

  @override
  State<_HeroImageSection> createState() => _HeroImageSectionState();
}

class _HeroImageSectionState extends State<_HeroImageSection> {
  static const _fallbackTarget = LatLng(37.5665, 126.9780);

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng _center = _fallbackTarget;

  @override
  void initState() {
    super.initState();
    Future.microtask(_startPositionStream);
  }

  Future<void> _startPositionStream() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (!mounted) return;
        final target = LatLng(position.latitude, position.longitude);
        setState(() => _center = target);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, _mapZoom),
        );
      });
    } catch (_) {
      // Keep fallback center — do not crash the screen.
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _mapController = null;
    super.dispose();
  }

  /// Zoom so the full radius ring stays visible (3km needs a wider view).
  double get _mapZoom => widget.radiusMeters >= 3000 ? 12.0 : 14.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: _mapZoom,
              ),
              circles: <Circle>{
                Circle(
                  circleId: CircleId(
                    'room_radius_${widget.radiusMeters.toInt()}m',
                  ),
                  center: _center,
                  radius: widget.radiusMeters,
                  fillColor: AppColors.primaryMint.withValues(alpha: 0.18),
                  strokeColor: AppColors.primaryMint.withValues(alpha: 0.85),
                  strokeWidth: 1,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(PanGestureRecognizer.new),
                Factory<ScaleGestureRecognizer>(ScaleGestureRecognizer.new),
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.progressYellow,
                  Color(0xFFFFA726),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textBlack.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.badge,
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.nightOnLime,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({
    required this.prize,
    required this.donation,
  });

  final String prize;
  final String donation;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2310), Color(0xFF14110A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StoreTag('PRIZE & DONATION', color: Color(0xFFE8B84B)),
          const SizedBox(height: 8),
          Text(prize, style: storeText(15, c.ink, w: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  donation,
                  style: storeText(15, c.ink, w: FontWeight.w800),
                ),
              ),
              Icon(Icons.info_outline_rounded, size: 16, color: c.muted),
            ],
          ),
        ],
      ),
    );
  }
}
