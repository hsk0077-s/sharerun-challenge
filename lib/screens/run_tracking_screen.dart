import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../features/run_tracking/models/run_telemetry.dart';
import '../features/run_tracking/utils/home_start_gate.dart';
import '../features/run_tracking/widgets/sponsor_live_buff_banner.dart';
import 'run_result_screen.dart';

class RunTrackingScreen extends ConsumerStatefulWidget {
  const RunTrackingScreen({super.key});

  @override
  ConsumerState<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends ConsumerState<RunTrackingScreen> {
  StreamSubscription<RunTelemetry>? telemetrySubscription;
  RunTelemetry telemetry = RunTelemetry.empty;
  bool starting = true;
  bool sessionStarted = false;
  bool validating = false;
  String? startError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_startRunSession);
  }

  @override
  void dispose() {
    unawaited(telemetrySubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(runSessionServiceProvider);
    final sponsorBuff = ref.watch(activeSponsorBuffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SRC Run Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sponsorBuff != null) ...[
              SponsorLiveBuffBanner(buff: sponsorBuff),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Text(
                    '${telemetry.distanceKm.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.neonLime,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(_formatDuration(telemetry.durationSeconds)),
                  const SizedBox(height: 8),
                  Text(
                    'HR ${telemetry.currentHeartRate?.toString() ?? '--'} BPM / '
                    'Cadence ${telemetry.currentCadenceSpm?.toString() ?? '--'} SPM',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gyro stability ${telemetry.gyroStabilityScore.toStringAsFixed(2)}',
                  ),
                  if (startError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      startError!,
                      style: const TextStyle(color: AppColors.dangerRed),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: starting || validating || !sessionStarted
                  ? null
                  : _finishAndValidate,
              icon: starting || validating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_rounded),
              label: Text(
                starting
                    ? 'Starting sensors...'
                    : validating
                        ? 'Jena validating...'
                        : 'Finish & Validate Run',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRunSession() async {
    try {
      var profile = ref.read(activeUserProfileProvider).value;
      if (profile == null) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        profile = ref.read(activeUserProfileProvider).value;
      }

      if (profile?.healthDataConsent != true) {
        throw StateError(
          'MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.',
        );
      }

      final runSessionService = ref.read(runSessionServiceProvider);
      telemetrySubscription = runSessionService.telemetryStream.listen(
        (event) {
          if (mounted) {
            setState(() => telemetry = event);
          }
        },
      );
      await runSessionService.start();

      if (!mounted) {
        return;
      }
      setState(() {
        starting = false;
        sessionStarted = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        starting = false;
        sessionStarted = false;
        startError = 'Sensor start failed: $error';
      });
    }
  }

  Future<void> _finishAndValidate() async {
    setState(() => validating = true);

    final authUser = ref.read(authStateChangesProvider).value;
    final validateBlocked = HomeStartGate.validateBlockReason(
      signedIn: authUser != null,
      sessionStarted: sessionStarted,
    );
    if (validateBlocked != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validateBlocked)),
        );
        setState(() => validating = false);
      }
      return;
    }

    final userId = authUser!.uid;
    final activityId = 'activity-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final completedRun = await ref.read(runSessionServiceProvider).finish();

      final result = await ref
          .read(activityValidationServiceProvider)
          .validateAndPersistResult(
            activityId: activityId,
            userId: userId,
            distanceKm: completedRun.telemetry.distanceKm,
            durationSeconds: completedRun.telemetry.durationSeconds,
            gyroStabilityScore: completedRun.telemetry.gyroStabilityScore,
            routePoints: completedRun.routePoints,
            sensorBuffer: completedRun.sensorBuffer,
          );

      if (!mounted) {
        return;
      }
      context.go(
        RouteNames.runResult,
        extra: RunResultArgs(
          activityId: activityId,
          result: result,
          routePoints: completedRun.routePoints,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jena validation failed: ${ApiErrorMessage.from(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() => validating = false);
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
