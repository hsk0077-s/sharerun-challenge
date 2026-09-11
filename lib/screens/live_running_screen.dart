import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/router/route_names.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../features/voice_coaching/voice_coaching_providers.dart';
import '../features/voice_coaching/widgets/voice_coaching_header_toggle.dart';
import 'onboarding_run_result_screen.dart';

/// 라이브 러닝 및 고스트 페이스 화면 (Screen 10).
class LiveRunningScreen extends ConsumerStatefulWidget {
  const LiveRunningScreen({super.key, this.roomId});

  /// Active room from Room Detail — selects 1km vs 3km competition context.
  final String? roomId;

  static const _background = Color(0xFF1E1E1E);
  static const _mapBackground = Color(0xFF2A2A2A);
  static const _neonPath = Color(0xFF00E5FF);

  @override
  ConsumerState<LiveRunningScreen> createState() => _LiveRunningScreenState();
}

class _LiveRunningScreenState extends ConsumerState<LiveRunningScreen> {
  static const _fallbackTarget = LatLng(37.5665, 126.9780);
  static const _beginnerRoomIds = <String>{
    RouteNames.beginner1kmRoomId,
    'beginner-1km-room-01',
  };

  bool isRunning = false;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _distanceInMeters = 0.0;
  List<LatLng> _routePoints = [];
  LatLng _cameraTarget = _fallbackTarget;
  Set<Marker> _markers = {};
  BitmapDescriptor? _meIcon;
  BitmapDescriptor? _ghostIcon;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeMarkers);
  }

  String get _roomTitle {
    if (widget.roomId != null && _beginnerRoomIds.contains(widget.roomId)) {
      return '1km 초보 챌린지방';
    }
    return AppStrings.liveRunningRoomTitle;
  }

  String get _distanceLabel =>
      '${(_distanceInMeters / 1000).toStringAsFixed(2)} km';

  String get _timeLabel {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _paceLabel {
    final km = _distanceInMeters / 1000.0;
    if (km <= 0 || _elapsedSeconds <= 0) {
      return '--:-- /km';
    }
    final minutesPerKm = (_elapsedSeconds / 60.0) / km;
    final totalSeconds = (minutesPerKm * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')} /km';
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    String text,
    Color bgColor,
  ) async {
    // Freeze bubble footprint from the current (tiny-font) layout.
    const sizingFontSize = 2.24;
    const paddingH = 17.6;
    const paddingV = 9.6;
    const cornerRadius = 22.0;
    const pinSize = 10.0;
    const preferredFontSize = 13.0;

    final sizingPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: sizingFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final pillWidth = sizingPainter.width + paddingH * 2;
    final pillHeight = sizingPainter.height + paddingV * 2;
    final width = pillWidth;
    final height = pillHeight + pinSize;

    var fontSize = preferredFontSize;
    late TextPainter textPainter;
    while (true) {
      textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: pillWidth);
      if (textPainter.width <= pillWidth &&
          textPainter.height <= pillHeight) {
        break;
      }
      fontSize *= 0.92;
      if (fontSize < 6.0) {
        break;
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, pillWidth, pillHeight),
      const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(pill, Paint()..color = bgColor);
    textPainter.paint(
      canvas,
      Offset(
        (pillWidth - textPainter.width) / 2,
        (pillHeight - textPainter.height) / 2,
      ),
    );

    final pinPath = Path()
      ..moveTo(width / 2 - pinSize, pillHeight - 1)
      ..lineTo(width / 2 + pinSize, pillHeight - 1)
      ..lineTo(width / 2, height)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = bgColor);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.ceil(), height.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  Set<Marker> _buildMarkers(LatLng me) {
    final ghost = LatLng(me.latitude + 0.002, me.longitude + 0.002);
    return {
      Marker(
        markerId: const MarkerId('me'),
        position: me,
        icon: _meIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 1.0),
      ),
      Marker(
        markerId: const MarkerId('ghost'),
        position: ghost,
        icon: _ghostIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        anchor: const Offset(0.5, 1.0),
      ),
    };
  }

  Future<void> _initializeMarkers() async {
    try {
      _meIcon ??= await _createCustomMarkerBitmap(
        '나',
        AppColors.primaryMint,
      );
      _ghostIcon ??= await _createCustomMarkerBitmap(
        '고스트',
        const Color(0xFF7E57C2),
      );
      if (!mounted) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _markers = _buildMarkers(_cameraTarget));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (!mounted) return;
        setState(() => _markers = _buildMarkers(_cameraTarget));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _cameraTarget = target;
        _markers = _buildMarkers(target);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (_) {
      if (!mounted) return;
      setState(() => _markers = _buildMarkers(_cameraTarget));
    }
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
        final previousKm = _distanceInMeters / 1000.0;
        setState(() {
          _cameraTarget = target;
          if (isRunning) {
            if (_routePoints.isNotEmpty) {
              final prev = _routePoints.last;
              final delta = Geolocator.distanceBetween(
                prev.latitude,
                prev.longitude,
                target.latitude,
                target.longitude,
              );
              if (delta.isFinite && delta > 0) {
                _distanceInMeters += delta;
              }
            }
            _routePoints = List<LatLng>.from(_routePoints)..add(target);
          }
          _markers = _buildMarkers(target);
        });
        if (isRunning) {
          unawaited(
            ref.read(voiceCoachingControllerProvider).onRunProgress(
                  previousKm: previousKm,
                  currentKm: _distanceInMeters / 1000.0,
                ),
          );
        }
        _mapController?.animateCamera(CameraUpdate.newLatLng(target));
      });
    } catch (_) {
      // Keep fallback camera — do not crash the screen.
    }
  }

  void _startRun() {
    if (isRunning) return;
    setState(() {
      isRunning = true;
      _elapsedSeconds = 0;
      _distanceInMeters = 0.0;
      _routePoints = [];
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !isRunning) return;
      setState(() => _elapsedSeconds++);
    });
    unawaited(_startPositionStream());
    unawaited(ref.read(voiceCoachingControllerProvider).onRunStarted());
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void _onFinish() {
    setState(() => isRunning = false);
    _stopTracking();
    unawaited(ref.read(voiceCoachingControllerProvider).onRunFinished());
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingRunResultScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _stopTracking();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiveRunningScreen._background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LiveRunningHeader(
              onBack: () => Navigator.pop(context),
              roomTitle: _roomTitle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppShapes.termsHorizontalPadding,
              ),
              child: _StatsDashboard(
                distance: _distanceLabel,
                time: _timeLabel,
                pace: _paceLabel,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppShapes.termsHorizontalPadding,
                ),
                child: _LiveGoogleMap(
                  cameraTarget: _cameraTarget,
                  routePoints: _routePoints,
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppShapes.termsHorizontalPadding,
                12,
                AppShapes.termsHorizontalPadding,
                8,
              ),
              child: const _EffortTipBox(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppShapes.termsHorizontalPadding,
                8,
                AppShapes.termsHorizontalPadding,
                4,
              ),
              child: isRunning
                  ? _ActionButton(
                      label: AppStrings.liveRunningFinish,
                      onTap: _onFinish,
                    )
                  : _ActionButton(
                      label: '시작',
                      onTap: _startRun,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                AppStrings.liveRunningSubmissionsLeft,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textGreyLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRunningHeader extends StatelessWidget {
  const _LiveRunningHeader({
    required this.onBack,
    required this.roomTitle,
  });

  final VoidCallback onBack;
  final String roomTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textWhite,
              iconSize: 22,
              onPressed: onBack,
            ),
          ),
          Text(
            roomTitle,
            style: AppTextStyles.header1.copyWith(
              fontSize: 17,
              color: AppColors.textWhite,
            ),
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VoiceCoachingHeaderToggle(color: AppColors.primaryMint),
                Text(
                  AppStrings.liveRunningGps,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.primaryMint,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.sensors_rounded,
                  color: AppColors.primaryMint,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsDashboard extends StatelessWidget {
  const _StatsDashboard({
    required this.distance,
    required this.time,
    required this.pace,
  });

  final String distance;
  final String time;
  final String pace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: AppColors.primaryMint, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMint.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.primaryMint.withValues(alpha: 0.15),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: AppStrings.liveRunningStatDistance,
              value: distance,
              valueColor: AppColors.textWhite,
            ),
          ),
          Expanded(
            child: _StatCell(
              label: AppStrings.liveRunningStatTime,
              value: time,
              valueColor: AppColors.primaryMint,
            ),
          ),
          Expanded(
            child: _StatCell(
              label: AppStrings.liveRunningStatPace,
              value: pace,
              valueColor: AppColors.primaryMint,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: AppColors.textGreyLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.header1.copyWith(
            fontSize: 20,
            color: valueColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LiveGoogleMap extends StatelessWidget {
  const _LiveGoogleMap({
    required this.cameraTarget,
    required this.routePoints,
    required this.markers,
    required this.onMapCreated,
  });

  final LatLng cameraTarget;
  final List<LatLng> routePoints;
  final Set<Marker> markers;
  final ValueChanged<GoogleMapController> onMapCreated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(
          color: LiveRunningScreen._neonPath.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: LiveRunningScreen._neonPath.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        child: ColoredBox(
          color: LiveRunningScreen._mapBackground,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: cameraTarget,
              zoom: 16,
            ),
            markers: markers,
            polylines: <Polyline>{
              Polyline(
                polylineId: const PolylineId('live_route'),
                points: routePoints,
                color: LiveRunningScreen._neonPath,
                width: 5,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            onMapCreated: onMapCreated,
          ),
        ),
      ),
    );
  }
}

class _EffortTipBox extends StatelessWidget {
  const _EffortTipBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(
          color: AppColors.primaryMintLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.liveRunningEffortTip,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: const Color(0xFFE8F5A0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryMint,
      borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
      elevation: 0,
      shadowColor: AppColors.primaryMint,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
        child: Container(
          height: AppShapes.buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMint.withValues(alpha: 0.55),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.textBlack,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textWhite,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
