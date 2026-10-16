import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/onboarding/widgets/chibi_tier_avatar.dart';
import 'package:share_run_challenge/features/pedometer/walking_look.dart';
import 'package:share_run_challenge/features/profile/avatar_choice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the five tier animals are turtle, beagle, wolf, zebra, cheetah', () {
    expect(
      UserTier.rankedAnimals.map((a) => a.code),
      ['turtle', 'beagle', 'wolf', 'zebra', 'cheetah'],
    );
    expect(
      UserTier.rankedAnimals.map((a) => a.labelKo),
      ['거북이', '비글', '늑대', '얼룩말', '치타'],
    );
    expect(UserTier.tryFromRankScore(6)?.animal, TierAnimal.beagle);
    expect(UserTier.tryFromRankScore(16)?.animal, TierAnimal.zebra);
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
    expect(AvatarPresets.byId('rabbit').id, 'beagle');
    expect(AvatarPresets.byId('gazelle').id, 'zebra');
    expect(AvatarPresets.byId('beagle').label, '비글');
    expect(AvatarPresets.byId('zebra').label, '얼룩말');
  });

  testWidgets('no mascot is mirrored on the walking track: the snail PNG faces right too',
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
    expect(mirrored(tester), isFalse);

    await pump(const UserTier(animal: TierAnimal.cheetah, medal: TierMedal.gold));
    expect(mirrored(tester), isFalse);
  });
}
