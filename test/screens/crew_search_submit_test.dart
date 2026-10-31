import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/navigation/open_popup_tracker.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/features/crew/crew_emblem.dart';
import 'package:share_run_challenge/core/widgets/src_bottom_nav.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/running_crew_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/ko_localization.dart';

const _wallet = WalletModel(
  shareBalance: 90000,
  diamondBalance: 5,
  valueTokenBalance: 100,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

Widget _scope({required Widget child}) {
  return ProviderScope(
    overrides: [
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      recentActivitiesProvider.overrideWith((ref) => Stream.value(const [])),
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: child,
  );
}

Future<void> _pumpCrewTab(
  WidgetTester tester, {
  Widget home = const SizedBox.shrink(),
}) async {
  final router = GoRouter(
    observers: [OpenPopupTracker()],
    initialLocation: RouteNames.crew,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SrcBottomNav(navigationShell: navigationShell);
        },
        branches: [
          for (final (path, child) in <(String, Widget)>[
            (RouteNames.mainDashboard, home),
            (RouteNames.shop, const SizedBox.shrink()),
            (RouteNames.tournament, const SizedBox.shrink()),
            (RouteNames.crew, const RunningCrewScreen()),
            (RouteNames.myPage, const SizedBox.shrink()),
          ])
            StatefulShellBranch(
              observers: [OpenPopupTracker()],
              routes: [
                GoRoute(path: path, builder: (context, state) => child),
              ],
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    _scope(
      child: MaterialApp(
        locale: koTestLocale,
        supportedLocales: koTestSupportedLocales,
        localizationsDelegates: koTestDelegates,
        theme: SrcTheme.light,
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            final inner = router.routerDelegate.navigatorKey.currentState;
            if (inner != null && inner.mounted) {
              inner.maybePop();
            }
          },
          child: MaterialApp.router(
            locale: koTestLocale,
            supportedLocales: koTestSupportedLocales,
            localizationsDelegates: koTestDelegates,
            debugShowCheckedModeBanner: false,
            theme: SrcTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  router.go(RouteNames.crew);
  await tester.pumpAndSettle();
}

Future<void> _submitQuery(WidgetTester tester, String query) async {
  await tester.ensureVisible(find.byIcon(Icons.search_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.search_rounded));
  await tester.pumpAndSettle();
  expect(find.text('크루 검색'), findsOneWidget);

  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
  await tester.tap(find.text('검색'));
  await tester.pump();
  expect(tester.takeException(), isNull);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    OpenPopupTracker.resetForTest();
  });

  testWidgets('switching tabs with the picker open closes it', (tester) async {
    await _pumpCrewTab(tester, home: const Text('HOME_ROOT'));
    await tester.tap(find.byKey(const Key('crew-header-emblem')));
    await tester.pumpAndSettle();
    expect(find.byKey(CrewEmblemPicker.doneKey), findsOneWidget);

    await tester.tap(find.text('홈').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('크루').last);
    await tester.pumpAndSettle();

    expect(find.byKey(CrewEmblemPicker.doneKey), findsNothing);
    expect(find.text(AppStrings.runningCrewNoCrewName), findsOneWidget);
  });

  testWidgets('back closes the emblem picker first; the crew tab stays',
      (tester) async {
    await _pumpCrewTab(tester, home: const Text('HOME_ROOT'));
    await tester.tap(find.byKey(const Key('crew-header-emblem')));
    await tester.pumpAndSettle();
    expect(find.byKey(CrewEmblemPicker.doneKey), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(CrewEmblemPicker.doneKey), findsNothing);
    expect(find.text('HOME_ROOT').hitTestable(), findsNothing,
        reason: 'must not jump to home while a sheet was open');
    expect(find.text(AppStrings.runningCrewNoCrewName), findsOneWidget);

    // 창이 닫힌 뒤의 뒤로가기는 홈으로 간다.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);
  });

  testWidgets('plain MaterialApp: crew search submit stays up', (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _submitQuery(tester, '부산');
    expect(find.text('검색: "부산"'), findsOneWidget);
    // 내 크루만 있으므로 맞는 크루가 없으면 안내 문구가 나온다.
    expect(find.byKey(const Key('crew-search-result')), findsNothing);
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
  });

  testWidgets('plain MaterialApp: keyboard submit stays up', (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '부산');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('검색: "부산"'), findsOneWidget);
    expect(find.byKey(const Key('crew-search-result')), findsNothing);
  });

  testWidgets(
      'nested MaterialApp like AuthenticatedApp: search submit stays up',
      (tester) async {
    await _pumpCrewTab(tester);
    await _submitQuery(tester, '부산');
    expect(find.text('검색: "부산"'), findsOneWidget);
  });

  testWidgets('dismissing the search dialog clears the crew filter',
      (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _submitQuery(tester, '부산');

    await tester.ensureVisible(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    expect(find.text('크루 검색'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('크루 검색'), findsNothing);
    expect(find.text('검색: "부산"'), findsNothing);
    expect(find.text(AppStrings.runningCrewNoCrewName), findsOneWidget);
  });

  testWidgets('back chevron clears crew search and restores the full list',
      (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          locale: koTestLocale,
          supportedLocales: koTestSupportedLocales,
          localizationsDelegates: koTestDelegates,
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _submitQuery(tester, '부산');
    expect(find.byKey(const Key('crew-search-result')), findsNothing);

    await tester.ensureVisible(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('검색: "부산"'), findsNothing);
    expect(find.text(AppStrings.runningCrewNoCrewName), findsOneWidget);
  });

  testWidgets('system back on the crew tab clears search before leaving',
      (tester) async {
    await _pumpCrewTab(tester, home: const Text('HOME_ROOT'));
    await _submitQuery(tester, '부산');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('검색: "부산"'), findsNothing);
    expect(find.text(AppStrings.runningCrewNoCrewName), findsOneWidget);
    expect(find.text('HOME_ROOT'), findsNothing);
  });
}
