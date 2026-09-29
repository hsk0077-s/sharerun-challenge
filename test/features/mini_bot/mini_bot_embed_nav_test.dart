import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/src_bottom_nav.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_sheet.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/challenge_lobby_screen.dart';
import 'package:share_run_challenge/screens/main_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 90000,
  diamondBalance: 5,
  valueTokenBalance: 5200,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

Widget _scope({required Widget child}) {
  final profile =
      UserModel.dashboardDefault(uid: 'test-home').copyWith(nickname: '테스트러너');
  return ProviderScope(
    overrides: [
      needsNicknameSetupProvider.overrideWith((ref) => false),
      userNicknameProvider.overrideWith((ref) => '테스트러너'),
      activeUserProfileProvider.overrideWith(
        (ref) => Stream<UserModel>.value(profile),
      ),
      activeWalletProvider.overrideWith(
        (ref) => Stream<WalletModel>.value(_wallet),
      ),
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      recentActivitiesProvider.overrideWith((ref) => Stream.value(const [])),
      tournamentRoomsProvider.overrideWith(
        (ref) => Stream<List<TournamentModel>>.value(const []),
      ),
      activeUserTierProvider.overrideWith((ref) => Stream<int>.value(1)),
      retentionDailyKmProvider.overrideWith((ref) => 1.5),
    ],
    child: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('embedNav home and lobby each show one mic', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const MainDashboardScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('mini-bot-entry-home')), findsOneWidget);
    expect(find.byType(MiniBotEntryButton), findsOneWidget);

    await tester.pumpWidget(
      _scope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const ChallengeLobbyScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('mini-bot-entry-lobby')), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-entry-home')), findsNothing);
    expect(find.byType(MiniBotEntryButton), findsOneWidget);
  });

  testWidgets('shell shows a single mic on home and lobby', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: RouteNames.mainDashboard,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return SrcBottomNav(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.mainDashboard,
                  builder: (context, state) => const MainDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.shop,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.tournament,
                  builder: (context, state) => const ChallengeLobbyScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.crew,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.myPage,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _scope(
        child: MaterialApp.router(
          theme: SrcTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('mini-bot-entry-home')), findsOneWidget);
    expect(find.byType(MiniBotEntryButton), findsOneWidget);

    router.go(RouteNames.tournament);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mini-bot-entry-lobby')), findsOneWidget);
    expect(find.byKey(const Key('mini-bot-entry-home')), findsNothing);
    expect(find.byType(MiniBotEntryButton), findsOneWidget);

    router.go(RouteNames.shop);
    await tester.pumpAndSettle();

    expect(find.byType(MiniBotEntryButton), findsNothing);
  });
}
