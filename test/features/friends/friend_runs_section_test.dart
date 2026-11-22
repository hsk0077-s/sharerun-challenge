import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/friends/cheers_models.dart';
import 'package:share_run_challenge/features/friends/screens/friend_runs_section.dart';

import 'friends_support.dart';

Future<FakeCheersApi> _pump(
  WidgetTester tester, {
  List<FriendRun>? runs,
  FakeCheersApi? api,
}) async {
  final cheers = api ?? FakeCheersApi(runs: runs);
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(friendsApp(
    home: const Scaffold(body: SingleChildScrollView(child: FriendRunsSection())),
    api: FakeFriendsApi(),
    cheers: cheers,
  ));
  await tester.pumpAndSettle();
  return cheers;
}

Future<void> _openSheetAndPick(
  WidgetTester tester,
  String activityId,
  CheerReaction reaction,
) async {
  await tester.tap(find.byKey(FriendRunsSection.buttonKey(activityId)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(FriendRunsSection.reactionKey(reaction)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a row shows nickname, distance, time and the day',
      (tester) async {
    await _pump(tester, runs: [
      testRun(id: 'a', nickname: 'Mina'),
      testRun(id: 'b', nickname: 'Jun', km: 10, seconds: 3725, date: '2026-11-21'),
      testRun(id: 'c', nickname: 'Sua', km: 3.456, seconds: 59, date: '2026-11-18'),
    ]);

    expect(find.text('친구 달리기'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('5.20km · 30:05 · 오늘'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);
    expect(find.text('10.00km · 1:02:05 · 어제'), findsOneWidget);
    expect(find.text('3.46km · 0:59 · 11월 18일'), findsOneWidget);
  });

  testWidgets('a friend with no nickname shows the stand-in name',
      (tester) async {
    await _pump(tester, runs: [testRun(nickname: '')]);

    expect(find.text('이름 없는 러너'), findsOneWidget);
  });

  testWidgets('no runs shows one calm line and no nagging', (tester) async {
    await _pump(tester, runs: []);

    expect(find.byKey(FriendRunsSection.emptyKey), findsOneWidget);
    expect(find.text('최근 7일 동안 친구 달리기가 없어요.'), findsOneWidget);
    for (final word in ['안 뛰', '뛰어', '재촉', '아직']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

  testWidgets('a failed load says so and retry loads again', (tester) async {
    final api = FakeCheersApi(runs: [testRun()])..runsError = Exception('x');
    await _pump(tester, api: api);

    expect(find.byKey(FriendRunsSection.failedKey), findsOneWidget);
    api.runsError = null;
    await tester.tap(find.byKey(FriendRunsSection.retryKey));
    await tester.pumpAndSettle();

    expect(find.text('Mina'), findsOneWidget);
  });

  testWidgets('the cheer button opens a sheet with the five cheers',
      (tester) async {
    await _pump(tester, runs: [testRun()]);

    await tester.tap(find.byKey(FriendRunsSection.buttonKey('r1')));
    await tester.pumpAndSettle();

    expect(find.byKey(FriendRunsSection.sheetKey), findsOneWidget);
    for (final reaction in CheerReaction.values) {
      expect(find.byKey(FriendRunsSection.reactionKey(reaction)), findsOneWidget);
      expect(find.text(reaction.emoji), findsOneWidget);
    }
    for (final name in ['박수', '불꽃', '파이팅', '하트', '최고']) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('sending shows the emoji and disables the button',
      (tester) async {
    final api = await _pump(tester, runs: [testRun(), testRun(id: 'r2')]);

    await _openSheetAndPick(tester, 'r1', CheerReaction.fire);

    expect(api.sendCalls, [('u1', 'r1', CheerReaction.fire)]);
    expect(find.byKey(FriendRunsSection.emojiKey('r1')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(FriendRunsSection.emojiKey('r1')))
          .data,
      '🔥',
    );
    expect(
      tester
          .widget<OutlinedButton>(
              find.byKey(FriendRunsSection.buttonKey('r1')))
          .onPressed,
      isNull,
    );
    expect(find.text('응원했어요'), findsOneWidget);
    // The other row is untouched.
    expect(
      tester
          .widget<OutlinedButton>(
              find.byKey(FriendRunsSection.buttonKey('r2')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('closing the sheet without a pick sends nothing',
      (tester) async {
    final api = await _pump(tester, runs: [testRun()]);

    await tester.tap(find.byKey(FriendRunsSection.buttonKey('r1')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(api.sendCalls, isEmpty);
  });

  testWidgets('a run already cheered starts disabled with its emoji',
      (tester) async {
    await _pump(tester, runs: [testRun(reaction: 'heart')]);

    expect(
      tester.widget<Text>(find.byKey(FriendRunsSection.emojiKey('r1'))).data,
      '❤️',
    );
    expect(
      tester
          .widget<OutlinedButton>(
              find.byKey(FriendRunsSection.buttonKey('r1')))
          .onPressed,
      isNull,
    );
    expect(find.text('응원했어요'), findsOneWidget);
  });

  for (final row in [
    (404, 'not_found', '이 기록에는 응원할 수 없어요.'),
    (429, 'friend_daily_limit', '이 친구에게는 오늘 이미 응원했어요'),
    (429, 'daily_limit', '오늘 응원은 20번까지예요.'),
    (400, 'invalid_reaction', '잠시 후 다시 시도해 주세요.'),
  ]) {
    testWidgets('${row.$2} shows its message and keeps the button',
        (tester) async {
      final api = await _pump(tester, runs: [testRun()]);
      api.sendError = apiError(row.$1, row.$2);

      await _openSheetAndPick(tester, 'r1', CheerReaction.clap);

      expect(find.textContaining(row.$3), findsOneWidget);
      expect(find.byKey(FriendRunsSection.emojiKey('r1')), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
                find.byKey(FriendRunsSection.buttonKey('r1')))
            .onPressed,
        isNotNull,
      );
    });
  }

  testWidgets('already_cheered says so and reloads the list', (tester) async {
    final api = await _pump(tester, runs: [testRun()]);
    api.sendError = apiError(409, 'already_cheered');
    api.runList = [testRun(reaction: 'clap')];
    final before = api.runsCalls;

    await _openSheetAndPick(tester, 'r1', CheerReaction.clap);

    expect(find.text('이미 응원했어요.'), findsOneWidget);
    expect(api.runsCalls, before + 1);
    expect(find.byKey(FriendRunsSection.emojiKey('r1')), findsOneWidget);
  });

  testWidgets('no place, route or start-time words appear', (tester) async {
    await _pump(tester, runs: [testRun()]);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    for (final word in ['위치', '경로', '시작', '지도', '순위']) {
      expect(texts.contains(word), isFalse, reason: word);
    }
    expect(find.byIcon(Icons.map), findsNothing);
    expect(find.byIcon(Icons.location_on), findsNothing);
  });
}
