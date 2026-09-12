import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/currency_badge.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/features/tournaments/providers/local_joined_ids_provider.dart';
import 'package:share_run_challenge/screens/home_screen.dart';
import 'package:share_run_challenge/screens/main_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 90000,
  diamondBalance: 5,
  valueTokenBalance: 5200,
  totalDonationValue: 0,
);

const _room = TournamentModel(
  id: 'rookie-3k',
  title: 'Rookie 3K UNICEF Run',
  targetDistanceKm: 3,
  entryFeeShare: 100,
  winnerRewardValue: 500,
  donationValue: 200,
  minParticipantsBep: 10,
  maxParticipants: 100,
  participantCount: 4,
  requiredTier: 1,
  status: TournamentStatus.recruiting,
  sponsorName: 'UNICEF Partner',
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

Widget _scopedApp({required Widget home}) {
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
      recentActivitiesProvider.overrideWith(
        (ref) => Stream.value(const []),
      ),
      tournamentRoomsProvider.overrideWith(
        (ref) => Stream<List<TournamentModel>>.value(const [_room]),
      ),
      activeUserTierProvider.overrideWith((ref) => Stream<int>.value(1)),
      effectiveJoinedTournamentIdsProvider.overrideWith((ref) => <String>{}),
      retentionDailyKmProvider.overrideWith((ref) => 1.5),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: home,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Home START uses mint ColorScheme and still shows SHARE/DIA/VALUE',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_scopedApp(home: const Scaffold(body: HomeScreen())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('START'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Diamond'), findsOneWidget);
    expect(find.text('Value'), findsOneWidget);
    expect(find.text('90000'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('5200'), findsOneWidget);
    expect(find.textContaining('DEBUG Jena:'), findsOneWidget);
    expect(find.byKey(const Key('home-start-cta')), findsOneWidget);

    final start = tester.widget<FilledButton>(
      find.byKey(const Key('home-start-cta')),
    );
    expect(start.style?.backgroundColor?.resolve(const <WidgetState>{}),
        AppColors.primaryMint);
    expect(start.style?.foregroundColor?.resolve(const <WidgetState>{}),
        AppColors.textWhite);

    final shareBadge = tester.widget<CurrencyBadge>(
      find.ancestor(
        of: find.text('Share'),
        matching: find.byType(CurrencyBadge),
      ),
    );
    expect(shareBadge.color, AppColors.tealAccent);
    expect(shareBadge.amount, 90000);

    final valueBadge = tester.widget<CurrencyBadge>(
      find.ancestor(
        of: find.text('Value'),
        matching: find.byType(CurrencyBadge),
      ),
    );
    expect(valueBadge.color, AppColors.angelGold);
    expect(valueBadge.amount, 5200);

    expect(find.byType(SrcSurfaceCard), findsWidgets);
  });

  testWidgets('live Home tab paints token wallet colors and challenge CTAs',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scopedApp(home: const MainDashboardScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('나의 지갑'), findsOneWidget);
    expect(find.textContaining('보유 SHARE: 90,000'), findsOneWidget);
    expect(find.textContaining('보유 다이아몬드: 5개'), findsOneWidget);
    expect(find.textContaining('보유 밸류(VALUE): 5,200'), findsOneWidget);
    expect(find.text('방 상세 보기'), findsNWidgets(2));
    expect(find.text('워킹 챌린지 시작'), findsOneWidget);
    expect(find.textContaining('내 이름으로 달리기 후원하기'), findsOneWidget);
    expect(find.text(AppStrings.dashboardChallenge1Sub), findsOneWidget);
    expect(find.text(AppStrings.dashboardChallenge2Sub), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    final shareStyle = tester
        .widget<Text>(
          find.textContaining('보유 SHARE: 90,000'),
        )
        .style;
    expect(shareStyle?.color, AppColors.tealAccent);

    final valueStyle = tester
        .widget<Text>(
          find.textContaining('보유 밸류(VALUE): 5,200'),
        )
        .style;
    expect(valueStyle?.color, AppColors.angelGold);
  });

  testWidgets('Home avatar sheet offers presets and gallery, not only gender',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scopedApp(home: const MainDashboardScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('home-header-avatar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text(AppStrings.avatarCustomizeTitle), findsOneWidget);
    expect(find.byKey(const Key('avatar-preset-snail')), findsOneWidget);
    expect(find.byKey(const Key('avatar-preset-cheetah')), findsOneWidget);
    expect(find.byKey(const Key('avatar-pick-gallery')), findsOneWidget);

    await tester.tap(find.byKey(const Key('avatar-preset-snail')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(AppStrings.avatarCustomizeTitle), findsNothing);
  });

  testWidgets('Home START golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_scopedApp(home: const Scaffold(body: HomeScreen())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen_tokens.png'),
    );
  });

  testWidgets('live Home tab golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scopedApp(home: const MainDashboardScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await expectLater(
      find.byType(MainDashboardScreen),
      matchesGoldenFile('goldens/home_dashboard_tokens.png'),
    );
  });
}
