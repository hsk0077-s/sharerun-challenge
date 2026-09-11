import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/features/pedometer/walking_look.dart';
import 'package:share_run_challenge/screens/solo_pedometer_screen.dart';
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

Widget _scopedWalking() {
  final profile = UserModel.dashboardDefault(uid: '');
  return ProviderScope(
    overrides: [
      needsNicknameSetupProvider.overrideWith((ref) => false),
      userNicknameProvider.overrideWith((ref) => '테스트워커'),
      activeUserProfileProvider.overrideWith(
        (ref) => Stream<UserModel>.value(profile),
      ),
      activeWalletProvider.overrideWith(
        (ref) => Stream<WalletModel>.value(_wallet),
      ),
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      activeUserTierProvider.overrideWith((ref) => Stream<int>.value(0)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SrcTheme.light,
      home: const SoloPedometerScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'is_pedometer_reset_v3_done': true,
    });
  });

  Future<void> pumpWalking(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_scopedWalking());
    await tester.pump();
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(WalkingLook.snailWalkingAsset),
        tester.element(find.byType(SoloPedometerScreen)),
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets(
      'Walking challenge uses SRC tokens, harvest CTA, SHARE, and step count',
      (tester) async {
    await pumpWalking(tester);

    expect(find.text('워킹챌린지'), findsOneWidget);
    expect(find.text('걸음'), findsOneWidget);
    expect(find.byKey(const Key('walking-step-count')), findsOneWidget);
    expect(find.text('코인 쌓이는 중...'), findsOneWidget);
    expect(find.textContaining('줍기 대기'), findsOneWidget);
    expect(find.text('90000 SHARE'), findsOneWidget);
    expect(find.text('내 누적 셰어 통장 🏦'), findsOneWidget);
    expect(find.textContaining('오늘의 채굴'), findsOneWidget);
    expect(find.text('이번 주 분석 일지'), findsOneWidget);
    expect(find.textContaining('산책 중'), findsOneWidget);
    expect(find.textContaining('워킹챌린지 혜택 알림'), findsOneWidget);
    expect(find.byType(SrcSurfaceCard), findsWidgets);

    final ctx = tester.element(find.text('워킹챌린지'));
    expect(ctx.srcTokens.colors.primary, AppColors.primaryMint);
    expect(ctx.srcTokens.colors.accent, AppColors.tealAccent);
    expect(ctx.srcTokens.colors.donation, AppColors.angelGold);
    expect(Theme.of(ctx).colorScheme.primary, AppColors.primaryMint);
    expect(Theme.of(ctx).colorScheme.secondary, AppColors.tealAccent);
    expect(Theme.of(ctx).colorScheme.tertiary, AppColors.angelGold);

    final harvest = tester.widget<FilledButton>(
      find.byKey(const Key('walking-harvest-cta')),
    );
    expect(harvest.onPressed, isNull);

    final harvestInk = tester.widget<Ink>(
      find.ancestor(
        of: find.byKey(const Key('walking-harvest-cta')),
        matching: find.byType(Ink),
      ),
    );
    final harvestColors =
        (harvestInk.decoration as BoxDecoration).gradient!.colors;
    expect(
      harvestColors.any(
        (color) =>
            (color.r - AppColors.angelGold.r).abs() < 0.01 &&
            (color.g - AppColors.angelGold.g).abs() < 0.01 &&
            (color.b - AppColors.angelGold.b).abs() < 0.01,
      ),
      isTrue,
    );

    final shareStyle = tester
        .widget<Text>(find.byKey(const Key('walking-share-balance')))
        .style;
    expect(shareStyle?.color, AppColors.tealAccent);
    expect(shareStyle?.fontSize, greaterThanOrEqualTo(32));

    final stepStyle =
        tester.widget<Text>(find.byKey(const Key('walking-step-count'))).style;
    expect(stepStyle?.fontSize, greaterThanOrEqualTo(64));
    expect(stepStyle?.color, WalkingLook.onHero);

    final mascot = tester.widget<Image>(find.byKey(const Key('walking-mascot')));
    expect(mascot.color, isNull);
    expect(mascot.colorBlendMode, isNull);
    expect(
      mascot.image,
      const AssetImage(WalkingLook.snailWalkingAsset),
    );
  });

  testWidgets('benefit notification toggle stays on the walking screen',
      (tester) async {
    await pumpWalking(tester);

    expect(find.text('알림 해지'), findsOneWidget);
    await tester.tap(find.text('알림 해지'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('꺼져 있습니다'), findsOneWidget);
    expect(find.text('알림 받기'), findsOneWidget);
    expect(find.text('워킹챌린지'), findsOneWidget);
    expect(find.byKey(const Key('walking-harvest-cta')), findsOneWidget);
  });

  testWidgets('SrcSurfaceCard color override uses the donation fill',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: Scaffold(
          body: SrcSurfaceCard(
            color: SrcTokens.light.colors.donation.withValues(alpha: 0.12),
            child: const Text('tinted'),
          ),
        ),
      ),
    );

    final card = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(SrcSurfaceCard),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    expect(
      (card.decoration as BoxDecoration).color,
      AppColors.angelGold.withValues(alpha: 0.12),
    );
  });

  testWidgets('Walking challenge golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_scopedWalking());
    await tester.pump();
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(WalkingLook.snailWalkingAsset),
        tester.element(find.byType(SoloPedometerScreen)),
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await expectLater(
      find.byType(SoloPedometerScreen),
      matchesGoldenFile('goldens/walking_challenge_tokens.png'),
    );
  });
}
