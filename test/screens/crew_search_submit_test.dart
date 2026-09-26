import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/src_theme.dart';
import 'package:share_run_challenge/core/widgets/src_bottom_nav.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/running_crew_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

  testWidgets('plain MaterialApp: crew search submit stays up', (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _submitQuery(tester, '서울');
    expect(find.text('검색: "서울"'), findsOneWidget);
    expect(find.text(AppStrings.runningCrewMyCrewName), findsWidgets);
    expect(find.text('강남 스피드 클럽'), findsNothing);
  });

  testWidgets('plain MaterialApp: keyboard submit stays up', (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '서울');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('검색: "서울"'), findsOneWidget);
    expect(find.text('강남 스피드 클럽'), findsNothing);
  });

  testWidgets(
      'nested MaterialApp like AuthenticatedApp: search submit stays up',
      (tester) async {
    await _pumpCrewTab(tester);
    await _submitQuery(tester, '서울');
    expect(find.text('검색: "서울"'), findsOneWidget);
  });

  testWidgets('dismissing the search dialog clears the crew filter',
      (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _submitQuery(tester, '서울');

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    expect(find.text('크루 검색'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('크루 검색'), findsNothing);
    expect(find.text('검색: "서울"'), findsNothing);
    expect(find.text('강남 스피드 클럽'), findsOneWidget);
    expect(find.text(AppStrings.runningCrewTitle), findsOneWidget);
  });

  testWidgets('back chevron clears crew search and restores the full list',
      (tester) async {
    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const RunningCrewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _submitQuery(tester, '서울');
    expect(find.text('강남 스피드 클럽'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('검색: "서울"'), findsNothing);
    expect(find.text('강남 스피드 클럽'), findsOneWidget);
    expect(find.text('부산 오션 러너스'), findsOneWidget);
    expect(find.text(AppStrings.runningCrewTitle), findsOneWidget);
  });

  testWidgets('system back on the crew tab clears search before leaving',
      (tester) async {
    await _pumpCrewTab(tester, home: const Text('HOME_ROOT'));
    await _submitQuery(tester, '서울');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('검색: "서울"'), findsNothing);
    expect(find.text('강남 스피드 클럽'), findsOneWidget);
    expect(find.text(AppStrings.runningCrewTitle), findsOneWidget);
    expect(find.text('HOME_ROOT'), findsNothing);
  });
}
