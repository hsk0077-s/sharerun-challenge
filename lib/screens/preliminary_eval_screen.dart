import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/theme/app_colors.dart';
import '../l10n/surface_copy.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/onboarding/widgets/chibi_tier_avatar.dart';
import '../features/run_tracking/utils/run_start_preflight.dart';

/// 등급 배정 안내. 횟수와 등급은 모두 서버가 정한 값이다.
/// 첫 인증 1km에 거북이 브론즈로 시작하고, 인증된 날마다 서버가 한 단계씩
/// 올린다. 이 화면은 기록을 만들지 않는다.
///
/// 가입 직후에는 앱이 `GoRouter` 없이 열려 있어서 여기서 달리기를 시작할 수 없다.
/// 그때는 "홈으로 가기"로 정상 홈에 보내고, 홈의 달리기 버튼으로 시작하게 한다.
class PreliminaryEvalScreen extends ConsumerWidget {
  const PreliminaryEvalScreen({super.key});

  static const startRunKey = Key('grade-start-run');
  static const goHomeKey = Key('grade-go-home');
  static const currentGradeKey = Key('grade-current');
  static const currentGradeAvatarKey = Key('grade-current-avatar');
  static const upgradeHowKey = Key('grade-upgrade-how');

  /// 가입 직후(GoRouter 없음)에 정상 홈으로 나간다. 뒤로 돌아올 곳을 남기지 않는다.
  void _goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.home,
      (route) => false,
    );
  }

  /// 이 화면 위에 돌아갈 화면이 없을 때(건너뛰기로 들어온 경우 등) 뒤로 가기는 앱을 끄지 않고
  /// 홈으로 보낸다.
  void _backToHome(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(RouteNames.home);
      return;
    }
    _goHome(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = Navigator.of(context).canPop() ||
        (GoRouter.maybeOf(context)?.canPop() ?? false);
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToHome(context);
      },
      child: _screen(context, ref),
    );
  }

  Widget _screen(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeUserProfileProvider).asData?.value;
    final hasRouter = GoRouter.maybeOf(context) != null;
    final guide = GradeGuide.of(Localizations.localeOf(context));
    final tier = UserTier.tryFromRankScore(profile?.gradeRank ?? 0);

    return Scaffold(
      backgroundColor: AppColors.nightBg,
      appBar: AppBar(
        backgroundColor: AppColors.nightBg,
        elevation: 0,
        foregroundColor: AppColors.nightInk,
        centerTitle: true,
        title: Text(
          guide.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (tier != null) ...[
                        // 등급이 이미 있는 사람: 지금 등급(동물 + 이름)을 먼저 보여 준다.
                        ChibiTierAvatar(
                          key: currentGradeAvatarKey,
                          tier: tier,
                          size: 96,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          guide.assigned(
                              tier.gradeTitle(Localizations.localeOf(context))),
                          key: currentGradeKey,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.nightInk,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 서버가 "다음 등급까지 남은 조건"을 내려 주지 않으므로 숫자 없이 규칙만 안내한다.
                        Text(
                          guide.upgradeHow,
                          key: upgradeHowKey,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.nightMuted,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ] else ...[
                        Text(
                          guide.intro,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.nightMuted,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          guide.progress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.nightInk,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        guide.sameDay,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.nightMuted,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!hasRouter) ...[
                Text(
                  guide.skipNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.nightMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: hasRouter ? startRunKey : goHomeKey,
                    onPressed: hasRouter
                        ? () => startRunWithPreflight(
                              context: context,
                              profile: profile,
                            )
                        : () => _goHome(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.nightLime,
                      foregroundColor: AppColors.nightOnLime,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasRouter ? guide.startRun : guide.goHome,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
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
