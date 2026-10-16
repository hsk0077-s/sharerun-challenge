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
    await tester.tap(find.byKey(CrewEmblemPicker.iconKey('trophy')));
    await tester.tap(find.byKey(CrewEmblemPicker.colorKey('pink')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(CrewEmblemPicker.doneKey));
    await tester.tap(find.byKey(CrewEmblemPicker.doneKey));
    await tester.pumpAndSettle();
    expect(result?.code, 'trophy:pink');
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
