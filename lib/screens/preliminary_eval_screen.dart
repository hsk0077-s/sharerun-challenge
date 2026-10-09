import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/constants/economy_constants.dart';
import '../core/theme/app_colors.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/run_tracking/utils/run_start_preflight.dart';

/// 등급 배정 안내. 횟수와 등급은 모두 서버가 정한 값이다.
/// 1km 이상 검증 달리기를 서로 다른 날 3번 마치면 서버가 세 기록의
/// 중간 페이스로 등급을 한 번 배정한다. 이 화면은 기록을 만들지 않는다.
class PreliminaryEvalScreen extends ConsumerWidget {
  const PreliminaryEvalScreen({super.key});

  static const _total = EconomyConstants.trialRunsRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeUserProfileProvider).asData?.value;
    final tier = UserTier.tryFromRankScore(profile?.gradeRank ?? 0);
    final done = tier != null
        ? _total
        : (profile?.economy.gradeRunCount ?? 0).clamp(0, _total);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        centerTitle: true,
        title: const Text(
          '등급 배정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                '1km 이상 검증된 달리기를 서로 다른 날 3번 마치면, '
                '서버가 세 기록의 중간 페이스로 등급을 정해 드려요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tier == null
                    ? '진행 상황: $done/$_total회 완료'
                    : '배정된 등급: ${tier.koreanName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(_total, (index) {
                  final step = index + 1;
                  final reached = step <= done;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < _total - 1 ? 8 : 0),
                      child: Column(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: reached
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
                              color: reached
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
              const Text(
                '같은 날 달린 기록은 한 번으로 세요. '
                '기록이 서버에서 확인된 뒤에 횟수가 올라가요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              if (tier == null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => startRunWithPreflight(
                      context: context,
                      profile: profile,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryMint,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '달리기 시작하기',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
