import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/features/accessories/accessory_catalog.dart';
import 'package:share_run_challenge/features/accessories/dressed_mascot.dart';
import 'package:share_run_challenge/features/accessories/try_on_sheet.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/screens/snail_to_cheetah_book_page.dart';

void main() {
  final dressable = TierAnimal.values.where(canDress).toList(growable: false);

  Accessory byId(String id) => accessoryCatalog.firstWhere((a) => a.id == id);

  test('the catalog has 46 items with unique ids', () {
    expect(accessoryCatalog, hasLength(46));
    expect(accessoryCatalog.map((a) => a.id).toSet(), hasLength(46));
    expect(
      accessoryCatalog.where((a) => a.slot == AccessorySlot.skin),
      hasLength(9),
    );
  });

  test('every ready picture exists for all five animals', () {
    for (final acc in accessoryCatalog.where((a) => a.ready)) {
      for (final animal in dressable) {
        expect(
          File(acc.assetPath(animal)).existsSync(),
          isTrue,
          reason: '${acc.id} ${acc.file} for ${animal.code}',
        );
        final front = acc.frontAssetPath(animal);
        if (front != null) {
          expect(File(front).existsSync(), isTrue, reason: front);
        }
      }
    }
  });

  test('the angel wings are held back until the art is fixed', () {
    final wings = byId('P047');
    expect(wings.ready, isFalse);
    expect(accessoriesIn(AccessorySlot.back).contains(wings), isFalse);
    expect(accessoriesIn(AccessorySlot.back), hasLength(2));
  });

  test('each slot lists what the designers delivered', () {
    final counts = {
      for (final s in AccessorySlot.values) s: accessoriesIn(s).length,
    };
    expect(counts, {
      AccessorySlot.back: 2,
      AccessorySlot.bottom: 2,
      AccessorySlot.top: 4,
      AccessorySlot.feet: 3,
      AccessorySlot.hand: 10,
      AccessorySlot.eyes: 5,
      AccessorySlot.head: 10,
      AccessorySlot.skin: 9,
    });
  });

  test('tier locks and price labels follow the catalog', () {
    final locked = accessoryCatalog.where((a) => a.tierLock != null).toList();
    expect(locked.map((a) => a.id), ['S001', 'S002', 'S003', 'S004', 'S009']);
    expect(byId('S004').tierLock, TierAnimal.cheetah);
    expect(byId('P001').priceLabel, '400 SHARE');
    expect(byId('P004').priceLabel, '40 DIA');
    expect(byId('P015').priceLabel, '티어 보상');
    // 임시였던 가격은 소유자가 그대로 확정했다.
    expect(accessoryCatalog.where((a) => a.provisional), isEmpty);
    expect(byId('STOPWATCH').priceLabel, '300 SHARE');
  });

  test('wearing something replaces the item in the same slot', () {
    final cap = byId('P001');
    final baton = byId('P030');
    var worn = <Accessory>{};
    worn = toggleAccessory(worn, cap);
    worn = toggleAccessory(worn, baton);
    expect(worn, {cap, baton});
    // 모자 → 머리띠: 머리 칸은 하나만.
    worn = toggleAccessory(worn, byId('P002'));
    expect(worn, {byId('P002'), baton});
    // 입은 것을 다시 누르면 벗는다.
    worn = toggleAccessory(worn, baton);
    expect(worn.contains(baton), isFalse);
  });

  test('a skin replaces everything and any item takes the skin off', () {
    final skin = byId('S005');
    var worn = toggleAccessory({byId('P001'), byId('P030')}, skin);
    expect(worn, {skin});
    worn = toggleAccessory(worn, byId('P022'));
    expect(worn, {byId('P022')});
  });

  Future<void> pumpMascot(WidgetTester tester, Set<Accessory> worn) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: DressedMascot(
            key: const Key('stage'),
            animal: TierAnimal.wolf,
            worn: worn,
            size: 300,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// 그려진 그림 파일 이름을 아래층부터 순서대로.
  List<String> layers(WidgetTester tester) => [
        for (final image in tester.widgetList<Image>(
          find.descendant(
            of: find.byKey(const Key('stage')),
            matching: find.byType(Image),
          ),
        ))
          ((image.image as ResizeImage).imageProvider as AssetImage)
              .assetName
              .split('/')
              .last,
      ];

  testWidgets('the mascot stacks the layers in the agreed order',
      (tester) async {
    await pumpMascot(tester, {});
    expect(layers(tester), ['tier_wolf.png']);

    await pumpMascot(tester, {
      byId('P001'),
      byId('P022'),
      byId('P030'),
      byId('P074'),
      byId('P059'),
      byId('P067'),
      byId('P046'),
    });
    expect(layers(tester), [
      'cape-wolf.webp',
      'tier_wolf.png',
      'P067-shorts-racing-pink-wolf.webp',
      'P059-singlet-lime-wolf.webp',
      'P074-shoes-neon-wolf.webp',
      'hand-baton-held-wolf.webp',
      'aviator-wolf.webp',
      'cap-wolf.webp',
    ]);
    expect(
      tester.getSize(find.byKey(const Key('stage'))),
      const Size(300, 300),
    );
  });

  testWidgets('the backpack strap goes over the top, a skin stands alone',
      (tester) async {
    await pumpMascot(tester, {byId('P045'), byId('P058')});
    expect(layers(tester), [
      'backpack-wolf.webp',
      'tier_wolf.png',
      'P058-tee-white-mesh-wolf.webp',
      'backpack-strap-wolf.webp',
    ]);

    await pumpMascot(tester, {byId('S003')});
    expect(layers(tester), ['S003-wolf-master-wolf.webp']);
  });

  testWidgets('wings that are held back are not drawn', (tester) async {
    await pumpMascot(tester, {byId('P047')});
    expect(layers(tester), ['tier_wolf.png']);
  });

  testWidgets('the book opens the try-on sheet; the snail does not',
      (tester) async {
    // 칸 버튼 8개가 한 줄에 다 보이도록 넉넉한 폭.
    tester.view.physicalSize = const Size(900, 3000);
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
    final stage = find.byKey(const Key('dressed-mascot-wolf'));
    expect(stage, findsOneWidget);
    int drawn() => tester
        .widgetList<Image>(
          find.descendant(of: stage, matching: find.byType(Image)),
        )
        .length;
    expect(drawn(), 1);

    // 머리 칸이 처음 열려 있다. 모자를 누르면 한 장, 머리띠로 바꾸면 그대로 한 장.
    await tester.tap(find.byKey(TryOnSheet.chipKey(byId('P001'))));
    await tester.pump();
    expect(drawn(), 2);
    await tester.tap(find.byKey(TryOnSheet.chipKey(byId('P002'))));
    await tester.pump();
    expect(drawn(), 2);

    // 다른 칸으로 옮겨서 하나 더 입는다.
    await tester.tap(find.byKey(TryOnSheet.slotKey(AccessorySlot.eyes)));
    await tester.pump();
    await tester.tap(find.byKey(TryOnSheet.chipKey(byId('P021'))));
    await tester.pump();
    expect(drawn(), 3);

    // 스킨을 입으면 한 장만 남는다.
    await tester.tap(find.byKey(TryOnSheet.slotKey(AccessorySlot.skin)));
    await tester.pump();
    await tester.tap(find.byKey(TryOnSheet.chipKey(byId('S001'))));
    await tester.pump();
    expect(drawn(), 1);

    await tester.tap(find.byKey(const Key('try-on-clear')));
    await tester.pump();
    expect(drawn(), 1);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('try-on-clear')))
          .onPressed,
      isNull,
    );
  });
}
