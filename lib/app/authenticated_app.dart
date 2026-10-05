import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/src_theme.dart';
import '../features/run_tracking/run_recording_foreground.dart';
import '../features/run_tracking/run_recording_policy.dart';
import '../features/pedometer/solo_pedometer_foreground.dart';
import '../features/pedometer/today_steps.dart';
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
      today: TodaySteps.instance,
      onDaily: (
        steps,
        km, {
        required String dayKey,
        required String source,
        int? lastHealth,
      }) {
        return ref.read(pedometerStateProvider.notifier).updateSteps(
              steps,
              km,
              isMoving: false,
              dayKey: dayKey,
              source: source,
              lastHealth: lastHealth,
            );
      },
    );
    unawaited(_bootBackgroundRun());
  }

  Future<void> _bootBackgroundRun() async {
    final interrupted = await RunRecordingForeground.consumeInterruptedRun();
    if (!mounted) return;
    await _stepKeepAlive!.attach();
    if (!mounted || !interrupted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(interruptedRunTitle),
          content: const Text(interruptedRunBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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
    // Nested inside ShareRunChallengeApp's MaterialApp. Without this, Android
    // treats an unhandled inner pop (HoF / sponsor as last page) as app exit
    // before those screens' PopScope can run. Delegate to the inner navigator
    // so tab SrcExitGuard is unchanged (#29).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final inner = _router?.routerDelegate.navigatorKey.currentState;
        if (inner != null && inner.mounted) {
          inner.maybePop();
        }
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: '쉐어 런',
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
