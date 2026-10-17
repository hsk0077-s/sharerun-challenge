import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/crew/crew_emblem.dart';
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
