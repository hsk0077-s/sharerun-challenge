import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/screens/preliminary_eval_screen.dart';
import 'package:share_run_challenge/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/ko_localization.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('settings: tapping the animal tier row opens the grade guide with a start button',
      (tester) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserModel.dashboardDefault(uid: 'u1');
    final router = GoRouter(
      initialLocation: RouteNames.settings,
      routes: [
        GoRoute(
          path: RouteNames.settings,
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.preliminaryEval,
          builder: (_, __) => const PreliminaryEvalScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserProfileProvider.overrideWith(
            (ref) => Stream<UserModel>.value(profile),
          ),
        ],
        child: MaterialApp.router(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final row = find.byKey(const Key('settings-tier-row'));
    await tester.scrollUntilVisible(row, 200,
        scrollable: find.byType(Scrollable).first);
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.arrow_forward_rounded)),
      findsOneWidget,
      reason: 'the row shows the same arrow as the other rows',
    );

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(PreliminaryEvalScreen), findsOneWidget);
    // Opened inside GoRouter, so the run can start right here.
    expect(find.byKey(PreliminaryEvalScreen.startRunKey), findsOneWidget);
  });
}
