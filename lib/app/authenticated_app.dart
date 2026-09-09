import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/src_theme.dart';
import 'router/dashboard_router.dart';
import '../features/pedometer/solo_pedometer_foreground.dart';

/// Dashboard shell (tabs + sub-routes) shown after local guest login.
///
/// Holds a single [GoRouter] instance so Health Connect permission UI
/// (background/resume) does not recreate the router and jump back to /home.
class AuthenticatedApp extends ConsumerStatefulWidget {
  const AuthenticatedApp({super.key});

  @override
  ConsumerState<AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends ConsumerState<AuthenticatedApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(dashboardRouterProvider);
    SoloPedometerForeground.attachRouter(_router);
  }

  @override
  void dispose() {
    SoloPedometerForeground.attachRouter(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // Light SRC theme — do NOT use AppTheme.dark (black neon) post-login.
      theme: SrcTheme.light,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router!,
    );
  }
}
