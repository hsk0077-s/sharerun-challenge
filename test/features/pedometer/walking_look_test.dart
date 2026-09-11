import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/walking_look.dart';

void main() {
  test('snail mascot uses the transparent running asset, not the white-plate PNG',
      () {
    expect(
      WalkingLook.mascotAsset(UserTier.unratedFallback),
      'assets/images/characters/chibi_snail_cute_gold_medal.png',
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
  });
}
