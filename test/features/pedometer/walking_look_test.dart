import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/walking_look.dart';

Offset _poseTranslation(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const Key('walking-mascot-pose')),
  );
  final translation = transform.transform.getTranslation();
  return Offset(translation.x, translation.y);
}

Future<void> _pumpMascot(
  WidgetTester tester, {
  bool moving = false,
  int pickupNonce = 0,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: SrcTheme.light,
      builder: disableAnimations
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: Scaffold(
        body: Center(
          child: WalkingMascot(
            tier: UserTier.unratedFallback,
            size: 80,
            moving: moving,
            pickupNonce: pickupNonce,
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('snail mascot uses the smiling derivative of the walking-challenge snail',
      () {
    expect(
      WalkingLook.mascotAsset(UserTier.unratedFallback),
      WalkingLook.snailWalkingAsset,
    );
    expect(
      WalkingLook.mascotAsset(UserTier.unratedFallback),
      'assets/images/characters/chibi_snail_smiling.png',
    );
    expect(
      WalkingLook.mascotAsset(UserTier.unratedFallback),
      isNot(contains('cute_gold_medal')),
    );
    expect(
      WalkingLook.mascotAsset(UserTier.unratedFallback),
      isNot(contains('disappointed')),
    );
  });

  test('harvest gold stays on the donation token', () {
    expect(WalkingLook.harvestLo, AppColors.angelGold);
    expect(
      WalkingLook.harvestGradient.colors,
      contains(AppColors.angelGold),
    );
  });

  testWidgets('WalkingHarvestCta keeps the harvest key and disabled wiring',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(
          body: WalkingHarvestCta(
            hasPendingCoins: false,
            pendingCoinsInt: 0,
            onPressed: null,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('walking-harvest-cta')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('코인 쌓이는 중...'), findsOneWidget);
  });

  testWidgets('WalkingMascot does not tint a square color band', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(
          body: WalkingMascot(
            tier: UserTier.unratedFallback,
            size: 80,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byKey(const Key('walking-mascot')));
    expect(image.color, isNull);
    expect(image.colorBlendMode, isNull);
    expect(
      find.descendant(
        of: find.byType(ColorFiltered),
        matching: find.byKey(const Key('walking-mascot')),
      ),
      findsOneWidget,
    );
    final filter = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
    expect(filter.colorFilter, WalkingLook.whitePlateKnockout);
  });

  testWidgets('WalkingMascot idles, then walks, then celebrates pickup',
      (tester) async {
    var moving = false;
    var pickupNonce = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WalkingMascot(
                      tier: UserTier.unratedFallback,
                      size: 80,
                      moving: moving,
                      pickupNonce: pickupNonce,
                    ),
                    TextButton(
                      onPressed: () => setState(() => moving = true),
                      child: const Text('walk'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => pickupNonce += 1),
                      child: const Text('pickup'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('walking-mascot-motion-idle')), findsOneWidget);
    expect(
      tester.widget<Image>(find.byKey(const Key('walking-mascot'))).image,
      const AssetImage(WalkingLook.snailWalkingAsset),
    );

    await tester.tap(find.text('walk'));
    await tester.pump();
    expect(
      find.byKey(const Key('walking-mascot-motion-walking')),
      findsOneWidget,
    );

    await tester.tap(find.text('pickup'));
    await tester.pump();
    expect(
      find.byKey(const Key('walking-mascot-motion-pickup')),
      findsOneWidget,
    );

    await tester.pump(WalkingMascot.pickupDuration);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const Key('walking-mascot-motion-pickup')), findsNothing);
    expect(
      find.byKey(const Key('walking-mascot-motion-walking')),
      findsOneWidget,
    );
    expect(
      tester.widget<Image>(find.byKey(const Key('walking-mascot'))).image,
      const AssetImage('assets/images/characters/chibi_snail_smiling.png'),
    );
  });

  test('evaluatePose idle / walk / pickup travel is large enough to see', () {
    const size = 80.0;
    final idle = WalkingMascot.evaluatePose(
      motion: WalkingMascotMotion.idle,
      size: size,
      loopValue: 1,
      loopReversing: false,
      pickupValue: 0,
    );
    final walk = WalkingMascot.evaluatePose(
      motion: WalkingMascotMotion.walking,
      size: size,
      loopValue: 1,
      loopReversing: false,
      pickupValue: 0,
    );
    final pickup = WalkingMascot.evaluatePose(
      motion: WalkingMascotMotion.pickup,
      size: size,
      loopValue: 0,
      loopReversing: false,
      pickupValue: 0.42,
    );

    expect(idle.lift, greaterThanOrEqualTo(size * 0.14));
    expect(idle.lift, closeTo(size * WalkingMascot.idleLiftFactor, 0.01));
    expect(walk.lift, greaterThan(idle.lift));
    expect(walk.lift, closeTo(size * WalkingMascot.walkLiftFactor, 0.01));
    final walkMid = WalkingMascot.evaluatePose(
      motion: WalkingMascotMotion.walking,
      size: size,
      loopValue: 0.5,
      loopReversing: false,
      pickupValue: 0,
    );
    expect(walkMid.slide.abs(), greaterThan(4));
    expect(pickup.lift, greaterThan(walk.lift));
    expect(pickup.lift, greaterThanOrEqualTo(size * 0.30));
    expect(pickup.sparkle, greaterThan(0));
  });

  testWidgets('WalkingMascot idle pose actually translates over time',
      (tester) async {
    await _pumpMascot(tester);
    await tester.pump();
    final start = _poseTranslation(tester);

    await tester.pump(WalkingMascot.idleLoopDuration ~/ 2);
    final mid = _poseTranslation(tester);

    expect(
      (mid - start).distance,
      greaterThan(6),
      reason: 'idle bob/sway must move more than a couple of pixels',
    );
    expect(mid.dy.abs(), greaterThan(4));
    expect(find.byKey(const Key('walking-mascot-motion-idle')), findsOneWidget);
  });

  testWidgets('WalkingMascot waddle translates while moving', (tester) async {
    await _pumpMascot(tester, moving: true);
    await tester.pump();
    final start = _poseTranslation(tester);

    await tester.pump(WalkingMascot.walkLoopDuration ~/ 2);
    final mid = _poseTranslation(tester);

    expect((mid - start).distance, greaterThan(8));
    expect(find.byKey(const Key('walking-mascot-motion-walking')), findsOneWidget);
  });

  testWidgets('WalkingMascot harvest hop lifts farther than idle',
      (tester) async {
    var pickupNonce = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WalkingMascot(
                      tier: UserTier.unratedFallback,
                      size: 80,
                      pickupNonce: pickupNonce,
                    ),
                    TextButton(
                      onPressed: () => setState(() => pickupNonce += 1),
                      child: const Text('pickup'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('pickup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final hop = _poseTranslation(tester);

    expect(
      find.byKey(const Key('walking-mascot-motion-pickup')),
      findsOneWidget,
    );
    expect(hop.dy.abs(), greaterThan(12));
  });

  testWidgets('WalkingMascot still moves when disableAnimations is on',
      (tester) async {
    await _pumpMascot(tester, moving: true, disableAnimations: true);
    await tester.pump();
    final start = _poseTranslation(tester);

    await tester.pump(WalkingMascot.walkLoopDuration ~/ 2);
    final mid = _poseTranslation(tester);

    expect(find.byKey(const Key('walking-mascot')), findsOneWidget);
    expect(
      find.byKey(const Key('walking-mascot-motion-walking')),
      findsOneWidget,
    );
    expect((mid - start).distance, greaterThan(8));
  });
}
