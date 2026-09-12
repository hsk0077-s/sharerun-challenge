import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/walking_look.dart';

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

  testWidgets('WalkingMascot stays still when animations are disabled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: WalkingMascot(
            tier: UserTier.unratedFallback,
            size: 80,
            moving: true,
            pickupNonce: 1,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('walking-mascot-motion-idle')), findsOneWidget);
    expect(find.byKey(const Key('walking-mascot')), findsOneWidget);
  });
}
