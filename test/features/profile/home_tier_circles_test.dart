import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/features/profile/widgets/gender_profile_avatar.dart';
import 'package:share_run_challenge/features/profile/widgets/tier_circle_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  required UserTier tier,
  required AngelTier angel,
  double width = 280,
  List<String>? opened,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userNicknameProvider.overrideWith((ref) => '테스트러너'),
        activeUserTierStructProvider.overrideWith((ref) => tier),
        userAngelTierProvider.overrideWith((ref) => angel),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          opened?.add(settings.name ?? '');
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text('열림 ${settings.name}')),
          );
        },
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const HomeUserIdentityHeader(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('the circle size shrinks on narrow screens but stays in range', () {
    expect(HomeUserIdentityHeader.circleSize(280), 72);
    expect(HomeUserIdentityHeader.circleSize(232), closeTo(69.33, 0.01));
    expect(HomeUserIdentityHeader.circleSize(192), 56);
    expect(HomeUserIdentityHeader.circleSize(100), 48);
    expect(HomeUserIdentityHeader.circleSize(double.infinity), 72);
  });

  test('the names under the circles are short', () {
    const turtle = UserTier(animal: TierAnimal.turtle, medal: TierMedal.gold);
    expect(turtle.circleLabel, '거북이');
    expect(turtle.circleSubLabel, TierMedal.gold.labelKo);
    expect(UserTier.unratedFallback.circleLabel, '달팽이');
    expect(UserTier.unratedFallback.circleSubLabel, isNull);
    expect(AngelTier.preAngel.circleLabel, '예비 천사');
    expect(AngelTier.archangel.circleLabel, '대천사');
  });

  testWidgets(
      'the home header shows the photo, the animal tier and the angel '
      'tier as equal circles', (tester) async {
    await _pump(
      tester,
      tier: const UserTier(animal: TierAnimal.turtle, medal: TierMedal.gold),
      angel: AngelTier.archangel,
    );

    expect(find.text('거북이'), findsOneWidget);
    expect(find.text(TierMedal.gold.labelKo), findsOneWidget);
    expect(find.text('대천사'), findsOneWidget);
    // 예전 글자 칩은 없다.
    expect(find.textContaining('['), findsNothing);

    final photo = tester.getSize(find.byKey(const Key('home-header-avatar')));
    final animal = tester.getSize(
      find
          .descendant(
            of: find.byKey(const Key('home-tier-animal')),
            matching: find.byType(Container),
          )
          .first,
    );
    final angel = tester.getSize(
      find
          .descendant(
            of: find.byKey(const Key('home-tier-angel')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(animal, photo);
    expect(angel, photo);
    expect(photo.width, 72);
  });

  testWidgets('a runner without a grade shows the snail and the pre-angel',
      (tester) async {
    await _pump(
      tester,
      tier: UserTier.unratedFallback,
      angel: AngelTier.preAngel,
    );
    expect(find.text('달팽이'), findsOneWidget);
    expect(find.text('예비 천사'), findsOneWidget);
    expect(find.textContaining('Pre-Angel'), findsNothing);
  });

  testWidgets('it does not overflow on a narrow space', (tester) async {
    await _pump(
      tester,
      tier: const UserTier(animal: TierAnimal.maltese, medal: TierMedal.master),
      angel: AngelTier.seraphim,
      width: 190,
    );
    expect(tester.takeException(), isNull);
    final photo = tester.getSize(find.byKey(const Key('home-header-avatar')));
    expect(photo.width, lessThan(72));
    expect(photo.width, greaterThanOrEqualTo(48));
  });

  testWidgets('tapping each circle opens its own book', (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      tier: const UserTier(animal: TierAnimal.wolf, medal: TierMedal.silver),
      angel: AngelTier.guardian,
      opened: opened,
    );

    await tester.tap(find.byKey(const Key('home-tier-animal')));
    await tester.pumpAndSettle();
    expect(opened.last, RouteNames.tierBook);

    // 되돌아와서 천사 쪽도 누른다.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-tier-angel')));
    await tester.pumpAndSettle();
    expect(opened.last, RouteNames.angelBook);
  });
}
