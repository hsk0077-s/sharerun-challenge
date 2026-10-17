import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/crew/crew_emblem.dart';
import 'package:share_run_challenge/features/crew/crew_emblem_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  groupsTest();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('there are at least 20 shapes and 6 colors', () {
    expect(CrewEmblem.icons.length, greaterThanOrEqualTo(20));
    expect(CrewEmblem.colors.length, 6);
  });

  test('code round trip and bad codes', () {
    const emblem = CrewEmblem('rocket', 'sky');
    expect(CrewEmblem.parse(emblem.code), emblem);
    for (final bad in [
      null,
      '',
      'rocket',
      'rocket:red',
      'dragon:lime',
      'a:b:c'
    ]) {
      expect(CrewEmblem.parse(bad), isNull, reason: '$bad');
    }
  });

  test('choosing saves on the phone and a new container reads it back',
      () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    expect(first.read(crewEmblemProvider), CrewEmblem.fallback);
    await first
        .read(crewEmblemProvider.notifier)
        .choose(const CrewEmblem('star', 'gold'));
    expect(first.read(crewEmblemProvider).code, 'star:gold');

    final second = ProviderContainer();
    addTearDown(second.dispose);
    second.read(crewEmblemProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(second.read(crewEmblemProvider).code, 'star:gold');
  });

  testWidgets('picking a frame colour drops glyph colours that would not show',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.night,
        home: const Scaffold(
          body: CrewEmblemPicker(initial: CrewEmblem.layeredDefault),
        ),
      ),
    );
    // 금색 틀에는 숯색·남색 문양만 남는다. 흰색은 없다.
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.colorKey('gold')));
    await tester.tap(find.byKey(CrewEmblemPicker.colorKey('gold')));
    await tester.pump();
    expect(find.byKey(CrewEmblemPicker.glyphColorKey('navy')), findsOneWidget);
    expect(find.byKey(CrewEmblemPicker.glyphColorKey('charcoal')), findsOneWidget);
    expect(find.byKey(CrewEmblemPicker.glyphColorKey('white')), findsNothing);
  });

  test('layered codes round trip, and low-contrast or unknown parts are refused', () {
    const ok = 'shield:g_wolf:rays:navy:white';
    expect(CrewEmblem.parse(ok)?.code, ok);
    expect(CrewEmblem.parse(ok)?.isLayered, isTrue);
    for (final bad in [
      'shield:g_wolf:rays:lime:white',
      'blob:g_wolf:rays:navy:white',
      'shield:wolf:rays:navy:white',
      'shield:g_wolf:swirl:navy:white',
      'shield:g_wolf:rays:navy',
    ]) {
      expect(CrewEmblem.parse(bad), isNull, reason: bad);
    }
    // 서버와 같은 표인지 한 줄이라도 어긋나면 알 수 있게 개수를 고정한다.
    expect(
      CrewEmblem.allowedPairs.values.fold<int>(0, (n, l) => n + l.length),
      48,
    );
  });

  test('every frame and pattern has a PNG asset', () {
    expect(CrewEmblem.frames.length, 8);
    for (final id in CrewEmblem.frames) {
      expect(File(CrewEmblem.frameAsset(id)).existsSync(), isTrue, reason: id);
    }
    for (final id in CrewEmblem.patterns.where((p) => p != 'none')) {
      expect(File(CrewEmblem.patternAsset(id)).existsSync(), isTrue, reason: id);
    }
  });

  test('border and paid codes parse and round trip', () {
    const withBorder = 'shield:g_wolf:rays:navy:white:distance-2';
    expect(CrewEmblem.parse(withBorder)?.code, withBorder);
    expect(CrewEmblem.parse(withBorder)?.border, 'distance-2');
    expect(CrewEmblem.parse('shield:g_wolf:rays:navy:white:gold-9'), isNull);
    expect(CrewEmblem.parse('paid:moon-wolf')?.paid, isTrue);
    expect(CrewEmblem.parse('paid:moon-wolf')?.code, 'paid:moon-wolf');
    expect(CrewEmblem.parse('paid:nope'), isNull);
    for (final id in CrewEmblem.borderIds) {
      expect(File(CrewEmblem.borderAsset(id)).existsSync(), isTrue, reason: id);
    }
    for (final id in CrewEmblem.paidIds) {
      expect(File(CrewEmblem.paidAsset(id)).existsSync(), isTrue, reason: id);
    }
  });

  Future<void> pumpPicker(
    WidgetTester tester, {
    CrewEmblemStatus? status,
    Future<CrewEmblemStatus?> Function(String)? onBuy,
    required void Function(CrewEmblem?) onResult,
  }) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.night,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => onResult(await CrewEmblemPicker.show(
                context,
                CrewEmblem.layeredDefault,
                status: status,
                onBuy: onBuy,
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('only earned borders can be worn; the rest stay locked',
      (tester) async {
    CrewEmblem? result;
    await pumpPicker(
      tester,
      status: const CrewEmblemStatus(
        earnedBorders: {'members-1'},
        thresholds: {
          'members': [10, 30, 50]
        },
        progress: {'members': 12},
      ),
      onResult: (e) => result = e,
    );
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.borderKey('distance-1')));
    await tester.tap(find.byKey(CrewEmblemPicker.borderKey('distance-1')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.borderKey('members-1')));
    await tester.tap(find.byKey(CrewEmblemPicker.borderKey('members-1')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.doneKey));
    await tester.tap(find.byKey(CrewEmblemPicker.doneKey));
    await tester.pumpAndSettle();
    expect(result?.code, '${CrewEmblem.layeredDefault.code}:members-1');
  });

  testWidgets('paid emblems: not on sale, owned ones can be picked',
      (tester) async {
    CrewEmblem? result;
    await pumpPicker(
      tester,
      status: const CrewEmblemStatus(
        paidOwned: {'moon-wolf'},
        paidPrices: {'moon-wolf': 40, 'glow-heart': 50},
      ),
      onResult: (e) => result = e,
    );
    expect(find.byKey(const Key('crew-emblem-paid-preparing')), findsOneWidget);
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.paidKey('glow-heart')));
    await tester.tap(find.byKey(CrewEmblemPicker.paidKey('glow-heart')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.paidKey('moon-wolf')));
    await tester.tap(find.byKey(CrewEmblemPicker.paidKey('moon-wolf')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.doneKey));
    await tester.tap(find.byKey(CrewEmblemPicker.doneKey));
    await tester.pumpAndSettle();
    expect(result?.code, 'paid:moon-wolf');
  });

  testWidgets('with the sale on, tapping a paid emblem asks to buy it',
      (tester) async {
    final bought = <String>[];
    await pumpPicker(
      tester,
      status: const CrewEmblemStatus(
        paidSaleEnabled: true,
        isLeader: true,
        paidPrices: {'glow-heart': 300},
      ),
      onBuy: (id) async {
        bought.add(id);
        return const CrewEmblemStatus(
          paidSaleEnabled: true,
          isLeader: true,
          paidOwned: {'glow-heart'},
          paidPrices: {'glow-heart': 300},
        );
      },
      onResult: (_) {},
    );
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.paidKey('glow-heart')));
    await tester.tap(find.byKey(CrewEmblemPicker.paidKey('glow-heart')));
    await tester.pumpAndSettle();
    // 바로 사지 않고 값과 함께 먼저 묻는다.
    expect(bought, isEmpty);
    expect(find.textContaining('300 DIA'), findsWidgets);
    await tester.tap(find.byKey(const Key('crew-emblem-buy-confirm')));
    await tester.pumpAndSettle();
    expect(bought, ['glow-heart']);
    expect(find.text('보유'), findsOneWidget);
  });

  testWidgets('cancelling the question buys nothing; a sub-leader cannot buy',
      (tester) async {
    final bought = <String>[];
    Future<CrewEmblemStatus?> buy(String id) async {
      bought.add(id);
      return null;
    }

    await pumpPicker(
      tester,
      status: const CrewEmblemStatus(
        paidSaleEnabled: true,
        isLeader: true,
        paidPrices: {'glow-heart': 300},
      ),
      onBuy: buy,
      onResult: (_) {},
    );
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.paidKey('glow-heart')));
    await tester.tap(find.byKey(CrewEmblemPicker.paidKey('glow-heart')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(bought, isEmpty);
  });

  testWidgets('a sub-leader sees the emblems but the leader-only note',
      (tester) async {
    await pumpPicker(
      tester,
      status: const CrewEmblemStatus(
        paidSaleEnabled: true,
        isLeader: false,
        paidPrices: {'glow-heart': 300},
      ),
      onBuy: (id) async => null,
      onResult: (_) {},
    );
    await tester.ensureVisible(find.byKey(const Key('crew-emblem-paid-leader-only')));
    expect(find.byKey(const Key('crew-emblem-paid-leader-only')), findsOneWidget);
    await tester.tap(find.byKey(CrewEmblemPicker.paidKey('glow-heart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crew-emblem-buy-confirm')), findsNothing);
  });

  testWidgets('picker returns the chosen shape and color', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CrewEmblem? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.night,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result =
                  await CrewEmblemPicker.show(context, CrewEmblem.fallback),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    Future<void> tap(Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await tester.pump();
    }

    await tap(CrewEmblemPicker.frameKey('circle'));
    await tap(CrewEmblemPicker.iconKey('g_trophy'));
    await tap(CrewEmblemPicker.patternKey('dots'));
    await tap(CrewEmblemPicker.colorKey('charcoal'));
    await tap(CrewEmblemPicker.glyphColorKey('red'));
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.doneKey));
    await tester.tap(find.byKey(CrewEmblemPicker.doneKey));
    await tester.pumpAndSettle();
    expect(result?.code, 'circle:g_trophy:dots:charcoal:red');
  });
}

void groupsTest() {
  test('groups cover every icon exactly once', () {
    final listed = [for (final g in CrewEmblem.groups.values) ...g];
    expect(listed.length, CrewEmblem.icons.length + CrewEmblem.glyphIds.length);
    expect(
      listed.toSet(),
      {...CrewEmblem.icons.keys, ...CrewEmblem.glyphIds},
    );
  });

  test('every glyph id has a PNG asset and parses', () {
    expect(CrewEmblem.glyphIds.length, 30);
    for (final id in CrewEmblem.glyphIds) {
      expect(File(CrewEmblem.glyphAssetOf(id)).existsSync(), isTrue,
          reason: id);
      expect(CrewEmblem.parse('$id:lime'), isNotNull, reason: id);
    }
    expect(CrewEmblem.parse('g_nope:lime'), isNull);
  });
}
