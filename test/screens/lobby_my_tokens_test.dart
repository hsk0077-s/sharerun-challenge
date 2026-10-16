import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/activity_model.dart';
import 'package:share_run_challenge/data/models/tournament_model.dart';
import 'package:share_run_challenge/data/models/tournament_participation_model.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/home/home_cards.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/account_daily_steps_provider.dart';
import 'package:share_run_challenge/features/pedometer/kst_calendar.dart';
import 'package:share_run_challenge/features/profile/my_page_activity_stats.dart';
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

Widget _scopedApp({
  required Widget home,
  List<ActivityModel> activities = const [],
  Map<String, int> stepsByDate = const {},
}) {
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
        (ref) => Stream.value(activities),
      ),
      accountDailyMetricsProvider.overrideWith(
        (ref) => Stream.value([
          for (final entry in stepsByDate.entries)
            AccountDayMetric(dayKey: entry.key, steps: entry.value),
        ]),
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
    List<ActivityModel> activities = const [],
    Map<String, int> stepsByDate = const {},
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _scopedApp(
        home: home,
        activities: activities,
        stepsByDate: stepsByDate,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets(
      'Lobby shows three top tabs, night tokens, Battle Pass, create room, and live tournament data',
      (tester) async {
    await pumpSized(tester, const ChallengeLobbyScreen());

    // 상단 탭 3개: 챌린지 · 대회 · 내 기록
    expect(find.byKey(const Key('lobby-top-tabs')), findsOneWidget);
    expect(find.text('챌린지'), findsWidgets);
    expect(find.text('대회'), findsOneWidget);
    expect(find.text('내 기록'), findsOneWidget);

    expect(find.text(AppStrings.lobbyCreateRoom), findsOneWidget);
    expect(find.text(AppStrings.lobbyBattlePassCta), findsOneWidget);
    expect(find.text(AppStrings.lobbySponsorRoomTitle), findsOneWidget);
    expect(find.text(AppStrings.lobbyRoom1Title), findsOneWidget);
    expect(find.text(AppStrings.lobbyRoom3Title), findsOneWidget);
    expect(find.text(AppStrings.lobbyRoom3Sub), findsOneWidget);
    expect(find.text(AppStrings.lobbyEnterRoom), findsWidgets);
    expect(find.textContaining('실버'), findsNothing);
    expect(find.text('하위 등급 차단'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    expect(find.text('실시간 개설 · 참가 가능 방'), findsOneWidget);
    expect(find.text('Rookie 3K UNICEF Run'), findsOneWidget);
    expect(find.byKey(const Key('lobby-create-room')), findsOneWidget);
    expect(find.byKey(const Key('lobby-battle-pass')), findsOneWidget);
    expect(find.byKey(const Key('lobby-sponsor-card')), findsOneWidget);
    // 맨 위 큰 카드가 1번, 목록은 2번부터 번호가 붙는다.
    expect(find.text('02'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('06'), findsNothing);

    // 챌린지 탭은 검정+라임 테마다.
    final ctx = tester.element(find.byKey(const Key('lobby-battle-pass')));
    expect(ctx.srcTokens.colors.primary, AppColors.nightLime);
    expect(ctx.srcTokens.colors.canvas, AppColors.nightBg);
    expect(Theme.of(ctx).colorScheme.primary, AppColors.nightLime);

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
      AppColors.nightLime,
    );

    final beginnerEnter = find.descendant(
      of: find.ancestor(
        of: find.text(AppStrings.lobbyRoom3Sub),
        matching: find.byType(Row),
      ).first,
      matching: find.text(AppStrings.lobbyEnterRoom),
    );
    expect(beginnerEnter, findsOneWidget);

    await tester.tap(beginnerEnter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('1km 초보 챌린지'), findsOneWidget);
    expect(find.text(AppStrings.challengeDetailTitle), findsNothing);
  });

  testWidgets(
      'Tournament list uses token cards, SHARE teal, VALUE gold, join CTA',
      (tester) async {
    await pumpSized(
      tester,
      const Scaffold(body: TournamentScreen()),
    );

    expect(find.text('대회 방'), findsOneWidget);
    expect(find.text('Rookie 3K UNICEF Run'), findsOneWidget);
    expect(find.text('후원  UNICEF Partner'), findsOneWidget);
    expect(find.text('100 SHARE'), findsOneWidget);
    expect(find.text('100 SHARE로 참가'), findsOneWidget);
    expect(find.text(AppStrings.winnerRewardNoConversion), findsOneWidget);
    expect(find.textContaining('+500 밸류'), findsNothing);
    expect(find.text('기부 풀: 200 VALUE'), findsOneWidget);
    expect(find.textContaining('내 대회'), findsOneWidget);

    final ctx = tester.element(find.text('대회 방'));
    expect(ctx.srcTokens.colors.primary, AppColors.primaryMint);
    expect(ctx.srcTokens.colors.accent, AppColors.tealAccent);
    expect(ctx.srcTokens.colors.donation, AppColors.angelGold);

    expect(
      tester.widget<Text>(find.text('100 SHARE')).style?.color,
      ctx.srcTokens.colors.primary,
    );
    expect(
      tester.widget<Text>(find.text(AppStrings.winnerRewardNoConversion)).style?.color,
      AppColors.angelGold,
    );
    expect(
      tester.widget<Text>(find.text('기부 풀: 200 VALUE')).style?.color,
      AppColors.angelGold,
    );

    final join = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '100 SHARE로 참가'));
    expect(
      join.style?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.primaryMint,
    );
    expect(join.onPressed, isNull);
  });

  testWidgets('My page shows village, identity, wallet chips and keeps actions',
      (tester) async {
    await pumpSized(tester, const OnboardingMyPageScreen());

    // 새 구성: 마을 풍경 + 원 세 개 + 잔액 칩 + 땀방울 게이지 + 바로가기 4칸
    expect(find.byKey(const Key('my-village-hero')), findsOneWidget);
    expect(find.text('MY VILLAGE'), findsOneWidget);
    expect(find.byKey(const Key('my-tier-animal')), findsOneWidget);
    expect(find.byKey(const Key('my-user-circle')), findsOneWidget);
    expect(find.byKey(const Key('my-tier-angel')), findsOneWidget);
    expect(find.text('테스트러너'), findsOneWidget);
    expect(find.text('프로필 꾸미기'), findsOneWidget);
    expect(find.text('천사 도감'), findsOneWidget);

    // 지갑 잔액은 마이 탭에 있다(홈에서 옮겨 옴).
    expect(find.byKey(const Key('my-chip-share')), findsOneWidget);
    expect(find.text('90,000'), findsOneWidget);
    expect(find.text('SHARE'), findsOneWidget);
    expect(find.text('DIAMOND'), findsOneWidget);
    expect(find.text('VALUE'), findsOneWidget);
    expect(find.text('5,200'), findsOneWidget);
    expect(find.text('오늘 모은 땀방울 1.5km / 5.0km (30%)'), findsOneWidget);
    expect(find.textContaining('채굴'), findsNothing);
    for (final label in ['내 지갑', '기부 정산', '티어 도감', '설정']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(HomeDiamondCard.toggleKey), findsOneWidget);

    // 설정·구독 관리 진입점은 그대로 있다.
    expect(find.byKey(const Key('my-page-settings')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('my-page-settings')))
          .onPressed,
      isNotNull,
    );
    expect(find.text(AppStrings.myPageSubscriptionManage), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('my-page-subscription')))
          .onTap,
      isNotNull,
    );

    // 아래 카드들은 그대로 이어진다.
    expect(find.text('나의 천사 연대기'), findsOneWidget);
    expect(find.text('🔥 0일째 불꽃 유지 중!'), findsOneWidget);
    expect(find.text('🔥 현재 연속 출석(Streak): 0일'), findsOneWidget);
    expect(find.text('러닝 로그'), findsOneWidget);
    expect(find.text('최근 러닝 기록이 없습니다'), findsOneWidget);
    expect(find.text('0.0 KM'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('42.5 KM'), findsNothing);
    expect(find.text('5:40 /KM'), findsNothing);
    expect(find.textContaining('12일'), findsNothing);
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    // 마이 탭은 검정+라임 테마다.
    final ctx = tester.element(find.byKey(const Key('my-tile-wallet')));
    expect(ctx.srcTokens.colors.primary, AppColors.nightLime);
    expect(ctx.srcTokens.colors.canvas, AppColors.nightBg);
    expect(Theme.of(ctx).colorScheme.primary, AppColors.nightLime);
    expect(
      tester
          .widget<Text>(find.text(AppStrings.myPageSubscriptionManage))
          .style
          ?.color,
      AppColors.nightLime,
    );
  });

  testWidgets('My page streak, log, and chart follow recorded activity',
      (tester) async {
    final today = KstCalendar.dateKey();
    SharedPreferences.setMockInitialValues({
      '${today}_steps': 2000,
      '${today}_km': 1.5,
    });
    final activities = [
      ActivityModel(
        id: 'run-today',
        userId: 'u',
        distanceKm: 3.2,
        durationSeconds: 960,
        averagePaceSecondsPerKm: 300,
        completedAt: DateTime.now(),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: null,
      ),
      ActivityModel(
        id: 'run-yesterday',
        userId: 'u',
        distanceKm: 2,
        durationSeconds: 700,
        averagePaceSecondsPerKm: 350,
        completedAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: null,
      ),
    ];
    final stats = MyPageActivityMath.compute(
      activities: activities,
      stepsByDate: {today: 2000},
      kmByDate: {today: 1.5},
      now: DateTime.now(),
    );
    expect(stats.streakDays, 2);

    await pumpSized(
      tester,
      const OnboardingMyPageScreen(),
      activities: activities,
    );

    expect(find.text('42.5 KM'), findsNothing);
    expect(find.textContaining('12일'), findsNothing);
    expect(
      find.text('🔥 ${stats.streakDays}일째 불꽃 유지 중!'),
      findsOneWidget,
    );
    expect(
      find.text('🔥 현재 연속 출석(Streak): ${stats.streakDays}일'),
      findsOneWidget,
    );
    expect(find.text(stats.monthDistanceLabel), findsOneWidget);
    expect(find.text(stats.paceLabel), findsOneWidget);
    expect(find.text('3.2 km'), findsOneWidget);
    expect(find.text('2.0 km'), findsOneWidget);
    expect(find.text('👑'), findsOneWidget);
  });

  testWidgets('My page log shows a walk when no run was saved that day',
      (tester) async {
    final today = KstCalendar.dateKey();

    await pumpSized(
      tester,
      const OnboardingMyPageScreen(),
      stepsByDate: {today: 2000},
    );
    await tester.pump();

    expect(find.text('걷기'), findsOneWidget);
    expect(find.text('1.5 km'), findsOneWidget);
    expect(find.text('1.5 KM'), findsOneWidget);
    expect(find.text('🔥 1일째 불꽃 유지 중!'), findsOneWidget);
    expect(find.text('🔥 현재 연속 출석(Streak): 1일'), findsOneWidget);
    expect(find.text('최근 러닝 기록이 없습니다'), findsNothing);
  });

  testWidgets('My Tournaments empty state uses SrcSurfaceCard', (tester) async {
    await pumpSized(
      tester,
      const Scaffold(body: MyTournamentsScreen()),
    );

    expect(find.text('내 대회'), findsOneWidget);
    expect(find.text('아직 참가한 대회가 없습니다.'), findsOneWidget);
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    final ctx = tester.element(find.text('내 대회'));
    expect(ctx.srcTokens.colors.primary, AppColors.primaryMint);
  });

  testWidgets('Lobby golden', (tester) async {
    await pumpSized(
      tester,
      const ChallengeLobbyScreen(),
      size: const Size(390, 844),
    );
    // 큰 사진이 늦게 읽혀 비교 이미지가 들쭉날쭉하지 않게 미리 읽어 둔다.
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/challenge_track.jpg'),
        tester.element(find.byType(ChallengeLobbyScreen)),
      );
    });
    await tester.pump();

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
    // 마을 그림과 원 안의 동물이 늦게 읽혀 비교 이미지가 들쭉날쭉하지 않게 미리 읽어 둔다.
    await tester.runAsync(() async {
      final context = tester.element(find.byType(OnboardingMyPageScreen));
      for (final name in [
        'tier_turtle',
        'tier_maltese',
        'tier_horse',
        'tier_cheetah',
        'chibi_snail_smiling',
        'chibi_pre_angel_bandaid',
        'avatar_gender_male',
      ]) {
        await precacheImage(
          AssetImage('assets/images/characters/$name.png'),
          context,
        );
      }
    });
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(OnboardingMyPageScreen),
      matchesGoldenFile('goldens/my_page_tokens.png'),
    );
  });
}
