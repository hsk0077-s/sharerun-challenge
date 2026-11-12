import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/donation/today_donation.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/stamp/providers/stamp_tour_enabled_provider.dart';
import 'package:share_run_challenge/features/tournaments/providers/local_joined_ids_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/features/world_tour/widgets/world_tour_widgets.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_providers.dart';
import 'package:share_run_challenge/screens/main_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/ko_localization.dart';
import 'world_tour_support.dart';

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

/// The real first tab (the app redirects /home to it), with the providers it reads stubbed.
Widget _dashboardApp(FakeWorldTourApi api) {
  final profile =
      UserModel.dashboardDefault(uid: 'tour-test').copyWith(nickname: '테스트러너');
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const MainDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.worldTour,
        builder: (_, __) => const Scaffold(body: Text('tour-list-screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      worldTourApiProvider.overrideWithValue(api),
      stampTourEnabledProvider.overrideWith((ref) async => false),
      todayDonationLoaderProvider.overrideWithValue(
        () async => const TodayDonation(todayWon: 300, capReached: false),
      ),
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
      effectiveJoinedTournamentIdsProvider.overrideWith((ref) => <String>{}),
      retentionDailyKmProvider.overrideWith((ref) => 1.5),
    ],
    child: MaterialApp.router(
      locale: koTestLocale,
      supportedLocales: koTestSupportedLocales,
      localizationsDelegates: koTestDelegates,
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the real home tab (MainDashboardScreen) shows the World Tour entry card',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_dashboardApp(FakeWorldTourApi()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(WorldTourEntryCard.cardKey), findsOneWidget);
  });

  testWidgets('tapping the entry card opens the World Tour list route', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_dashboardApp(FakeWorldTourApi()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.ensureVisible(find.byKey(WorldTourEntryCard.cardKey));
    await tester.pump();
    await tester.tap(find.byKey(WorldTourEntryCard.cardKey));
    await tester.pumpAndSettle();

    expect(find.text('tour-list-screen'), findsOneWidget);
  });
}
