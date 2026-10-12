import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/screens/snail_to_cheetah_book_page.dart';

void main() {
  test('each tier is drawn a little larger than the one before', () {
    final order = [
      TierAnimal.snail,
      ...UserTier.rankedAnimals,
    ];
    for (var i = 1; i < order.length; i++) {
      expect(
        TierBookScale.of(order[i]),
        greaterThan(TierBookScale.of(order[i - 1])),
        reason: '${order[i].code} should be larger than ${order[i - 1].code}',
      );
    }
    // 폰에서 보이게 한 단계에 4%보다 크게, 그래도 한 단계 10%는 넘지 않게.
    expect(TierBookScale.of(TierAnimal.turtle), 1.0);
    for (var i = 1; i < order.length; i++) {
      final step = TierBookScale.of(order[i]) - TierBookScale.of(order[i - 1]);
      expect(step, inInclusiveRange(0.05, 0.10), reason: order[i].code);
    }
  });

  testWidgets('the book draws bigger animals in the same slot height',
      (tester) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: SnailToCheetahBookPage()),
      ),
    );
    await tester.pump();

    double drawnHeight(TierAnimal a) {
      final slot = find.byKey(Key('tier-book-mascot-${a.code}')).first;
      return tester
          .getSize(find.descendant(of: slot, matching: find.byType(Image)))
          .height;
    }

    double slotHeight(TierAnimal a) =>
        tester.getSize(find.byKey(Key('tier-book-mascot-${a.code}')).first).height;

    final animals = UserTier.rankedAnimals;
    for (var i = 1; i < animals.length; i++) {
      expect(drawnHeight(animals[i]), greaterThan(drawnHeight(animals[i - 1])));
    }
    // 칸 높이는 모두 같아서 줄이 흔들리지 않는다.
    final heights = {for (final a in animals) slotHeight(a)};
    expect(heights, hasLength(1));
  });
}
