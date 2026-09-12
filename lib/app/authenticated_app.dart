import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/src_theme.dart';
import '../features/pedometer/solo_pedometer_foreground.dart';
import '../features/pedometer/walking_step_keepalive.dart';
import '../screens/solo_pedometer_screen.dart';
import 'router/dashboard_router.dart';

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
  WalkingStepKeepAlive? _stepKeepAlive;

  @override
  void initState() {
    super.initState();
    _router = ref.read(dashboardRouterProvider);
    SoloPedometerForeground.attachRouter(_router);
    _stepKeepAlive = WalkingStepKeepAlive(
      onDaily: (steps, km) {
        unawaited(
          ref.read(pedometerStateProvider.notifier).updateSteps(
                steps,
                km,
                isMoving: false,
              ),
        );
      },
    );
    unawaited(_stepKeepAlive!.attach());
  }

  @override
  void dispose() {
    final keepAlive = _stepKeepAlive;
    _stepKeepAlive = null;
    if (keepAlive != null) unawaited(keepAlive.detach());
    SoloPedometerForeground.attachRouter(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: MaterialApp.router(
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
    ),
    );
  }
}
