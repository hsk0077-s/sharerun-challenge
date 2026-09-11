import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/config/app_env.dart';
import '../core/auth/health_data_consent_store.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/api/api_exception.dart';
import '../features/jena_validation/models/jena_validation_result.dart';
import '../features/run_tracking/models/route_point.dart';
import '../features/run_tracking/models/run_telemetry.dart';
import '../features/run_tracking/services/ghost_pace_matcher.dart';
import '../features/run_tracking/services/gps_tracking_service.dart';
import '../features/run_tracking/services/run_session_service.dart';
import '../features/run_tracking/utils/home_start_gate.dart';
import '../features/run_tracking/widgets/sponsor_live_buff_banner.dart';
import 'run_result_screen.dart';
import 'appeal_center_screen.dart';

/// 실전 라이브 러닝 트래커 — GPS · 센서 · Jena [ActivityPacket] · LBS 파기.
class InChallengeScreen extends ConsumerStatefulWidget {
  const InChallengeScreen({
    super.key,
    this.roomId,
    this.roomTitle,
    this.submissionsRemaining = 2,
    this.maxSubmissions = 3,
    this.ghostPaceSecPerKm = 285,
  });

  final String? roomId;
  final String? roomTitle;
  final int submissionsRemaining;
  final int maxSubmissions;
  final double ghostPaceSecPerKm;

  @override
  ConsumerState<InChallengeScreen> createState() => _InChallengeScreenState();
}

/// 개인 자유 달리기 — src-10 GPS 트래커.
typedef SoloRunTrackingScreen = InChallengeScreen;

class _InChallengeScreenState extends ConsumerState<InChallengeScreen> {

