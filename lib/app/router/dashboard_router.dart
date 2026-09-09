import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_shell_routes.dart';
import 'route_names.dart';

/// In-app navigation after login — no Firebase Auth redirects.
/// [keepAlive] prevents GoRouter from being recreated when the app resumes
/// from Health Connect (avoids resetting to [RouteNames.mainDashboard]).
final dashboardRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();

  final router = GoRouter(
    initialLocation: RouteNames.mainDashboard,
    routes: buildMainShellAndDetailRoutes(),
  );

  ref.onDispose(router.dispose);
  return router;
});
