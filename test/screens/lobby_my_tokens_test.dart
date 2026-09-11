import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/data/models/tournament_participation_model.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/tournaments/providers/local_joined_ids_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/challenge_lobby_screen.dart';
import 'package:share_run_challenge/screens/my_tournaments_screen.dart';
import 'package:share_run_challenge/screens/onboarding_my_page_screen.dart';
import 'package:share_run_challenge/screens/tournament_screen.dart';
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
      UserModel.dashboardDefault(uid: '').copyWith(nickname: '테스트러너');
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
      joinedTournamentParticipationsProvider.overrideWith(
        (ref) => Stream<List<TournamentParticipationModel>>.value(const []),
      ),
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

  Future<void> pumpSized(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(390, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_scopedApp(home: home));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets(
      'Lobby uses SRC tokens, Battle Pass, create room, and live tournament data',
      (tester) async {
    await pumpSized(tester, const ChallengeLobbyScreen());

    expect(find.text(AppStrings.lobbyTitle), findsOneWidget);
    expect(find.text(AppStrings.lobbyCreateRoom), findsOneWidget);
    expect(find.text(AppStrings.lobbyBattlePassCta), findsOneWidget);
    expect(find.text(AppStrings.lobbySponsorRoomTitle), findsOneWidget);
    expect(find.text(AppStrings.lobbyRoom1Title), findsOneWidget);
    expect(find.text(AppStrings.lobbyEnterRoom), findsWidgets);
    expect(find.text(AppStrings.lobbyGradeBlocked), findsOneWidget);
    expect(find.text('실시간 개설 · 참가 가능 방'), findsOneWidget);
    expect(find.text('Rookie 3K UNICEF Run'), findsOneWidget);
    expect(find.byKey(const Key('lobby-create-room')), findsOneWidget);
    expect(find.byKey(const Key('lobby-battle-pass')), findsOneWidget);
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    final ctx = tester.element(find.text(AppStrings.lobbyTitle));
    expect(ctx.srcTokens.colors.primary, AppColors.primaryMint);
    expect(ctx.srcTokens.colors.accent, AppColors.tealAccent);
    expect(ctx.srcTokens.colors.donation, AppColors.angelGold);
    expect(Theme.of(ctx).colorScheme.primary, AppColors.primaryMint);
    expect(Theme.of(ctx).colorScheme.secondary, AppColors.tealAccent);
    expect(Theme.of(ctx).colorScheme.tertiary, AppColors.angelGold);

    final create = tester.widget<OutlinedButton>(
      find.byKey(const Key('lobby-create-room')),
    );
    expect(create.onPressed, isNotNull);

    final battlePass = tester.widget<TextButton>(
      find.byKey(const Key('lobby-battle-pass')),
    );
    expect(battlePass.onPressed, isNotNull);
    expect(
      battlePass.style?.foregroundColor?.resolve(const <WidgetState>{}),
      AppColors.tealAccent,
    );

    final sponsorTitle = tester
        .widget<Text>(find.text(AppStrings.lobbySponsorRoomTitle))
        .style;
    expect(sponsorTitle?.color, AppColors.angelGold);
  });

  testWidgets(
      'Tournament list uses token cards, SHARE teal, VALUE gold, join CTA',
      (tester) async {
    await pumpSized(
      tester,
      const Scaffold(body: TournamentScreen()),
    );

    expect(find.text('Tournament Rooms'), findsOneWidget);
    expect(find.text('Rookie 3K UNICEF Run'), findsOneWidget);
    expect(find.text('Sponsor: UNICEF Partner'), findsOneWidget);
    expect(find.text('100 SHARE'), findsOneWidget);
    expect(find.textContaining('+500 밸류'), findsOneWidget);
    expect(find.text('Donation pool: 200 Value'), findsOneWidget);
    expect(find.text('Join with Share'), findsOneWidget);
    expect(find.textContaining('My Tournaments'), findsOneWidget);
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    final ctx = tester.element(find.text('Tournament Rooms'));
    expect(ctx.srcTokens.colors.primary, AppColors.primaryMint);
    expect(ctx.srcTokens.colors.accent, AppColors.tealAccent);
    expect(ctx.srcTokens.colors.donation, AppColors.angelGold);

    expect(
      tester.widget<Text>(find.text('100 SHARE')).style?.color,
      AppColors.tealAccent,
    );
    expect(
      tester.widget<Text>(find.textContaining('+500 밸류')).style?.color,
      AppColors.angelGold,
    );
    expect(
      tester.widget<Text>(find.text('Donation pool: 200 Value')).style?.color,
      AppColors.angelGold,
    );

    final join = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Join with Share'));
    expect(
      join.style?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.primaryMint,
    );
    expect(join.onPressed, isNull);
  });

  testWidgets('My page uses SRC tokens and keeps profile actions',
      (tester) async {
    await pumpSized(tester, const OnboardingMyPageScreen());

    expect(find.text(AppStrings.myPageTitle), findsWidgets);
    expect(find.text(AppStrings.myPageSettings), findsOneWidget);
    expect(find.text(AppStrings.myPageSubscriptionManage), findsOneWidget);
    expect(find.text('테스트러너'), findsOneWidget);
    expect(find.text('나의 천사 연대기'), findsOneWidget);
    expect(find.text('러닝 로그'), findsOneWidget);
    expect(find.text(AppStrings.myPageMonthlyDistanceValue), findsOneWidget);
    expect(find.byKey(const Key('my-page-settings')), findsOneWidget);
    expect(find.byKey(const Key('my-page-subscription')), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('my-page-settings')))
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('my-page-subscription')))
          .onTap,
      isNotNull,
    );
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    final ctx = tester.element(find.text(AppStrings.myPageTitle).first);
    expect(ctx.srcTokens.colors.primary, AppColors.primaryMint);
    expect(ctx.srcTokens.colors.accent, AppColors.tealAccent);
    expect(ctx.srcTokens.colors.donation, AppColors.angelGold);
    expect(Theme.of(ctx).colorScheme.tertiary, AppColors.angelGold);

    expect(
      tester
          .widget<Text>(find.text(AppStrings.myPageSubscriptionManage))
          .style
          ?.color,
      AppColors.tealAccent,
    );
    expect(
      tester
          .widget<Text>(find.text(AppStrings.myPageMonthlyDistanceValue))
          .style
          ?.color,
      AppColors.tealAccent,
    );
  });

  testWidgets('My Tournaments empty state uses SrcSurfaceCard', (tester) async {
    await pumpSized(
      tester,
      const Scaffold(body: MyTournamentsScreen()),
    );

    expect(find.text('My Tournaments'), findsOneWidget);
    expect(find.text('아직 참가한 대회가 없습니다.'), findsOneWidget);
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    final ctx = tester.element(find.text('My Tournaments'));
    expect(ctx.srcTokens.colors.primary, AppColors.primaryMint);
  });

  testWidgets('Lobby golden', (tester) async {
    await pumpSized(
      tester,
      const ChallengeLobbyScreen(),
      size: const Size(390, 844),
    );

    await expectLater(
      find.byType(ChallengeLobbyScreen),
      matchesGoldenFile('goldens/lobby_tokens.png'),
    );
  });

  testWidgets('Tournament list golden', (tester) async {
    await pumpSized(
      tester,
      const Scaffold(body: TournamentScreen()),
      size: const Size(390, 844),
    );

    await expectLater(
      find.byType(TournamentScreen),
      matchesGoldenFile('goldens/tournament_list_tokens.png'),
    );
  });

  testWidgets('My page golden', (tester) async {
    await pumpSized(
      tester,
      const OnboardingMyPageScreen(),
      size: const Size(390, 844),
    );

    await expectLater(
      find.byType(OnboardingMyPageScreen),
      matchesGoldenFile('goldens/my_page_tokens.png'),
    );
  });
}
