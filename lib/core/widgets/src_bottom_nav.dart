import '../navigation/open_popup_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/mini_bot/mini_bot_sheet.dart';
import '../../features/profile/providers/practice_streak_provider.dart';
import '../theme/app_colors.dart';
import 'email_verification_banner.dart';
import 'src_dashboard_bottom_nav.dart';
import 'src_exit_guard.dart';

/// 메인 5대 탭 셸 — 상태 보존(indexedStack) + 루트 더블 백 종료 가드.
class SrcBottomNav extends ConsumerWidget {
  const SrcBottomNav({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = navigationShell;
    ref.watch(practiceStreakProvider);
    ref.listen<PracticeStreakState>(practiceStreakProvider, (prev, next) {
      if (!next.diaRewardPending) return;
      if (prev?.diaRewardPending == true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('+10 Dia 획득!')),
      );
      ref.read(practiceStreakProvider.notifier).consumeDiaReward();
    });

    // 홈은 새 디자인(검정 바탕)이라 위아래 여백도 같은 색으로 맞춘다.
    // 다른 탭은 아직 옛 디자인이라 밝은 바탕 위에 검정 알약 바만 떠 있다.
    final onHome = shell.currentIndex == 0;
    return SrcExitGuard(
      navigationShell: shell,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (onHome ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: onHome ? AppColors.nightBg : null,
          body: SafeArea(
            child: Column(
              children: [
                const EmailVerificationBanner(),
                Expanded(child: shell),
              ],
            ),
          ),
          floatingActionButton: miniBotEntryForTab(shell.currentIndex),
          bottomNavigationBar: ColoredBox(
            color: onHome
                ? AppColors.nightBg
                : Theme.of(context).scaffoldBackgroundColor,
            child: DashboardBottomNav(
              currentIndex: shell.currentIndex,
              onTap: (index) {
                // 열려 있던 창은 탭을 옮기기 전에 닫는다.
                OpenPopupTracker.closeAll();
                shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
