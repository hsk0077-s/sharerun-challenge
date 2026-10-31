import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../data/models/winner_reward_action.dart';
import '../features/jena_validation/models/jena_validation_result.dart';
import '../features/jena_validation/verification_reason.dart';
import '../features/reward/view/winner_honor_popup.dart';
import '../features/run_tracking/models/route_point.dart';
import '../l10n/remaining_surface.dart';

class RunResultArgs {
  const RunResultArgs({
    required this.activityId,
    required this.result,
    required this.routePoints,
  });

  final String activityId;
  final JenaValidationResult result;
  final List<RoutePoint> routePoints;
}

class RunResultScreen extends ConsumerStatefulWidget {
  const RunResultScreen({
    required this.activityId,
    required this.result,
    required this.routePoints,
    super.key,
  });

  final String activityId;
  final JenaValidationResult result;
  final List<RoutePoint> routePoints;

  @override
  ConsumerState<RunResultScreen> createState() => _RunResultScreenState();
}

class _RunResultScreenState extends ConsumerState<RunResultScreen> {
  bool processingReward = false;
  bool rewardProcessed = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final routePoints = widget.routePoints;
    final canProcessReward =
        result.verified && result.valueTokenReward > 0 && !rewardProcessed;
    final color = result.verified ? AppColors.neonLime : AppColors.dangerRed;
    final headline = result.verified
        ? RemainingSurface.tr(context, 'run_result.title', '검증된 러닝')
        : result.decision == JenaDecision.pending
            ? RemainingSurface.tr(context, 'run_result.title.2', '인정되지 않은 기록')
            : RemainingSurface.tr(context, 'run_result.title.3', '검증되지 않은 기록');

    return Scaffold(
      appBar: AppBar(
        title: Text(RemainingSurface.tr(context, 'run_result.title.4', '러닝 결과')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                border: Border.all(color: color.withOpacity(0.55)),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(verificationUserMessage(result)),
                  const SizedBox(height: 16),
                  Text(
                    RemainingSurface.tr(
                      context,
                      'run_result.body',
                      '판정: ${result.decision.name}',
                      {'result.decision.name': result.decision.name},
                    ),
                  ),
                  Text(
                    RemainingSurface.tr(
                      context,
                      'run_result.body.2',
                      'VALUE 보상: ${result.valueTokenReward}',
                      {'result.valueTokenReward': result.valueTokenReward},
                    ),
                  ),
                ],
              ),
            ),
            if (routePoints.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        routePoints.first.latitude,
                        routePoints.first.longitude,
                      ),
                      zoom: 16,
                    ),
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('verified-route'),
                        color: AppColors.neonLime,
                        width: 5,
                        points: routePoints
                            .map(
                              (point) => LatLng(
                                point.latitude,
                                point.longitude,
                              ),
                            )
                            .toList(),
                      ),
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('start'),
                        position: LatLng(
                          routePoints.first.latitude,
                          routePoints.first.longitude,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('finish'),
                        position: LatLng(
                          routePoints.last.latitude,
                          routePoints.last.longitude,
                        ),
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (canProcessReward) ...[
              FilledButton.icon(
                onPressed: processingReward ? null : _showRewardDialog,
                icon: processingReward
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.workspace_premium_rounded),
                label: Text(
                  processingReward
                      ? RemainingSurface.tr(
                          context, 'run_result.button', '보상을 처리하는 중...')
                      : RemainingSurface.tr(
                          context, 'run_result.button.2', '우승 상금 선택하기'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: () => context.go(RouteNames.home),
              child: Text(
                RemainingSurface.tr(context, 'run_result.button.3', '홈으로 돌아가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRewardDialog() async {
    await WinnerHonorPopup.show(
      context: context,
      rewardValueToken: widget.result.valueTokenReward,
      onDonateHalf: () => _processReward(WinnerRewardAction.donateHalf),
      onDonateAll: () => _processReward(WinnerRewardAction.donateAll),
      onClaimAll: () => _processReward(WinnerRewardAction.claimAll),
    );
  }

  Future<void> _processReward(WinnerRewardAction action) async {
    if (ref.read(authStateChangesProvider).value == null) {
      _showSnack(
        RemainingSurface.tr(context, 'run_result.body.3', '로그인이 필요합니다.'),
      );
      return;
    }

    setState(() => processingReward = true);
    try {
      await ref.read(rewardRepositoryProvider).applyWinnerReward(
            activityId: widget.activityId,
            action: action,
          );
      if (!mounted) {
        return;
      }
      setState(() => rewardProcessed = true);
      _showSnack(
        RemainingSurface.tr(
          context,
          'run_result.body.4',
          '우승 보상 처리가 완료되었습니다.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        RemainingSurface.tr(
          context,
          'run_result.body.5',
          '우승 보상 처리 실패: ${ApiErrorMessage.from(error)}',
          {'ApiErrorMessage.from(error)': ApiErrorMessage.from(error)},
        ),
      );
    } finally {
      if (mounted) {
        setState(() => processingReward = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// GoRouter / dashboard 라우트용 결과 화면 인자.
class ResultScreenArgs {
  const ResultScreenArgs({
    required this.activityId,
    required this.result,
    this.routePoints = const [],
    this.distanceKm = 0,
    this.durationSeconds = 0,
    this.totalSteps,
    this.playerName,
  });

  final String activityId;
  final JenaValidationResult result;
  final List<RoutePoint> routePoints;
  final double distanceKm;
  final int durationSeconds;
  final int? totalSteps;
  final String? playerName;
}

/// [RunResultScreen] 라우터 별칭 (dashboard / in-challenge 호환).
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    required this.activityId,
    required this.result,
    required this.routePoints,
    this.distanceKm = 0,
    this.durationSeconds = 0,
    this.totalSteps,
    this.playerName,
    super.key,
  });

  final String activityId;
  final JenaValidationResult result;
  final List<RoutePoint> routePoints;
  final double distanceKm;
  final int durationSeconds;
  final int? totalSteps;
  final String? playerName;

  @override
  Widget build(BuildContext context) {
    return RunResultScreen(
      activityId: activityId,
      result: result,
      routePoints: routePoints,
    );
  }
}
