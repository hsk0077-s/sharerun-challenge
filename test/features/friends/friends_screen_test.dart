import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/friends/friends_models.dart';
import 'package:share_run_challenge/features/friends/screens/friends_screen.dart';

import 'friends_support.dart';

Friend _friend(String uid, String nickname) =>
    Friend(uid: uid, nickname: nickname, createdAt: DateTime.utc(2026, 11, 20));

Future<void> _pump(WidgetTester tester, FakeFriendsApi api) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(friendsApp(home: const FriendsScreen(), api: api));
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester, String uid, Key item) async {
  await tester.tap(find.byKey(FriendsScreen.menuKey(uid)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(item));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows each friend by nickname, with a stand-in for no name',
      (tester) async {
    await _pump(
        tester,
        FakeFriendsApi(friends: [
          _friend('u1', '달리는 토끼'),
          _friend('u2', ''),
          _friend('u3', '   '),
        ]));

    expect(find.text('달리는 토끼'), findsOneWidget);
    expect(find.text('이름 없는 러너'), findsNWidgets(2));
    expect(find.byKey(FriendsScreen.rowKey('u1')), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNWidgets(3));
  });

  testWidgets('an empty list explains what to do and keeps both buttons',
      (tester) async {
    await _pump(tester, FakeFriendsApi());

    expect(find.byKey(FriendsScreen.emptyKey), findsOneWidget);
    expect(find.textContaining('아직 친구가 없어요'), findsOneWidget);
    expect(find.text('친구 코드 만들기'), findsOneWidget);
    expect(find.text('친구 코드 입력'), findsOneWidget);
  });

  testWidgets('shows a spinner while loading', (tester) async {
    final api = FakeFriendsApi();
    await tester.pumpWidget(friendsApp(home: const FriendsScreen(), api: api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('a failed load shows a message and retry reloads',
      (tester) async {
    final api = FakeFriendsApi(friends: [_friend('u1', '토끼')])
      ..listError = apiError(500, 'boom');
    await _pump(tester, api);

    expect(find.text('친구 목록을 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('토끼'), findsNothing);

    api.listError = null;
    await tester.tap(find.byKey(FriendsScreen.retryKey));
    await tester.pumpAndSettle();
    expect(find.text('토끼'), findsOneWidget);
  });

  testWidgets('removing a friend asks first, then drops the row, once',
      (tester) async {
    final api =
        FakeFriendsApi(friends: [_friend('u1', '토끼'), _friend('u2', '거북')]);
    await _pump(tester, api);

    await _openMenu(tester, 'u1', FriendsScreen.removeItemKey);
    expect(find.text('친구를 끊을까요?'), findsOneWidget);
    expect(find.textContaining('알림이 가지 않아요'), findsOneWidget);
    expect(api.removeCalls, isEmpty);

    await tester.tap(find.byKey(FriendsScreen.confirmKey));
    await tester.pumpAndSettle();

    expect(api.removeCalls, ['u1']);
    expect(find.text('토끼'), findsNothing);
    expect(find.text('거북'), findsOneWidget);
    expect(find.text('친구를 끊었어요.'), findsOneWidget);
  });

  testWidgets('cancelling the remove dialog changes nothing', (tester) async {
    final api = FakeFriendsApi(friends: [_friend('u1', '토끼')]);
    await _pump(tester, api);

    await _openMenu(tester, 'u1', FriendsScreen.removeItemKey);
    await tester.tap(find.byKey(FriendsScreen.cancelKey));
    await tester.pumpAndSettle();

    expect(api.removeCalls, isEmpty);
    expect(find.text('토끼'), findsOneWidget);
  });

  testWidgets('block asks first, then calls block with no report reason',
      (tester) async {
    final api = FakeFriendsApi(friends: [_friend('u1', '토끼')]);
    await _pump(tester, api);

    await _openMenu(tester, 'u1', FriendsScreen.blockItemKey);
    expect(find.text('차단할까요?'), findsOneWidget);
    expect(find.textContaining('알림이 가지 않아요'), findsOneWidget);
    await tester.tap(find.byKey(FriendsScreen.confirmKey));
    await tester.pumpAndSettle();

    expect(api.blockCalls, [('u1', null)]);
    expect(find.text('토끼'), findsNothing);
    expect(find.text('차단했어요.'), findsOneWidget);
  });

  for (final reason in FriendReportReason.values) {
    testWidgets('report and block with "${reason.wire}"', (tester) async {
      final api = FakeFriendsApi(friends: [_friend('u1', '토끼')]);
      await _pump(tester, api);

      await _openMenu(tester, 'u1', FriendsScreen.reportItemKey);
      expect(api.blockCalls, isEmpty);
      await tester.tap(find.byKey(FriendsScreen.reasonKey(reason)));
      await tester.pumpAndSettle();

      expect(api.blockCalls, [('u1', reason.wire)]);
      expect(find.text('토끼'), findsNothing);
    });
  }

  testWidgets('closing the reason list without a pick blocks no one',
      (tester) async {
    final api = FakeFriendsApi(friends: [_friend('u1', '토끼')]);
    await _pump(tester, api);

    await _openMenu(tester, 'u1', FriendsScreen.reportItemKey);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(api.blockCalls, isEmpty);
    expect(find.text('토끼'), findsOneWidget);
  });

  testWidgets('a failed removal keeps the row and says why', (tester) async {
    final api = _FailingRemoveApi(friends: [_friend('u1', '토끼')]);
    await _pump(tester, api);

    await _openMenu(tester, 'u1', FriendsScreen.removeItemKey);
    await tester.tap(find.byKey(FriendsScreen.confirmKey));
    await tester.pumpAndSettle();

    expect(find.text('토끼'), findsOneWidget);
    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('no place, route or record words appear on the screen',
      (tester) async {
    await _pump(tester, FakeFriendsApi(friends: [_friend('u1', '토끼')]));

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join(' ');
    for (final word in ['위치', '경로', '기록', '거리', '시작 시각', 'km']) {
      expect(texts.contains(word), isFalse, reason: word);
    }
    expect(find.byIcon(Icons.map), findsNothing);
    expect(find.byIcon(Icons.location_on), findsNothing);
  });

  testWidgets('create and enter buttons open their sheets', (tester) async {
    final api = FakeFriendsApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(FriendsScreen.createKey));
    await tester.pumpAndSettle();
    expect(api.inviteCalls, 1);
    expect(find.text('친구 코드'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FriendsScreen.enterKey));
    await tester.pumpAndSettle();
    expect(find.text('친구 맺기'), findsOneWidget);
  });
}

class _FailingRemoveApi extends FakeFriendsApi {
  _FailingRemoveApi({super.friends});

  @override
  Future<void> remove(String friendUid) async {
    removeCalls.add(friendUid);
    throw apiError(500, 'boom');
  }
}
