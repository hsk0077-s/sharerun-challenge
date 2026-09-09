import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../features/profile/providers/practice_streak_provider.dart';
import '../strings/app_strings.dart';
import '../theme/app_colors.dart';
import 'email_verification_banner.dart';
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
    final myPageDot = ref.watch(hasPendingJenaAppealProvider);
    ref.watch(practiceStreakProvider);
    ref.listen<PracticeStreakState>(practiceStreakProvider, (prev, next) {
      if (!next.diaRewardPending) return;
      if (prev?.diaRewardPending == true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('+10 Dia 획득!')),
      );
      ref.read(practiceStreakProvider.notifier).consumeDiaReward();
    });

    return SrcExitGuard(
      navigationShell: shell,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const EmailVerificationBanner(),
              Expanded(child: shell),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: shell.currentIndex,
          onTap: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: AppStrings.dashboardNavHome,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_rounded),
              label: AppStrings.dashboardNavStore,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded),
              label: AppStrings.dashboardNavChallenge,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: AppStrings.dashboardNavCrew,
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: myPageDot,
                smallSize: 7,
                backgroundColor: AppColors.error,
                child: const Icon(Icons.person_rounded),
              ),
              label: AppStrings.dashboardNavMyPage,
            ),
          ],
        ),
      ),
    );
  }
}
