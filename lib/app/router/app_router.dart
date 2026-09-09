import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/login_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../providers/app_providers.dart';
import '../app_config.dart';
import 'auth_refresh_listenable.dart';
import 'main_shell_routes.dart';
import 'route_names.dart';

final sessionRefreshListenableProvider = Provider<SessionRefreshListenable>((ref) {
  final listenable = SessionRefreshListenable();
  ref.listen(authStateChangesProvider, (_, __) => listenable.refresh());
  ref.listen(activeUserProfileProvider, (_, __) => listenable.refresh());
  ref.onDispose(listenable.dispose);
  return listenable;
});

User? _resolveAuthUser(Ref ref) {
  final auth = ref.read(authStateChangesProvider);
  return auth.value ?? ref.read(firebaseAuthProvider).currentUser;
}

String? _authRedirect(Ref ref, GoRouterState state) {
  final path = state.uri.path;
  final onLogin = path == RouteNames.login;
  final onOnboarding = path == RouteNames.onboarding;
  // 온보딩·헬스 동의·워치 연동 중에는 로그인으로 튕기지 않음.
  final onWatchConnectFlow = path == RouteNames.watchSettings ||
      path == RouteNames.healthDataConsent ||
      path == RouteNames.smartWatchSync;

  final auth = ref.read(authStateChangesProvider);
  final persisted = ref.read(persistedAuthSessionProvider);
  final user = _resolveAuthUser(ref);

  if (auth.isLoading) {
    return null;
  }

  if (user == null && persisted == null) {
    if (onWatchConnectFlow) {
      // 세션 갱신 중 일시 null일 수 있음 — 강제 로그인 리다이렉트 금지.
      return null;
    }
    return onLogin ? null : RouteNames.login;
  }

  final isGuest = user?.isAnonymous == true || persisted?.isGuest == true;
  if (isGuest) {
    if (onLogin || onOnboarding) {
      return RouteNames.mainDashboard;
    }
    return null;
  }

  if (user == null && persisted != null) {
    if (onLogin || onOnboarding) {
      return RouteNames.mainDashboard;
    }
    return null;
  }

  final profile = ref.read(activeUserProfileProvider);
  if (profile.isLoading || profile.hasError) {
    return null;
  }

  final termsAccepted = profile.value?.termsAccepted ?? false;
  if (!termsAccepted) {
    if (onOnboarding || onWatchConnectFlow) {
      return null;
    }
    return RouteNames.onboarding;
  }

  if (onLogin || onOnboarding) {
    return RouteNames.mainDashboard;
  }
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConfig.initialRoute,
    refreshListenable: ref.watch(sessionRefreshListenableProvider),
    redirect: (context, state) => _authRedirect(ref, state),
    routes: [
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      ...buildMainShellAndDetailRoutes(),
    ],
  );
});
