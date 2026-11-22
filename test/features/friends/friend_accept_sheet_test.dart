import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/friends/friends_models.dart';
import 'package:share_run_challenge/features/friends/screens/friend_accept_sheet.dart';

import 'friends_support.dart';

Future<void> _pump(WidgetTester tester, FakeFriendsApi api) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(friendsApp(
    home: const Scaffold(body: FriendAcceptSheet()),
    api: api,
  ));
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(FriendAcceptSheet.fieldKey), text);
  await tester.tap(find.byKey(FriendAcceptSheet.submitKey));
  await tester.pumpAndSettle();
}

void main() {
  const code = 'sharerun-friend:$testToken';

  testWidgets('added says you are friends and sends only the token',
      (tester) async {
    final api = FakeFriendsApi();
    await _pump(tester, api);

    await _submit(tester, code);

    expect(api.acceptCalls, [testToken]);
    expect(find.text('친구가 됐어요.'), findsOneWidget);
    expect(find.byKey(FriendAcceptSheet.errorKey), findsNothing);
  });

  testWidgets('already_friends is a friendly note, not an error',
      (tester) async {
    final api = FakeFriendsApi()
      ..acceptResult =
          const FriendAcceptResult(status: 'already_friends', friendUid: 'u1');
    await _pump(tester, api);

    await _submit(tester, code);

    expect(find.text('이미 친구예요.'), findsOneWidget);
    expect(find.byKey(FriendAcceptSheet.errorKey), findsNothing);
  });

  testWidgets('the whole shared message works, not just the code',
      (tester) async {
    final api = FakeFriendsApi();
    await _pump(tester, api);

    await _submit(
      tester,
      "Let's be friends on ShareRun. Code: $code\nhttps://play.google.com/x",
    );

    expect(api.acceptCalls, [testToken]);
  });

  for (final row in [
    (400, 'invalid', '코드를 확인해 주세요'),
    (400, 'self', '내 친구 코드는 내가 쓸 수 없어요'),
    (410, 'used', '이미 사용한 코드예요'),
    (410, 'expired', '24시간이 지난 코드예요'),
    (409, 'friend_limit', '친구는 50명까지'),
  ]) {
    testWidgets('${row.$2} shows its own message', (tester) async {
      final api = FakeFriendsApi()..acceptError = apiError(row.$1, row.$2);
      await _pump(tester, api);

      await _submit(tester, code);

      expect(find.byKey(FriendAcceptSheet.errorKey), findsOneWidget);
      expect(find.textContaining(row.$3), findsOneWidget);
      expect(api.acceptCalls, [testToken]);
      // The button works again so the person can try another code.
      expect(
        tester
            .widget<FilledButton>(find.byKey(FriendAcceptSheet.submitKey))
            .onPressed,
        isNotNull,
      );
    });
  }

  testWidgets('invalid never mentions referral codes', (tester) async {
    final api = FakeFriendsApi()..acceptError = apiError(400, 'invalid');
    await _pump(tester, api);

    await _submit(tester, code);

    final shown =
        tester.widget<Text>(find.byKey(FriendAcceptSheet.errorKey)).data!;
    expect(shown.contains('추천'), isFalse);
    expect(shown.contains('초대'), isFalse);
  });

  for (final text in ['', '   ', '안녕하세요', 'sharerun-friend:abc']) {
    testWidgets('no usable code ("$text") calls the server 0 times',
        (tester) async {
      final api = FakeFriendsApi();
      await _pump(tester, api);

      await _submit(tester, text);

      expect(api.acceptCalls, isEmpty);
      expect(find.byKey(FriendAcceptSheet.errorKey), findsOneWidget);
      expect(find.textContaining('코드를 확인해 주세요'), findsOneWidget);
    });
  }

  testWidgets('the paste button fills the field from the clipboard',
      (tester) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': code};
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final api = FakeFriendsApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(FriendAcceptSheet.pasteKey));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(FriendAcceptSheet.fieldKey))
          .controller!
          .text,
      code,
    );
    // Pasting alone sends nothing.
    expect(api.acceptCalls, isEmpty);
  });
}
