import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../navigation/dashboard_tab_navigation.dart';
import '../strings/app_strings.dart';

/// 메인 탭 루트 전용 뒤로가기 가드.
/// - 홈이 아닌 탭 루트 → 홈 탭으로 수렴
/// - 홈 탭 루트 → 2초 더블 백 종료
/// - 하위 상세(canPop) → 정상 pop (간섭 없음)
class SrcExitGuard extends StatefulWidget {
  const SrcExitGuard({
    required this.child,
    this.navigationShell,
    this.tabIndex = DashboardTabNavigation.home,
    super.key,
  });

  final Widget child;

  /// GoRouter [StatefulShellRoute] 셸 (있으면 우선 사용).
  final StatefulNavigationShell? navigationShell;

  /// Material 임베디드 탭 경로용 현재 탭 인덱스.
  final int tabIndex;

  @override
  State<SrcExitGuard> createState() => _SrcExitGuardState();
}

class _SrcExitGuardState extends State<SrcExitGuard> {
  DateTime? _lastBackAt;

  static const _exitGuardDuration = Duration(seconds: 2);

  int get _currentTabIndex =>
      widget.navigationShell?.currentIndex ?? widget.tabIndex;

  void _goHome() {
    final shell = widget.navigationShell;
    if (shell != null) {
      shell.goBranch(DashboardTabNavigation.home);
      return;
    }
    DashboardTabNavigation.go(context, DashboardTabNavigation.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final router = GoRouter.maybeOf(context);
        if (router != null && router.canPop()) {
          router.pop();
          return;
        }
        if (router == null && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        // 탭 수렴: 홈이 아니면 홈으로.
        if (_currentTabIndex != DashboardTabNavigation.home) {
          _lastBackAt = null;
          _goHome();
          return;
        }

        final now = DateTime.now();
        if (_lastBackAt != null &&
            now.difference(_lastBackAt!) <= _exitGuardDuration) {
          SystemNavigator.pop();
          return;
        }

        _lastBackAt = now;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(AppStrings.exitGuardMessage),
            duration: _exitGuardDuration,
          ),
        );
      },
      child: widget.child,
    );
  }
}
