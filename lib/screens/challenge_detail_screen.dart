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
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../data/models/tournament_model.dart';
import '../features/challenge/providers/challenge_room_providers.dart';
import '../features/tournaments/utils/tournament_join_flow.dart';
import 'live_running_screen.dart';

/// 대회방 상세정보 및 기부처 선택 화면 (Screen 9).
class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({super.key, this.roomId});

  /// Differentiates beginner 1km vs intermediate 3km room content.
  final String? roomId;

  void _onShare() {
    debugPrint('버튼 클릭됨');
  }

  void _onDonationTap() {
    debugPrint('버튼 클릭됨');
  }

  @override
  Widget build(BuildContext context) {
    final copy = _ChallengeDetailCopy.forRoom(roomId);

    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.textBlack,
                      iconSize: 22,
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.textBlack,
                      iconSize: 24,
                      onPressed: _onShare,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    0,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroImageSection(
                        badge: copy.badge,
                        radiusMeters: copy.radiusMeters,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        copy.title,
                        style: AppTextStyles.header1.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.entryFee,
                        style: AppTextStyles.agreementLabel.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _HighlightBox(
                        prize: copy.prize,
                        donation: copy.donation,
                      ),
                      const SizedBox(height: 20),
                      _DetailRow(
                        icon: Icons.flag_outlined,
                        text: copy.distance,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        text: copy.timeRemaining,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.people_outline_rounded,
                        text: copy.recruitment,
                      ),
                      const SizedBox(height: 20),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _onDonationTap,
                          borderRadius: BorderRadius.circular(
                            AppShapes.inputRadius,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderLight),
                              borderRadius: BorderRadius.circular(
                                AppShapes.inputRadius,
                              ),
                              color: AppColors.surfaceWhite,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    copy.donationTarget,
                                    style: AppTextStyles.inputText.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textGrey,
                                  size: 22,
                                ),
                              ],
                            ),
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
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                color: AppColors.primaryMint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    4,
                    AppShapes.termsHorizontalPadding,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          copy.cprTickets,
                          style: AppTextStyles.caption.copyWith(fontSize: 12),
                        ),
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
        ),
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
    required this.cprTickets,
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
  final String cprTickets;
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
        badge: 'Beginner',
        prize: '상금: 3만 원',
        donation: '기부금: 유니세프 기부 3만 원',
        distance: '거리: 1km',
        timeRemaining: AppStrings.challengeDetailTimeRemaining,
        recruitment: '모집 인원: 120 / 200명 (최소 BEP: 100명)',
        donationTarget: AppStrings.challengeDetailDonationTarget,
        valueTip: AppStrings.challengeDetailValueTip,
        cprTickets: AppStrings.challengeDetailCprTickets,
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
      cprTickets: AppStrings.challengeDetailCprTickets,
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
      winnerRewardValue: (widget.entryFeeShare * 0.4).round(),
      donationValue: (widget.entryFeeShare * 0.2).round(),
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
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _onJoin,
        child: SizedBox(
          width: double.infinity,
          height: AppShapes.buttonHeight,
          child: Center(
            child: Text(
              widget.joinLabel,
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textWhite,
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
                color: AppColors.textWhite,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.agreementBoxFill,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prize,
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  donation,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textGrey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.agreementLabel.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
