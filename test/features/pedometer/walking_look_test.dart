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

  testWidgets('WalkingMascot stays the static smiling snail (motion off)',
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

    expect(WalkingMascot.motionEnabled, isFalse);
    expect(find.byKey(const Key('walking-mascot-motion-static')), findsOneWidget);
    expect(
      tester.widget<Image>(find.byKey(const Key('walking-mascot'))).image,
      const AssetImage(WalkingLook.snailWalkingAsset),
    );

    await tester.tap(find.text('walk'));
    await tester.pump();
    expect(find.byKey(const Key('walking-mascot-motion-static')), findsOneWidget);
    expect(find.byKey(const Key('walking-mascot-motion-walking')), findsNothing);

    await tester.tap(find.text('pickup'));
    await tester.pump();
    expect(find.byKey(const Key('walking-mascot-motion-static')), findsOneWidget);
    expect(find.byKey(const Key('walking-mascot-motion-pickup')), findsNothing);
    expect(
      tester.widget<Image>(find.byKey(const Key('walking-mascot'))).image,
      const AssetImage('assets/images/characters/chibi_snail_smiling.png'),
    );
  });

  test('evaluatePose is grounded while motion is disabled', () {
    expect(WalkingMascot.motionEnabled, isFalse);
    const size = 80.0;
    for (final motion in WalkingMascotMotion.values) {
      final pose = WalkingMascot.evaluatePose(
        motion: motion,
        size: size,
        loopValue: 1,
        loopReversing: false,
        pickupValue: 0.42,
      );
      expect(pose.lift, 0);
      expect(pose.slide, 0);
      expect(pose.tilt, 0);
      expect(pose.scaleX, 1);
      expect(pose.scaleY, 1);
      expect(pose.sparkle, 0);
    }
  });

  testWidgets('WalkingMascot pose does not translate over time',
      (tester) async {
    await _pumpMascot(tester);
    await tester.pump();
    final start = _poseTranslation(tester);

    await tester.pump(WalkingMascot.idleLoopDuration ~/ 2);
    final mid = _poseTranslation(tester);

    expect((mid - start).distance, lessThan(0.5));
    expect(find.byKey(const Key('walking-mascot-motion-static')), findsOneWidget);
  });

  testWidgets('WalkingMascot stays static while moving flag is on',
      (tester) async {
    await _pumpMascot(tester, moving: true);
    await tester.pump();
    final start = _poseTranslation(tester);

    await tester.pump(WalkingMascot.walkLoopDuration ~/ 2);
    final mid = _poseTranslation(tester);

    expect((mid - start).distance, lessThan(0.5));
    expect(find.byKey(const Key('walking-mascot-motion-static')), findsOneWidget);
    expect(find.byKey(const Key('walking-mascot-motion-walking')), findsNothing);
  });

  testWidgets('WalkingMascot harvest hop is disabled', (tester) async {
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

    expect(find.byKey(const Key('walking-mascot-motion-static')), findsOneWidget);
    expect(find.byKey(const Key('walking-mascot-motion-pickup')), findsNothing);
    expect(hop.dy.abs(), lessThan(0.5));
  });

  testWidgets('WalkingMascot stays static when disableAnimations is on',
      (tester) async {
    await _pumpMascot(tester, moving: true, disableAnimations: true);
    await tester.pump();
    final start = _poseTranslation(tester);

    await tester.pump(WalkingMascot.walkLoopDuration ~/ 2);
    final mid = _poseTranslation(tester);

    expect(find.byKey(const Key('walking-mascot')), findsOneWidget);
    expect(find.byKey(const Key('walking-mascot-motion-static')), findsOneWidget);
    expect((mid - start).distance, lessThan(0.5));
  });
}
