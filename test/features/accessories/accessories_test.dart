import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/features/accessories/accessory_anchors.dart';
import 'package:share_run_challenge/features/accessories/accessory_catalog.dart';
import 'package:share_run_challenge/features/accessories/dressed_mascot.dart';
import 'package:share_run_challenge/features/accessories/try_on_sheet.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/screens/snail_to_cheetah_book_page.dart';

void main() {
  final dressable = TierAnimal.values.where(canDress).toList(growable: false);

  test('there are 12 accessories and every picture file exists', () {
    expect(Accessory.values, hasLength(12));
    for (final animal in dressable) {
      for (final acc in Accessory.values) {
        expect(
          File(acc.assetPath(animal)).existsSync(),
          isTrue,
          reason: '${acc.name} for ${animal.code}',
        );
      }
      expect(
        File('assets/images/accessories/fist/fist-front-${animal.code}.png')
            .existsSync(),
        isTrue,
      );
    }
  });

  test('every animal has a position for every item that needs one', () {
    final placed = Accessory.values.where((a) => !a.perAnimal).toList();
    expect(placed, hasLength(10));
    for (final animal in dressable) {
      final anchors = accessoryAnchors[animal]!;
      for (final acc in placed) {
        final a = anchors[acc];
        expect(a, isNotNull, reason: '${acc.name} for ${animal.code}');
        expect(a!.scale, inInclusiveRange(0.1, 1.5));
      }
    }
    expect(accessoryAnchors.containsKey(TierAnimal.snail), isFalse);
    expect(canDress(TierAnimal.snail), isFalse);
  });

  test('wearing something replaces the item in the same slot', () {
    var worn = <Accessory>{};
    worn = toggleAccessory(worn, Accessory.cap);
    worn = toggleAccessory(worn, Accessory.trophy);
    expect(worn, {Accessory.cap, Accessory.trophy});
    // 모자 → 머리띠: 머리 칸은 하나만.
    worn = toggleAccessory(worn, Accessory.headband);
    expect(worn, {Accessory.headband, Accessory.trophy});
    // 선글라스와 안경도 눈 칸 하나.
    worn = toggleAccessory(worn, Accessory.aviator);
    worn = toggleAccessory(worn, Accessory.roundGlasses);
    expect(worn.where((a) => a.slot == AccessorySlot.eyes), [
      Accessory.roundGlasses,
    ]);
    // 입은 것을 다시 누르면 벗는다.
    worn = toggleAccessory(worn, Accessory.trophy);
    expect(worn.contains(Accessory.trophy), isFalse);
  });

  test('placement keeps the item centre where the art guide puts it', () {
    // 돌리지 않은 소품: 왼쪽 위가 (x, y), 한 변이 512×scale.
    const flat = AccessoryAnchor(scale: 0.5, rotateDeg: 0, x: 100, y: 200);
    final p = DressedMascot.placement(flat, 1);
    expect(p.rect.left, closeTo(100, 0.001));
    expect(p.rect.top, closeTo(200, 0.001));
    expect(p.rect.width, closeTo(256, 0.001));
    expect(p.angle, 0);
    // 화면 크기를 반으로 줄이면 모든 값이 반이 된다.
    final half = DressedMascot.placement(flat, 0.5);
    expect(half.rect.left, closeTo(50, 0.001));
    expect(half.rect.width, closeTo(128, 0.001));
    // 15도 돌린 소품: 돌려서 커진 네모의 왼쪽 위가 (x, y)이고 방향은 반시계.
    const turned = AccessoryAnchor(scale: 0.36, rotateDeg: -15, x: 553, y: 128);
    final t = DressedMascot.placement(turned, 1);
    expect(t.angle, closeTo(15 * 3.141592653589793 / 180, 1e-9));
    final side = 512 * 0.36;
    final grown = side * (0.9659258 + 0.2588190);
    expect(t.rect.center.dx, closeTo(553 + grown / 2, 0.01));
    expect(t.rect.center.dy, closeTo(128 + grown / 2, 0.01));
  });

  Future<void> pumpMascot(WidgetTester tester, Set<Accessory> worn) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: DressedMascot(
            animal: TierAnimal.wolf,
            worn: worn,
            size: 300,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the mascot draws the body plus each worn item', (tester) async {
    await pumpMascot(tester, {});
    expect(find.byType(Image), findsOneWidget);

    await pumpMascot(tester, {Accessory.cap, Accessory.cape});
    expect(find.byType(Image), findsNWidgets(3));

    // 손에 드는 소품은 주먹 그림이 하나 더 붙는다.
    await pumpMascot(tester, {Accessory.trophy});
    expect(find.byType(Image), findsNWidgets(3));

    // 운동화·손목밴드는 판 전체 그림이라 같은 크기로 겹친다.
    await pumpMascot(tester, {Accessory.shoes, Accessory.wristband});
    final size = tester.getSize(find.byKey(const Key('dressed-mascot-wolf')));
    expect(size, const Size(300, 300));
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('the book opens the try-on sheet; the snail does not',
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

    expect(find.byKey(const Key('tier-book-try-on-snail')), findsNothing);
    final wolf = find.byKey(const Key('tier-book-try-on-wolf'));
    expect(wolf, findsOneWidget);
    await tester.tap(wolf);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('구경용이에요. 저장되거나 구매되지 않아요.'), findsOneWidget);
    expect(find.byKey(const Key('dressed-mascot-wolf')), findsOneWidget);

    final before = tester.widgetList<Image>(find.byType(Image)).length;
    await tester.tap(find.byKey(TryOnSheet.chipKey(Accessory.cap)));
    await tester.pump();
    expect(
      tester.widgetList<Image>(find.byType(Image)).length,
      before + 1,
    );
    // 머리띠로 바꾸면 그림 수는 그대로.
    await tester.tap(find.byKey(TryOnSheet.chipKey(Accessory.headband)));
    await tester.pump();
    expect(
      tester.widgetList<Image>(find.byType(Image)).length,
      before + 1,
    );
    await tester.tap(find.byKey(const Key('try-on-clear')));
    await tester.pump();
    expect(tester.widgetList<Image>(find.byType(Image)).length, before);
  });
}
