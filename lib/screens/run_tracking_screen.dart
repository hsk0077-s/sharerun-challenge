import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../core/theme/src_theme.dart';
import '../features/run_tracking/models/run_telemetry.dart';
import '../features/run_tracking/music_controls.dart';
import '../features/run_tracking/run_recording_checklist.dart';
import '../features/run_tracking/services/run_session_service.dart';
import '../data/models/user_model.dart';
import '../features/jena_validation/models/jena_validation_result.dart';
import '../features/jena_validation/verification_reason.dart';
import '../features/run_tracking/utils/home_start_gate.dart';
import '../features/run_tracking/widgets/sponsor_live_buff_banner.dart';
import '../features/world_tour/widgets/world_tour_widgets.dart';
import '../features/world_tour/world_tour_run_end.dart';
import '../l10n/remaining_surface.dart';
import 'run_result_screen.dart';

class RunTrackingScreen extends ConsumerStatefulWidget {
  const RunTrackingScreen({super.key, this.worldTourRun});

  /// Set only when the run was started from World Tour. Null for every
  /// ordinary run, which behaves exactly as before.
  final WorldTourRunArgs? worldTourRun;

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

  /// 기록이 이미 정상 종료(finish)됐으면 true. dispose 안전망이 한 번 더 정리하지 않게 한다.
  bool _sessionClosed = false;
  RunSessionService? _service;

  /// 기록 중(시작됨, 검증 제출 중 아님)일 때만 뒤로 가기에 확인창을 띄운다.
  /// 시작 전이거나 센서를 못 켠 상태면 확인 없이 나간다.
  bool get _recording => sessionStarted && !validating && !_sessionClosed;

  @override
  void initState() {
    super.initState();
    Future.microtask(_startRunSession);
  }

  @override
  void dispose() {
    unawaited(telemetrySubscription?.cancel());
    // 안전망: 화면이 정상 종료 없이 사라져도 위치 구독·포그라운드 서비스·타이머를 남기지 않는다.
    // (서비스는 autoDispose provider라 보통 함께 정리되지만, 여기서도 한 번 더 확실히 한다.)
    final service = _service;
    if (service != null && !_sessionClosed) {
      unawaited(service.dispose());
    }
    super.dispose();
  }

  /// 뒤로 가기: 기록 중이면 "달리기를 끝낼까요?"를 묻고, "끝내기"는 기존 정상 종료 흐름을 그대로 쓴다.
  Future<void> _confirmLeave() async {
    final end = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('run-leave-dialog'),
        title: Text(
          RemainingSurface.tr(
              dialogContext, 'run_tracking.leave.title', '달리기를 끝낼까요?'),
        ),
        content: Text(
          RemainingSurface.tr(
            dialogContext,
            'run_tracking.leave.body',
            '끝내면 지금까지의 기록을 검증으로 보내요.',
          ),
        ),
        actions: [
          TextButton(
            key: const Key('run-leave-continue'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              RemainingSurface.tr(
                  dialogContext, 'run_tracking.leave.continue', '계속 달리기'),
            ),
          ),
          FilledButton(
            key: const Key('run-leave-end'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              RemainingSurface.tr(
                  dialogContext, 'run_tracking.leave.end', '끝내기'),
            ),
          ),
        ],
      ),
    );
    if (end != true || !mounted) return;
    await _finishAndValidate();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(runSessionServiceProvider);
    final sponsorBuff = ref.watch(activeSponsorBuffProvider);

    return PopScope(
      canPop: !_recording,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_confirmLeave());
      },
      child: Theme(
      data: SrcTheme.night,
      child: Scaffold(
      appBar: AppBar(
        title: Text(RemainingSurface.tr(context, 'run_tracking.title', '달리기 기록')),
      ),
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
                color: AppColors.nightCard,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Text(
                    '${telemetry.distanceKm.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.nightLime,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(_formatDuration(telemetry.durationSeconds)),
                  const SizedBox(height: 8),
                  Text(
                    RemainingSurface.trNow(
                      'run_tracking.telemetry',
                      '심박 \$hr BPM / 케이던스 \$spm SPM',
                      {
                        'hr': telemetry.currentHeartRate?.toString() ?? '--',
                        'spm': telemetry.currentCadenceSpm?.toString() ?? '--',
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    RemainingSurface.tr(
                      context,
                      'run_tracking.body.3',
                      '자이로 안정도 ${telemetry.gyroStabilityScore.toStringAsFixed(2)}',
                      {
                        'telemetry.gyroStabilityScore.toStringAsFixed(2)':
                            telemetry.gyroStabilityScore.toStringAsFixed(2),
                      },
                    ),
                  ),
                  if (startError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      startError!,
                      style: const TextStyle(color: AppColors.nightDanger),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.worldTourRun != null) ...[
              const SizedBox(height: 12),
              WorldTourRunChip(
                args: widget.worldTourRun!,
                runKm: telemetry.distanceKm,
              ),
            ],
            const Spacer(),
            const MusicControls(),
            const SizedBox(height: 8),
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
                    ? RemainingSurface.tr(
                        context, 'run_tracking.body.4', '센서를 시작하는 중...')
                    : validating
                        ? RemainingSurface.tr(
                            context, 'run_tracking.body.5', '러닝 검증 중...')
                        : RemainingSurface.tr(
                            context, 'run_tracking.body.6', '러닝 끝내고 검증하기'),
              ),
            ),
          ],
        ),
      ),
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
          RemainingSurface.trNow(
            'run_tracking.body.7',
            'MyPage에서 [선택] 민감정보 수집 동의 후 러닝 검증을 시작할 수 있습니다.',
          ),
        );
      }

      if (!mounted) return;
      await ensureRunRecordingChecklist(context);
      if (!mounted) return;

      final runSessionService = ref.read(runSessionServiceProvider);
      _service = runSessionService;
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
        startError = RemainingSurface.tr(
          context,
          'run_tracking.body.8',
          '센서를 시작하지 못했어요: $error',
          {'error': error},
        );
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
      _sessionClosed = true;

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
            totalSteps: completedRun.totalSteps,
            watchType: ref.read(activeUserProfileProvider).value?.watchType ??
                WatchType.none,
          );

      if (!mounted) {
        return;
      }
      if (!result.verified && result.decision != JenaDecision.pending) {
        await showVerificationRejectedDialog(context, result);
        if (!mounted) return;
      }
      // World Tour only: link this run to the chosen mission. The server
      // decides; a failure here never changes the ordinary run result.
      final tourArgs = widget.worldTourRun;
      final tourEnd = tourArgs == null
          ? null
          : await WorldTourRunEnd.settle(
              ref: ref,
              args: tourArgs,
              uid: userId,
              activityId: activityId,
              verified: result.verified,
              pending: result.decision == JenaDecision.pending,
              distanceKm: completedRun.telemetry.distanceKm,
              durationSeconds: completedRun.telemetry.durationSeconds,
            );
      if (!mounted) return;
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      context.go(
        RouteNames.runResult,
        extra: RunResultArgs(
          activityId: activityId,
          result: result,
          routePoints: completedRun.routePoints,
        ),
      );
      tourEnd?.announce(router: router, messenger: messenger);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            RemainingSurface.tr(
              context,
              'run_tracking.toast',
              '러닝 검증에 실패했어요: ${ApiErrorMessage.from(error)}',
              {'ApiErrorMessage.from(error)': ApiErrorMessage.from(error)},
            ),
          ),
        ),
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
