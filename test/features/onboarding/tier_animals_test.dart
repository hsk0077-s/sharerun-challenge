import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/onboarding/widgets/chibi_tier_avatar.dart';
import 'package:share_run_challenge/features/pedometer/walking_look.dart';
import 'package:share_run_challenge/features/profile/avatar_choice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the five tier animals are turtle, maltese, wolf, horse, cheetah', () {
    expect(
      UserTier.rankedAnimals.map((a) => a.code),
      ['turtle', 'maltese', 'wolf', 'horse', 'cheetah'],
    );
    expect(
      UserTier.rankedAnimals.map((a) => a.labelKo),
      ['거북이', '몰티즈', '늑대', '말', '치타'],
    );
    expect(UserTier.tryFromRankScore(6)?.animal, TierAnimal.maltese);
    expect(UserTier.tryFromRankScore(16)?.animal, TierAnimal.horse);
    expect(UserTier.tryFromRankScore(1)?.firestoreCode, 'turtle_bronze');
    expect(UserTier.tryFromRankScore(11)?.firestoreCode, 'wolf_bronze');
  });

  test('every tier animal and the unrated snail has a picture in the app',
      () async {
    final tiers = [
      for (final animal in UserTier.rankedAnimals)
        UserTier(animal: animal, medal: TierMedal.gold),
      UserTier.unratedFallback,
    ];
    for (final tier in tiers) {
      final data = await rootBundle.load(tier.avatarAssetPath);
      expect(data.lengthInBytes, greaterThan(1000), reason: tier.avatarAssetPath);
    }
    expect(UserTier.unratedFallback.isSnail, isTrue);
  });

  testWidgets('a rated tier shows a medal badge, the unrated snail does not',
      (tester) async {
    Future<void> pump(UserTier tier) => tester.pumpWidget(
          MaterialApp(
            home: Center(child: ChibiTierAvatar(tier: tier, size: 120)),
          ),
        );

    await pump(const UserTier(animal: TierAnimal.wolf, medal: TierMedal.gold));
    expect(find.byKey(const Key('tier-medal-badge')), findsOneWidget);
    expect(find.bySemanticsLabel('골드'), findsWidgets);

    await pump(UserTier.unratedFallback);
    expect(find.byKey(const Key('tier-medal-badge')), findsNothing);
  });

  test('old saved avatar names still find the new animals', () {
    expect(AvatarPresets.byId('rabbit').id, 'maltese');
    expect(AvatarPresets.byId('gazelle').id, 'horse');
    expect(AvatarPresets.byId('maltese').label, '몰티즈');
    expect(AvatarPresets.byId('horse').label, '말');
  });

  testWidgets('only the left-facing snail is mirrored on the walking track',
      (tester) async {
    bool mirrored(WidgetTester t) {
      final transforms = t.widgetList<Transform>(
        find.ancestor(
          of: find.byKey(const Key('walking-mascot')),
          matching: find.byType(Transform),
        ),
      );
      return transforms.any((w) => w.transform.storage[0] < 0);
    }

    Future<void> pump(UserTier tier) => tester.pumpWidget(
          MaterialApp(
            home: Center(child: WalkingMascot(tier: tier, size: 96)),
          ),
        );

    await pump(UserTier.unratedFallback);
    expect(mirrored(tester), isTrue);

    await pump(const UserTier(animal: TierAnimal.cheetah, medal: TierMedal.gold));
    expect(mirrored(tester), isFalse);
  });
}