  StreamSubscription<RunTelemetry>? _telemetrySubscription;
  RunTelemetry _telemetry = RunTelemetry.empty;
  GoogleMapController? _mapController;
  BitmapDescriptor? _runnerIcon;
  BitmapDescriptor? _ghostIcon;
  var _starting = true;
  var _sessionStarted = false;
  var _validating = false;
  String? _startError;
  GpsPermissionResult? _permissionIssue;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    unawaited(_telemetrySubscription?.cancel());
    _mapController?.dispose();
    super.dispose();
  }

  String get _roomTitle {
    if (widget.roomTitle != null && widget.roomTitle!.isNotEmpty) {
      return widget.roomTitle!;
    }
    if (widget.roomId == RouteNames.beginner1kmRoomId) {
      return '1km 초보 챌린지방';
    }
    return AppStrings.liveRunningRoomTitle;
  }

  Future<void> _bootstrap() async {
    await _loadIcons();
    if (!mounted) return;
    await _startRunSession();
  }

  Future<void> _loadIcons() async {
    try {
      _runnerIcon = await _bubble(AppStrings.liveRunningYouLabel, AppColors.tealAccent);
      _ghostIcon = await _bubble(
        AppStrings.liveRunningGhostPace,
        AppColors.ghostPacePurple.withValues(alpha: 0.82),
      );
    } catch (_) {
      _runnerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _ghostIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  Future<BitmapDescriptor> _bubble(String text, Color bg) async {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    const padH = 16.0;
    const padV = 8.0;
    const pin = 10.0;
    final w = painter.width + padH * 2;
    final h = painter.height + padV * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(20)),
      Paint()..color = bg,
    );
    painter.paint(canvas, Offset((w - painter.width) / 2, (h - painter.height) / 2));
    canvas.drawPath(
      Path()
        ..moveTo(w / 2 - pin, h - 1)
        ..lineTo(w / 2 + pin, h - 1)
        ..lineTo(w / 2, h + pin)
        ..close(),
      Paint()..color = bg,
    );
    final image = await recorder.endRecording().toImage(w.ceil(), (h + pin).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(runSessionServiceProvider);
    final sponsorBuff = ref.watch(activeSponsorBuffProvider);
    final route = _telemetry.routePoints;
    final last = route.isEmpty ? null : route.last;
    final ghost = GhostPaceMatcher.positionAt(
      routePoints: route,
      elapsedSeconds: _telemetry.durationSeconds,
      ghostPaceSecPerKm: widget.ghostPaceSecPerKm,
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.liveRunningBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: _roomTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                if (sponsorBuff != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppShapes.termsHorizontalPadding,
                    ),
                    child: SponsorLiveBuffBanner(buff: sponsorBuff),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppShapes.termsHorizontalPadding,
                  ),
                  child: _BlurStats(
                    distanceKm: _telemetry.distanceKm,
                    durationSeconds: _telemetry.durationSeconds,
                    paceLabel: _formatPace(
                      _telemetry.distanceKm,
                      _telemetry.durationSeconds,
                    ),
                    heartRate: _telemetry.currentHeartRate,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppShapes.termsHorizontalPadding,
                    ),
                    child: _LiveMap(
                      routePoints: route,
                      lastLatitude: last?.latitude,
                      lastLongitude: last?.longitude,
                      ghostPosition: ghost,
                      runnerIcon: _runnerIcon,
                      ghostIcon: _ghostIcon,
                      permissionIssue: _permissionIssue,
                      startError: _startError,
                      onMapCreated: (c) => _mapController = c,
                      onOpenSettings: openAppSettings,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    10,
                    AppShapes.termsHorizontalPadding,
                    4,
                  ),
                  child: _EffortCapsule(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    8,
                    AppShapes.termsHorizontalPadding,
                    4,
                  ),
                  child: _SlideToFinish(
                    enabled: _sessionStarted && !_starting && !_validating,
                    loading: _starting || _validating,
                    label: _starting
                        ? '센서 준비 중...'
                        : _validating
                            ? 'Jena 검증 중...'
                            : '[ ${AppStrings.liveRunningFinish} > ]',
                    onConfirmed: _finishAndValidate,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '제출 기회: ${widget.submissionsRemaining}/${widget.maxSubmissions}회 남음',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textGreyLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_validating) const _JenaOverlay(),
      ],
    );
  }

  Future<void> _startRunSession() async {
    try {
      final firebaseUser = ref.read(authStateChangesProvider).value;
      final localUid = ref.read(persistedAuthSessionProvider)?.uid;
      final signedIn = firebaseUser != null ||
          (localUid != null && localUid.isNotEmpty);
      final profileConsent =
          ref.read(activeUserProfileProvider).value?.healthDataConsent ?? false;
      final prefsConsent = await HealthDataConsentStore().readAgreed();
      final startBlocked = HomeStartGate.startBlockReason(
        signedIn: signedIn,
        healthConsent: profileConsent || prefsConsent,
      );
      if (startBlocked != null) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _sessionStarted = false;
          _startError = startBlocked;
        });
        return;
      }
      final service = ref.read(runSessionServiceProvider);
      _telemetrySubscription = service.telemetryStream.listen((event) {
        if (!mounted) return;
        final prev = _telemetry.routePoints.length;
        setState(() => _telemetry = event);
        if (event.routePoints.length > prev && event.routePoints.isNotEmpty) {
          final p = event.routePoints.last;
          final controller = _mapController;
          if (controller != null) {
            unawaited(
              controller.animateCamera(
                CameraUpdate.newLatLng(LatLng(p.latitude, p.longitude)),
              ),
            );
          }
        }
      });
      await service.start();
      if (!mounted) return;
      setState(() {
        _starting = false;
        _sessionStarted = true;
        _startError = null;
        _permissionIssue = null;
      });
    } on GpsPermissionException catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _sessionStarted = false;
        _permissionIssue = e.result;
        _startError = e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _sessionStarted = false;
        _startError = '센서 시작 실패: $e';
      });
    }
  }

  Future<void> _finishAndValidate() async {
    setState(() => _validating = true);
    final authUser = ref.read(authStateChangesProvider).value;
    final validateBlocked = HomeStartGate.validateBlockReason(
      signedIn: authUser != null,
      sessionStarted: _sessionStarted,
    );
    if (validateBlocked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validateBlocked)),
      );
      setState(() => _validating = false);
      return;
    }

    final userId = authUser!.uid;
    final activityId = 'activity-${DateTime.now().millisecondsSinceEpoch}';
    CompletedRunSession? session;
    try {
      session = await ref.read(runSessionServiceProvider).finish(
            activityId: activityId,
            userId: userId,
          );
      final result = await ref
          .read(activityValidationServiceProvider)
          .validateAndPersistResult(
            activityId: activityId,
            userId: userId,
            distanceKm: session.telemetry.distanceKm,
            durationSeconds: session.telemetry.durationSeconds,
            gyroStabilityScore: session.telemetry.gyroStabilityScore,
            routePoints: session.routePoints,
            sensorBuffer: session.sensorBuffer,
          );
      final distanceKm = session.telemetry.distanceKm;
      final durationSeconds = session.telemetry.durationSeconds;
      final totalSteps = session.totalSteps;
      session.discardAllSensitive();

      if (!mounted) return;
      if (result.decision == JenaDecision.pending) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Jena AI 기록 검증 보류'),
              content: const Text(
                '강제 정지 대신 소명 기회가 부여되었습니다. 증빙 자료를 제출해 주세요.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('소명하러 가기'),
                ),
              ],
            );
          },
        );
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => AppealCenterScreen(
              activityId: activityId,
              challengeTitle: widget.roomTitle ?? '중급 3km 챌린지',
            ),
          ),
        );
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            activityId: activityId,
            result: result,
            routePoints: const [],
            distanceKm: distanceKm,
            durationSeconds: durationSeconds,
            totalSteps: totalSteps,
          ),
        ),
      );
    } catch (error) {
      session?.discardAllSensitive();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jena 검증 실패: ${ApiErrorMessage.from(error)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  String _formatPace(double km, int seconds) {
    if (km < 0.01 || seconds <= 0) return '--:-- /km';
    final pace = (seconds / km).round();
    return '${(pace ~/ 60).toString().padLeft(2, '0')}:'
        '${(pace % 60).toString().padLeft(2, '0')} /km';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textWhite,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.header1.copyWith(
                fontSize: 17,
                color: AppColors.textWhite,
              ),
            ),
          ),
          const Icon(Icons.sensors_rounded, color: AppColors.tealAccent, size: 18),
          const SizedBox(width: 4),
          Text(
            AppStrings.liveRunningGps,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.tealAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _BlurStats extends StatelessWidget {
  const _BlurStats({
    required this.distanceKm,
    required this.durationSeconds,
    required this.paceLabel,
    required this.heartRate,
  });

  final double distanceKm;
  final int durationSeconds;
  final String paceLabel;
  final int? heartRate;

  @override
  Widget build(BuildContext context) {
    final mm = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (durationSeconds % 60).toString().padLeft(2, '0');
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
            border: Border.all(
              color: AppColors.tealAccent.withValues(alpha: 0.5),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              _Stat(AppStrings.liveRunningStatDistance, '${distanceKm.toStringAsFixed(1)} km'),
              _Stat(AppStrings.liveRunningStatTime, '$mm:$ss', color: AppColors.primaryMint),
              _Stat(AppStrings.liveRunningStatPace, paceLabel, color: AppColors.tealAccent),
              _Stat('심박수', heartRate != null ? '$heartRate BPM' : '-- BPM', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color = AppColors.textWhite});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textGreyLight),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.header1.copyWith(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

class _LiveMap extends StatelessWidget {
  const _LiveMap({
    required this.routePoints,
    required this.lastLatitude,
    required this.lastLongitude,
    required this.ghostPosition,
    required this.runnerIcon,
    required this.ghostIcon,
    required this.permissionIssue,
    required this.startError,
    required this.onMapCreated,
    required this.onOpenSettings,
  });

  final List<RoutePoint> routePoints;
  final double? lastLatitude;
  final double? lastLongitude;
  final LatLng? ghostPosition;
  final BitmapDescriptor? runnerIcon;
  final BitmapDescriptor? ghostIcon;
  final GpsPermissionResult? permissionIssue;
  final String? startError;
  final ValueChanged<GoogleMapController> onMapCreated;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        ),
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (permissionIssue != null &&
        permissionIssue != GpsPermissionResult.granted) {
      return ColoredBox(
        color: AppColors.liveMapBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_rounded, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  startError ?? '위치 권한이 필요합니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.tealAccent),
                  onPressed: onOpenSettings,
                  child: const Text('시스템 설정 열기'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!AppEnv.isGoogleMapsConfigured) {
      return const ColoredBox(
        color: AppColors.liveMapBackground,
        child: Center(
          child: Text('Google Maps API 키가 설정되지 않았습니다.', style: TextStyle(color: AppColors.textGreyLight)),
        ),
      );
    }
    if (lastLatitude == null || lastLongitude == null) {
      return const ColoredBox(
        color: AppColors.liveMapBackground,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.tealAccent, strokeWidth: 2.4),
        ),
      );
    }

    final pts = routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final me = LatLng(lastLatitude!, lastLongitude!);
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: me, zoom: 17),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onMapCreated: onMapCreated,
      polylines: pts.length >= 2
          ? {
              Polyline(
                polylineId: const PolylineId('live-route'),
                color: AppColors.tealAccent,
                width: 5,
                points: pts,
              ),
            }
          : {},
      markers: {
        Marker(
          markerId: const MarkerId('runner'),
          position: me,
          icon: runnerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 1),
        ),
        if (ghostPosition != null)
          Marker(
            markerId: const MarkerId('ghost'),
            position: ghostPosition!,
            icon: ghostIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            anchor: const Offset(0.5, 1),
            alpha: 0.72,
          ),
      },
    );
  }
}

