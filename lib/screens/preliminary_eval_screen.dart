import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/router/route_names.dart';
import '../core/theme/app_colors.dart';

class PreliminaryEvalScreen extends StatefulWidget {
  const PreliminaryEvalScreen({super.key});

  @override
  State<PreliminaryEvalScreen> createState() => _PreliminaryEvalScreenState();
}

class _PreliminaryEvalScreenState extends State<PreliminaryEvalScreen> {
  bool _isRunning = false;
  int _completedRuns = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _distanceInMeters = 0.0;
  StreamSubscription<Position>? _positionStream;

  static const LatLng _fallbackTarget = LatLng(37.5665, 126.9780);

  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  LatLng _cameraTarget = _fallbackTarget;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _meIcon;
  BitmapDescriptor? _ghostIcon;

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
      return "--'--\"";
    }
    final minutesPerKm = (_elapsedSeconds / 60.0) / km;
    final totalSeconds = (minutesPerKm * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// Returns animal tier name only. Pace = average seconds per km.
  String _calculateTier() {
    final km = _distanceInMeters / 1000.0;
    if (km <= 0 || _elapsedSeconds <= 0) {
      return '[거북이]';
    }
    final pace = (_elapsedSeconds / km).round();
    if (pace < 240) return '[치타]';
    if (pace < 300) return '[말]';
    if (pace < 360) return '[토끼]';
    if (pace < 420) return '[개]';
    return '[거북이]';
  }

  @override
  void initState() {
    super.initState();
    // Marker icons + one-shot initial location — no Timer / GPS stream.
    Future.microtask(() async {
      await _initializeMarkerIcons();
      await _fetchInitialLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _positionStream?.cancel();
    _positionStream = null;
    _mapController = null;
    super.dispose();
  }

  Future<void> _initializeMarkerIcons() async {
    try {
      _meIcon ??= await _createCustomMarkerBitmap('나', AppColors.primaryMint);
      _ghostIcon ??= await _createCustomMarkerBitmap(
        '고스트',
        const Color(0xFF7E57C2),
      );
      if (!mounted) return;
      setState(() => _markers = _buildMarkers(_cameraTarget));
    } catch (_) {
      if (!mounted) return;
      setState(() => _markers = _buildMarkers(_cameraTarget));
    }
  }

  /// One-shot current position for the map preview only (no timer / tracking).
  Future<void> _fetchInitialLocation() async {
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
      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _cameraTarget = target;
        _markers = _buildMarkers(target);
      });
      await _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (_) {
      // Keep fallback camera — do not crash the screen.
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    String text,
    Color bgColor,
  ) async {
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
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 1.0),
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    if (_routePoints.length < 2) {
      return {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: AppColors.primaryMint,
        width: 5,
      ),
    };
  }

  LocationSettings _runLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          intervalDuration: const Duration(seconds: 1),
        ),
      TargetPlatform.iOS || TargetPlatform.macOS => AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.fitness,
          distanceFilter: 3,
          pauseLocationUpdatesAutomatically: false,
        ),
      _ => const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
    };
  }

  Future<bool> _ensureLocationReady() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  void _applyPosition(Position position) {
    if (!mounted || !_isRunning) return;
    final target = LatLng(position.latitude, position.longitude);
    setState(() {
      _cameraTarget = target;
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
      _markers = _buildMarkers(target);
      _polylines = _buildPolylines();
    });
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (_) {}
  }

  /// 기록 검증 보류: GPS 실패해도 타이머 심사는 반드시 시작된다.
  Future<void> _startRun() async {
    if (_isRunning || _completedRuns >= 5) return;

    setState(() {
      _isRunning = true;
      _elapsedSeconds = 0;
      _distanceInMeters = 0.0;
      _routePoints = [];
      _polylines = {};
      _markers = _buildMarkers(_cameraTarget);
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning) return;
      setState(() => _elapsedSeconds++);
    });

    // GPS는 best-effort — 권한/수신 실패해도 회차 진행을 막지 않는다.
    unawaited(_attachGpsBestEffort());
  }

  void _stopRun() {
    if (!_isRunning) return;
    _timer?.cancel();
    _timer = null;
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _isRunning = false;
      _completedRuns++;
    });
  }

  Future<void> _attachGpsBestEffort() async {
    try {
      final ready = await _ensureLocationReady();
      if (!ready || !mounted || !_isRunning) return;

      try {
        final seed = await Geolocator.getCurrentPosition(
          locationSettings: _runLocationSettings(),
        ).timeout(const Duration(seconds: 5));
        if (mounted && _isRunning) _applyPosition(seed);
      } catch (e) {
        debugPrint('PreliminaryEval GPS seed skipped: $e');
      }

      if (!mounted || !_isRunning) return;

      await _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: _runLocationSettings(),
      ).listen(
        _applyPosition,
        onError: (Object error) {
          debugPrint('PreliminaryEval GPS stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('PreliminaryEval GPS attach skipped: $e');
    }
  }

  void _assignTierAndReward() {
    final tierName = _calculateTier();
    final averagePace = _paceLabel;
    debugPrint('Tier assigned: $tierName');
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('🎉 심사 완료 결과'),
          content: Text(
            '총 5회 예비 심사를 완료했습니다!\n\n'
            '평균 페이스: $averagePace\n'
            '최종 등급: $tierName\n'
            '보상: 본인 500 VALUE 지급!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _goMainScreen();
              },
              child: const Text('확인 (메인으로)'),
            ),
          ],
        );
      },
    );
  }

  void _goMainScreen() {
    if (!mounted) return;
    // MaterialApp(온보딩) / GoRouter(인증 셸) 모두에서 메인으로 진입.
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.go(RouteNames.mainDashboard);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.mainDashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String buttonLabel;
    final VoidCallback? onPressed;

    if (_completedRuns >= 5) {
      buttonLabel = '심사 완료 및 보상 받기';
      onPressed = _assignTierAndReward;
    } else if (!_isRunning) {
      buttonLabel = '${_completedRuns + 1}회차 시작하기';
      onPressed = () => unawaited(_startRun());
    } else {
      buttonLabel = '${_completedRuns + 1}회차 완료/정지';
      onPressed = _stopRun;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        centerTitle: true,
        title: const Text(
          '5회 등급심사',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _goMainScreen,
            child: const Text(
              '건너뛰기',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                '본 대회 입장 전, 정확한 실력 측정을 위해 5회의 예비 러닝을 완료해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '※ 심사 미완료 시, 본 대회 매칭을 포함한 일부 핵심 서비스 이용이 제한될 수 있습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent.shade200,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '현재 거리',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _distanceLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 36,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppColors.borderLight,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '경과 시간',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _timeLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 36,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppColors.borderLight,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '현재 페이스',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _paceLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '챌린지 진행 상황: $_completedRuns/5회 완료',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (index) {
                  final step = index + 1;
                  final done = step <= _completedRuns;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 10,
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.primaryMint
                                  : AppColors.borderLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$step',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: done
                                  ? AppColors.primaryMintDark
                                  : AppColors.textGreyLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _cameraTarget,
                      zoom: 15.5,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      controller.animateCamera(
                        CameraUpdate.newLatLng(_cameraTarget),
                      );
                    },
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomControlsEnabled: true,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    markers: _markers,
                    polylines: _polylines,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryMint,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
