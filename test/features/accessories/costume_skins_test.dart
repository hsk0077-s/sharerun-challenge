import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/accessories/accessory_catalog.dart';
import 'package:share_run_challenge/features/accessories/accessory_inventory.dart';
import 'package:share_run_challenge/features/accessories/dressed_mascot.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/features/profile/widgets/gender_profile_avatar.dart';
import 'package:share_run_challenge/l10n/accessory_names.dart' as names;
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/ko_localization.dart';

/// 의상 스킨 1차: 운동복 6종(동물·캐릭터·세트)과 전통의상 4종(남·여·세트).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Accessory byId(String id) => accessoryCatalog.firstWhere((a) => a.id == id);
  final sports = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
  final costumes = ['T1', 'T2', 'T3', 'T4'];
  final dressable = TierAnimal.values.where(canDress).toList();

  test('the agreed prices are fixed', () {
    for (final s in sports) {
      expect(byId('${s}A').price, 60);
      expect(byId('${s}C').price, 60);
      expect(byId('${s}B').price, 90);
    }
    for (final t in costumes) {
      expect(byId('${t}M').price, 120);
      expect(byId('${t}F').price, 120);
      expect(byId('${t}S').price, 200);
    }
    expect(byId('S008').price, 180);
    expect(byId('S008').nameKo, '한복(동물)');
    for (final a in accessoryCatalog.where((a) => 'WT'.contains(a.id[0]) && a.id.length == 3)) {
      expect(a.currency, AccessoryCurrency.dia, reason: a.id);
    }
  });

  test('targets, genders, sets and parts', () {
    for (final s in sports) {
      expect(byId('${s}A').target, AccessoryTarget.animal);
      expect(byId('${s}A').slot, AccessorySlot.outfit);
      expect(byId('${s}A').parts, isNotEmpty);
      expect(byId('${s}C').target, AccessoryTarget.character);
      expect(byId('${s}C').gender, AccessoryGender.unisex);
      expect(byId('${s}B').bundle, ['${s}A', '${s}C']);
      expect(byId('${s}B').target, AccessoryTarget.both);
    }
    for (final t in costumes) {
      expect(byId('${t}M').gender, AccessoryGender.male);
      expect(byId('${t}F').gender, AccessoryGender.female);
      expect(byId('${t}S').bundle, ['${t}M', '${t}F']);
      expect(byId('${t}M').slot, AccessorySlot.costume);
    }
    // 태권도는 흰 띠 하나라 색 변형이 없고, 상의·하의 두 칸이다.
    expect(byId('W6A').parts, [AccessorySlot.top, AccessorySlot.bottom]);
  });

  test('placeholder pictures exist for every animal part and character version', () {
    for (final s in sports) {
      final outfit = byId('${s}A');
      for (final animal in dressable) {
        for (final part in outfit.parts) {
          expect(File(outfit.partAssetPath(part, animal)).existsSync(), isTrue,
              reason: outfit.partAssetPath(part, animal));
        }
      }
      for (final g in ['male', 'female']) {
        expect(File(byId('${s}C').characterAssetPath(g)).existsSync(), isTrue);
      }
    }
    for (final t in costumes) {
      expect(File(byId('${t}M').characterAssetPath('male')).existsSync(), isTrue);
      expect(File(byId('${t}F').characterAssetPath('female')).existsSync(), isTrue);
    }
  });

  test('every new product has a name in all 11 languages', () {
    final ids = accessoryCatalog.where((a) => 'WT'.contains(a.id[0]) && a.id.length == 3).map((a) => a.id);
    for (final id in ids) {
      for (final code in names.accessoryLanguageOrder) {
        final text = names.accessoryName(id, byId(id).nameKo, Locale(code));
        expect(text.trim(), isNotEmpty, reason: '$id $code');
      }
      expect(names.accessoryNames[id]!.length, names.accessoryLanguageOrder.length, reason: id);
    }
    expect(names.accessoryName('T1M', '', const Locale('ko')), '한국 한복 (캐릭터·남)');
    expect(names.accessoryName('T4S', '', const Locale('en')).toLowerCase(), contains('bavarian'));
    expect(names.accessoryName('S008', '', const Locale('ko')), '한복(동물)');
  });

  test('names carry no banned words', () {
    const banned = ['월드컵', '올림픽', 'FIFA', 'Olympic', 'IOC', 'World Cup', 'Nike', 'adidas'];
    for (final row in names.accessoryNames.values) {
      for (final text in row) {
        for (final word in banned) {
          expect(text.toLowerCase().contains(word.toLowerCase()), isFalse, reason: text);
        }
      }
    }
  });

  group('wearing on the animal', () {
    test('an outfit replaces loose clothes and loose clothes replace the outfit', () {
      final tee = byId('P058');
      final shorts = byId('P067');
      final outfit = byId('W1A');
      var worn = toggleAccessory({}, tee);
      worn = toggleAccessory(worn, shorts);
      worn = toggleAccessory(worn, outfit);
      expect(worn, {outfit});
      worn = toggleAccessory(worn, tee);
      expect(worn, {tee});
    });

    test('an outfit keeps head, eyes, hand and back items; a skin takes everything off', () {
      final cap = byId('P001');
      final baton = byId('P030');
      var worn = toggleAccessory({cap, baton}, byId('W2A'));
      expect(worn, {cap, baton, byId('W2A')});
      worn = toggleAccessory(worn, byId('S005'));
      expect(worn, {byId('S005')});
      worn = toggleAccessory({byId('W2A')}, byId('S005'));
      expect(worn, {byId('S005')});
    });

    test('sets and character costumes are never put on the animal', () {
      final base = {byId('P001')};
      for (final id in ['W1B', 'W1C', 'T1M', 'T1F', 'T1S']) {
        expect(byId(id).wornOnAnimal, isFalse, reason: id);
        expect(toggleAccessory(base, byId(id)), base, reason: id);
      }
    });
  });

  Future<void> pumpMascot(WidgetTester tester, Set<Accessory> worn) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: DressedMascot(
          key: const Key('stage'),
          animal: TierAnimal.wolf,
          worn: worn,
          size: 300,
        ),
      ),
    ));
    await tester.pump();
  }

  List<String> layers(WidgetTester tester) => [
        for (final image in tester.widgetList<Image>(
          find.descendant(of: find.byKey(const Key('stage')), matching: find.byType(Image)),
        ))
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName.split('/').last,
      ];

  testWidgets('an outfit draws one picture per part in the agreed order', (tester) async {
    await pumpMascot(tester, {byId('W2A')});
    expect(layers(tester), [
      'tier_wolf.png',
      'singlet-bottom-wolf.webp',
      'singlet-top-wolf.webp',
      'singlet-feet-wolf.webp',
      'singlet-head-wolf.webp',
    ]);
  });

  testWidgets('a loose head item wins over the outfit head part, hand items stack on top',
      (tester) async {
    await pumpMascot(tester, {byId('W4A'), byId('P001'), byId('P030')});
    expect(layers(tester), [
      'tier_wolf.png',
      'baseball-bottom-wolf.webp',
      'baseball-top-wolf.webp',
      'baseball-feet-wolf.webp',
      'hand-baton-held-wolf.webp',
      'cap-wolf.webp',
    ]);
  });

  group('inventory and the character', () {
    AccessoryInventory inv(Set<String> owned, {String? costume}) => AccessoryInventory(
          owned: owned,
          worn: {if (costume != null) 'costume': costume},
        );

    test('a set counts as owned only when every part is owned', () {
      expect(inv({'T1M', 'T1F'}).ownsAll(byId('T1S')), isTrue);
      expect(inv({'T1M'}).ownsAll(byId('T1S')), isFalse);
      expect(inv({'T1M'}).ownsAnyPart(byId('T1S')), isTrue);
      expect(inv({}).ownsAnyPart(byId('T1S')), isFalse);
      expect(inv({'W1A'}).ownsAnyPart(byId('W1A')), isFalse); // 단품에는 해당 없음
    });

    test('the costume fits only the matching gender, unisex fits both', () {
      expect(byId('T1M').fitsGender('male'), isTrue);
      expect(byId('T1M').fitsGender('female'), isFalse);
      expect(byId('T1F').fitsGender('female'), isTrue);
      expect(byId('T1F').fitsGender('male'), isFalse);
      expect(byId('W3C').fitsGender('male'), isTrue);
      expect(byId('W3C').fitsGender('female'), isTrue);
      expect(byId('T1S').fitsGender('male'), isFalse); // 세트는 입지 않는다
      expect(byId('W3A').fitsGender('male'), isFalse); // 동물용은 캐릭터에 입지 않는다
    });

    test('changing gender keeps what was bought, only the fitting version is worn', () {
      final bought = {'T3M', 'T3F'};
      expect(wornCostumeFor(inv(bought, costume: 'T3F'), 'female')?.id, 'T3F');
      expect(wornCostumeFor(inv(bought, costume: 'T3F'), 'male'), isNull);
      expect(inv(bought, costume: 'T3F').owns('T3M'), isTrue);
      expect(inv(bought, costume: 'T3F').owns('T3F'), isTrue);
      expect(wornCostumeFor(inv(bought, costume: 'T3M'), 'male')?.id, 'T3M');
    });

    test('a costume that is not owned or not ready is never worn', () {
      expect(wornCostumeFor(inv({}, costume: 'T1M'), 'male'), isNull);
      expect(wornCostumeFor(inv({'T1M'}), 'male'), isNull);
      expect(wornCostumeFor(inv({'nope'}, costume: 'nope'), 'male'), isNull);
    });

    test('the loadout document is read as the costume slot', () {
      final read = AccessoryInventory.fromDocs({
        'T2M': {'category': 'accessory', 'quantity': 1},
        AccessoryInventory.loadoutDocId: {
          'slots': {'costume': 'T2M', 'head': 'P001'},
        },
      });
      expect(read.worn['costume'], 'T2M');
      expect(wornCostumeFor(read, 'male')?.id, 'T2M');
    });
  });

  group('the home avatar', () {
    Future<void> pumpAvatar(
      WidgetTester tester, {
      required String gender,
      required AccessoryInventory inventory,
    }) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userGenderProvider.overrideWithValue(gender),
            accessoryInventoryProvider.overrideWith((ref) => Stream.value(inventory)),
          ],
          child: const MaterialApp(
            locale: koTestLocale,
            supportedLocales: koTestSupportedLocales,
            localizationsDelegates: koTestDelegates,
            home: Scaffold(body: Center(child: GenderProfileAvatar())),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows the worn costume of the matching gender', (tester) async {
      await pumpAvatar(
        tester,
        gender: 'female',
        inventory: const AccessoryInventory(owned: {'T1M', 'T1F'}, worn: {'costume': 'T1F'}),
      );
      expect(find.byKey(const Key('avatar-costume-T1F')), findsOneWidget);
    });

    testWidgets('falls back to the plain picture when the gender no longer matches',
        (tester) async {
      await pumpAvatar(
        tester,
        gender: 'male',
        inventory: const AccessoryInventory(owned: {'T1M', 'T1F'}, worn: {'costume': 'T1F'}),
      );
      expect(find.byKey(const Key('avatar-costume-T1F')), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('the picker lists owned costumes only, and locks the other gender',
        (tester) async {
      await pumpAvatar(
        tester,
        gender: 'male',
        inventory: const AccessoryInventory(owned: {'T2M', 'T2F'}),
      );
      await tester.tap(find.byKey(const Key('home-header-avatar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('avatar-costume-choice-T2M')), findsOneWidget);
      expect(find.byKey(const Key('avatar-costume-choice-T2F')), findsOneWidget);
      expect(find.byKey(const Key('avatar-costume-choice-T1M')), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget); // 여성 버전만 잠김
    });

    testWidgets('no costume section when nothing was bought', (tester) async {
      await pumpAvatar(tester, gender: 'male', inventory: const AccessoryInventory());
      await tester.tap(find.byKey(const Key('home-header-avatar')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.byKey(const Key('avatar-costume-choice-T1M')), findsNothing);
    });
  });
}
