import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/features/friends/cheers_models.dart';
import 'package:share_run_challenge/features/friends/screens/cheer_inbox_screen.dart';
import 'package:share_run_challenge/features/friends/screens/friends_screen.dart';

import 'friends_support.dart';

ReceivedCheer _cheer(
  String uid,
  String nickname,
  CheerReaction reaction,
  DateTime at,
) =>
    ReceivedCheer(
      fromUid: uid,
      nickname: nickname,
      activityId: 'a-$uid',
      reaction: reaction,
      createdAt: at,
    );

Future<void> _pump(WidgetTester tester, FakeCheersApi cheers) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(friendsApp(
    home: const CheerInboxScreen(),
    api: FakeFriendsApi(),
    cheers: cheers,
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cheers are listed in the order given, newest first',
      (tester) async {
    final now = DateTime.now();
    final api = FakeCheersApi(cheers: [
      _cheer('u1', 'Mina', CheerReaction.fire, now),
      _cheer('u2', 'Jun', CheerReaction.clap, now.subtract(const Duration(days: 1))),
      _cheer('u3', '', CheerReaction.heart, now.subtract(const Duration(days: 5))),
    ]);
    await _pump(tester, api);

    expect(find.text('받은 응원'), findsOneWidget);
    final first = tester.getTopLeft(find.text('Mina님이 응원했어요')).dy;
    final second = tester.getTopLeft(find.text('Jun님이 응원했어요')).dy;
    final third = tester.getTopLeft(find.text('이름 없는 러너님이 응원했어요')).dy;
    expect(first, lessThan(second));
    expect(second, lessThan(third));
    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('👏'), findsOneWidget);
    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('어제'), findsOneWidget);
  });

  testWidgets('a cheer with no date still shows', (tester) async {
    final api = FakeCheersApi(cheers: [
      const ReceivedCheer(
        fromUid: 'u1',
        nickname: 'Mina',
        activityId: 'r',
        reaction: CheerReaction.thumbs,
      ),
    ]);
    await _pump(tester, api);

    expect(find.text('Mina님이 응원했어요'), findsOneWidget);
  });

  testWidgets('no cheers shows the empty line', (tester) async {
    await _pump(tester, FakeCheersApi());

    expect(find.byKey(CheerInboxScreen.emptyKey), findsOneWidget);
    expect(find.text('아직 받은 응원이 없어요.'), findsOneWidget);
  });

  testWidgets('opening marks cheers seen exactly once', (tester) async {
    final api = FakeCheersApi(unread: 3, cheers: [
      _cheer('u1', 'Mina', CheerReaction.fire, DateTime.now()),
    ]);
    await _pump(tester, api);

    expect(api.markSeenCalls, 1);
    expect(api.unread, 0);
  });

  testWidgets('there is no reply or cheer-back button', (tester) async {
    final api = FakeCheersApi(cheers: [
      _cheer('u1', 'Mina', CheerReaction.fire, DateTime.now()),
    ]);
    await _pump(tester, api);

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  group('badge on the friends screen', () {
    Future<void> pumpFriends(WidgetTester tester, FakeCheersApi cheers) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(friendsApp(
        home: const FriendsScreen(),
        api: FakeFriendsApi(),
        cheers: cheers,
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('unread 3 shows a 3 badge', (tester) async {
      await pumpFriends(tester, FakeCheersApi(unread: 3));

      expect(find.byKey(FriendsScreen.inboxBadgeKey), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('unread 0 shows no badge', (tester) async {
      await pumpFriends(tester, FakeCheersApi(unread: 0));

      expect(find.byKey(FriendsScreen.inboxButtonKey), findsOneWidget);
      expect(find.byKey(FriendsScreen.inboxBadgeKey), findsNothing);
    });

    testWidgets('many unread is capped at 99+', (tester) async {
      await pumpFriends(tester, FakeCheersApi(unread: 240));

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('opening the inbox clears the badge when coming back',
        (tester) async {
      final api = FakeCheersApi(unread: 3, cheers: [
        _cheer('u1', 'Mina', CheerReaction.fire, DateTime.now()),
      ]);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const FriendsScreen()),
        GoRoute(
          path: RouteNames.cheerInbox,
          builder: (_, __) => const CheerInboxScreen(),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(friendsApp(
        home: const SizedBox(),
        api: FakeFriendsApi(),
        cheers: api,
        router: router,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(FriendsScreen.inboxBadgeKey), findsOneWidget);

      await tester.tap(find.byKey(FriendsScreen.inboxButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Mina님이 응원했어요'), findsOneWidget);
      expect(api.markSeenCalls, 1);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(FriendsScreen.inboxBadgeKey), findsNothing);
    });
  });
}
