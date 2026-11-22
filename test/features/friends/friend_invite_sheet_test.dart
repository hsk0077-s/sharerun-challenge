import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/features/brag_card/brag_card_links.dart';
import 'package:share_run_challenge/features/friends/screens/friend_invite_sheet.dart';

import 'friends_support.dart';

Future<void> _pump(WidgetTester tester, FakeFriendsApi api) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(friendsApp(
    home: const Scaffold(body: FriendInviteSheet()),
    api: api,
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => debugFriendShareOverride = null);

  testWidgets('shows the friend code as text with its expiry', (tester) async {
    await _pump(tester, FakeFriendsApi());

    final code =
        tester.widget<SelectableText>(find.byKey(FriendInviteSheet.codeKey));
    expect(code.data, 'sharerun-friend:$testToken');
    expect(find.byKey(FriendInviteSheet.expiresKey), findsOneWidget);
    expect(find.textContaining('까지 쓸 수 있어요'), findsOneWidget);
    expect(find.textContaining('24시간 동안 한 번만'), findsOneWidget);
  });

  testWidgets('no QR is drawn', (tester) async {
    await _pump(tester, FakeFriendsApi());

    final names = tester.allWidgets
        .map((w) => w.runtimeType.toString().toLowerCase())
        .where((name) => name.contains('qr'));
    expect(names, isEmpty);
    expect(find.byIcon(Icons.qr_code), findsNothing);
    expect(find.byIcon(Icons.qr_code_2), findsNothing);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
  });

  testWidgets('copy puts the friend code on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await _pump(tester, FakeFriendsApi());

    await tester.tap(find.byKey(FriendInviteSheet.copyKey));
    await tester.pumpAndSettle();

    expect(copied, 'sharerun-friend:$testToken');
    expect(find.text('복사했어요.'), findsOneWidget);
  });

  testWidgets('share hands the phone share sheet the code and the Play link',
      (tester) async {
    ShareParams? sent;
    debugFriendShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    await _pump(tester, FakeFriendsApi());

    await tester.tap(find.byKey(FriendInviteSheet.shareKey));
    await tester.pumpAndSettle();

    final text = sent!.text!;
    expect(text, contains('sharerun-friend:$testToken'));
    expect(text, contains(sharerunPlayStoreUrl));
    expect(text, contains('쉐어런'));
    expect(text, contains('친구 코드 입력'));
    expect(text, contains('24시간'));
    expect(sent!.subject, '쉐어런 친구 코드');
  });

  testWidgets('the shared text has no referral code, uid or nickname',
      (tester) async {
    ShareParams? sent;
    debugFriendShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    await _pump(tester, FakeFriendsApi());

    await tester.tap(find.byKey(FriendInviteSheet.shareKey));
    await tester.pumpAndSettle();

    final text = sent!.text!;
    expect(text.contains('추천'), isFalse);
    expect(text.contains('초대 코드'), isFalse);
    expect(text.toLowerCase().contains('referral'), isFalse);
    expect(text.contains('uid'), isFalse);
    expect(text.contains('nickname'), isFalse);
    // Only the plain Play Store link, with no tracking parameters.
    expect(text.contains('utm_'), isFalse);
    expect(text.contains('referrer'), isFalse);
  });

  testWidgets('429 says no more codes today and shows no code', (tester) async {
    final api = FakeFriendsApi()
      ..inviteError = apiError(429, 'Friend invite limit reached.');
    await _pump(tester, api);

    expect(find.byKey(FriendInviteSheet.errorKey), findsOneWidget);
    expect(find.textContaining('오늘은 코드를 더 만들 수 없어요'), findsOneWidget);
    expect(find.byKey(FriendInviteSheet.codeKey), findsNothing);
    expect(find.byKey(FriendInviteSheet.shareKey), findsNothing);
  });

  testWidgets('a network error shows the general message', (tester) async {
    final api = FakeFriendsApi()..inviteError = Exception('offline');
    await _pump(tester, api);

    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);
  });
}
