import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/home/providers/home_provider.dart';
import '../features/stamp/providers/stamp_tour_provider.dart';

/// 스탬프 투어 & 일일 미션 화면 (Screen 23).
class StampTourScreen extends ConsumerStatefulWidget {
  const StampTourScreen({super.key});

  @override
  ConsumerState<StampTourScreen> createState() => _StampTourScreenState();
}

class _StampTourScreenState extends ConsumerState<StampTourScreen> {
  static const _currentNavIndex = DashboardTabNavigation.home;

  static const _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Colors.white],
  );

  static const _cardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const _completedMint = Color(0xFF00C853);
  static const _inProgressGrey = Color(0xFFBDBDBD);

  GoogleMapController? _mapController;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      Navigator.pop(context);
      return;
    }
    DashboardTabNavigation.go(context, index);
  }

  Future<void> _onWalkMissionTap() async {
    final message =
        await ref.read(stampTourProvider.notifier).tryClaimWalkMission();
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onStampMissionTap() async {
    final message =
        await ref.read(stampTourProvider.notifier).tryClaimStampMission();
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Set<Marker> _buildMarkers(List<StampLandmark> landmarks) {
    return landmarks.map((landmark) {
      return Marker(
        markerId: MarkerId(landmark.id),
        position: LatLng(landmark.latitude, landmark.longitude),
        infoWindow: InfoWindow(
          title: landmark.name,
          snippet: landmark.isVisited
              ? AppStrings.stampTourVisitComplete
              : '반경 50m 이내 접근',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          landmark.isVisited
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueAzure,
        ),
      );
    }).toSet();
  }

  CameraPosition _initialCamera(StampTourState tour) {
    final pos = tour.currentPosition;
    if (pos != null) {
      return CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 14.5,
      );
    }
    final fallback = tour.landmarks.isNotEmpty
        ? tour.landmarks.first
        : const StampLandmark(
            id: 'fallback',
            name: 'Seoul',
            latitude: 37.5665,
            longitude: 126.9780,
            isVisited: false,
          );
    return CameraPosition(
      target: LatLng(fallback.latitude, fallback.longitude),
      zoom: 13.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.sizeOf(context).height * 0.35;
    final tour = ref.watch(stampTourProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final diamondBalance = profileAsync.maybeWhen(
      data: (user) => '${user.wallet.diamondBalance}',
      orElse: () => AppStrings.storeDiamondBalance,
    );

    final markers = _buildMarkers(tour.landmarks);
    final camera = _initialCamera(tour);

    // Keep camera roughly synced when first GPS fix arrives.
    ref.listen<StampTourState>(stampTourProvider, (prev, next) {
      final prevLat = prev?.currentPosition?.latitude;
      final nextPos = next.currentPosition;
      if (nextPos == null || _mapController == null) return;
      if (prevLat != null) return;
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(nextPos.latitude, nextPos.longitude),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SRCGradientBackground(
        gradient: _screenGradient,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _StampTourHeader(
                          onBack: () => Navigator.pop(context),
                          diamondBalance: diamondBalance,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _StampTourMapCard(
                          height: mapHeight,
                          cardShadow: _cardShadow,
                          markers: markers,
                          fallbackCamera: camera,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _MissionCard(
                              icon: Icons.directions_walk_rounded,
                              title: AppStrings.stampTourMissionWalk,
                              completed: tour.walkMissionCompleted,
                              inProgress: !tour.walkMissionCompleted,
                              cardShadow: _cardShadow,
                              completedMint: _completedMint,
                              inProgressGrey: _inProgressGrey,
                              onTap: tour.claiming ? null : _onWalkMissionTap,
                            ),
                            const SizedBox(height: 10),
                            _MissionCard(
                              icon: Icons.photo_camera_outlined,
                              title: tour.stampMissionTitle,
                              completed: tour.stampMissionCompleted,
                              inProgress: !tour.stampMissionCompleted,
                              cardShadow: _cardShadow,
                              completedMint: _completedMint,
                              inProgressGrey: _inProgressGrey,
                              onTap: tour.claiming ? null : _onStampMissionTap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _StampTourHeader extends StatelessWidget {
  const _StampTourHeader({
    required this.onBack,
    required this.diamondBalance,
  });

  final VoidCallback onBack;
  final String diamondBalance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textBlack,
              iconSize: 22,
              onPressed: onBack,
            ),
          ),
          Text(
            AppStrings.stampTourTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  color: Color(0xFF42A5F5),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  diamondBalance,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StampTourMapCard extends StatefulWidget {
  const _StampTourMapCard({
    required this.height,
    required this.cardShadow,
    required this.markers,
    required this.fallbackCamera,
    required this.onMapCreated,
  });

  final double height;
  final List<BoxShadow> cardShadow;
  final Set<Marker> markers;
  final CameraPosition fallbackCamera;
  final ValueChanged<GoogleMapController> onMapCreated;

  @override
  State<_StampTourMapCard> createState() => _StampTourMapCardState();
}

class _StampTourMapCardState extends State<_StampTourMapCard> {
  late LatLng _cameraTarget;

  @override
  void initState() {
    super.initState();
    _cameraTarget = widget.fallbackCamera.target;
    Future.microtask(_requestLocationAndCenter);
  }

  Future<void> _requestLocationAndCenter() async {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _cameraTarget = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Keep fallback camera target — do not crash the screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: widget.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        key: ValueKey(
          '${_cameraTarget.latitude},${_cameraTarget.longitude}',
        ),
        initialCameraPosition: CameraPosition(
          target: _cameraTarget,
          zoom: widget.fallbackCamera.zoom,
        ),
        markers: widget.markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: widget.onMapCreated,
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.icon,
    required this.title,
    required this.cardShadow,
    this.completed = false,
    this.inProgress = false,
    this.completedMint,
    this.inProgressGrey,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final List<BoxShadow> cardShadow;
  final bool completed;
  final bool inProgress;
  final Color? completedMint;
  final Color? inProgressGrey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 26, color: AppColors.textGrey),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                      height: 1.3,
                    ),
                  ),
                ),
                if (completed) ...[
                  const Icon(
                    Icons.diamond_rounded,
                    color: Color(0xFF42A5F5),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '획득 완료',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: completedMint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
                if (inProgress && !completed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: inProgressGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      AppStrings.stampTourMissionInProgress,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