class _EffortCapsule extends StatelessWidget {
  const _EffortCapsule();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.35)),
      ),
      child: Text(
        '💡 ${AppStrings.liveRunningEffortTip}',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFFE8F5A0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SlideToFinish extends StatefulWidget {
  const _SlideToFinish({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onConfirmed,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback onConfirmed;

  @override
  State<_SlideToFinish> createState() => _SlideToFinishState();
}

class _SlideToFinishState extends State<_SlideToFinish> {
  double _offset = 0;
  var _done = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const knob = 52.0;
        final max = (c.maxWidth - knob - 16).clamp(0.0, double.infinity);
        return GestureDetector(
          onHorizontalDragUpdate: widget.enabled && !widget.loading
              ? (d) => setState(() => _offset = (_offset + d.delta.dx).clamp(0, max))
              : null,
          onHorizontalDragEnd: widget.enabled && !widget.loading
              ? (_) {
                  if (_offset >= max * 0.88 && !_done) {
                    _done = true;
                    widget.onConfirmed();
                  } else {
                    setState(() => _offset = 0);
                  }
                }
              : null,
          child: Container(
            height: AppShapes.buttonHeight,
            decoration: BoxDecoration(
              color: AppColors.primaryMint,
              borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.label,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Positioned(
                  left: 8 + _offset,
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: const BoxDecoration(
                      color: AppColors.textBlack,
                      shape: BoxShape.circle,
                    ),
                    child: widget.loading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textWhite,
                            ),
                          )
                        : const Icon(Icons.chevron_right_rounded, color: AppColors.textWhite),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JenaOverlay extends StatelessWidget {
  const _JenaOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryMint),
            SizedBox(height: 16),
            Text(
              'Jena AI가 러닝 데이터를 검증 중입니다...',
              style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
