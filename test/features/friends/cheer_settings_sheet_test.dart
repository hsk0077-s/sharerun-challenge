import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/friends/cheers_models.dart';
import 'package:share_run_challenge/features/friends/friends_models.dart';
import 'package:share_run_challenge/features/friends/screens/cheer_settings_sheet.dart';

import 'friends_support.dart';

Friend _friend(String uid, String nickname) =>
    Friend(uid: uid, nickname: nickname);

Future<void> _pump(
  WidgetTester tester,
  FakeCheersApi cheers, {
  List<Friend>? friends,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(friendsApp(
    home: const Scaffold(body: CheerSettingsSheet()),
    api: FakeFriendsApi(
        friends: friends ?? [_friend('u1', 'Mina'), _friend('u2', 'Jun')]),
    cheers: cheers,
  ));
  await tester.pumpAndSettle();
}

bool _on(WidgetTester tester, Key key) =>
    tester.widget<SwitchListTile>(find.byKey(key)).value;

void main() {
  testWidgets('shows the note and does not promise instant alerts',
      (tester) async {
    await _pump(tester, FakeCheersApi());

    expect(
      find.text('꺼도 친구에게는 알려지지 않아요. 받은 응원은 응원함에 그대로 쌓여요.'),
      findsOneWidget,
    );
    expect(find.text('응원 알림 받기'), findsOneWidget);
    expect(find.text('친구별 응원 알림'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);
    for (final word in ['바로 알림', '즉시', '푸시']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

  testWidgets('a switch that is on means alerts are received', (tester) async {
    await _pump(
      tester,
      FakeCheersApi(
        settings: const CheerSettings(muteAll: false, mutedFriends: ['u2']),
      ),
    );

    // muteAll=false -> the "get cheer alerts" switch is on.
    expect(_on(tester, CheerSettingsSheet.muteAllKey), isTrue);
    // u1 is not muted -> on. u2 is muted -> off.
    expect(_on(tester, CheerSettingsSheet.friendKey('u1')), isTrue);
    expect(_on(tester, CheerSettingsSheet.friendKey('u2')), isFalse);
  });

  testWidgets('everything muted shows every switch off', (tester) async {
    await _pump(
      tester,
      FakeCheersApi(
        settings: const CheerSettings(muteAll: true, mutedFriends: ['u1', 'u2']),
      ),
    );

    expect(_on(tester, CheerSettingsSheet.muteAllKey), isFalse);
    expect(_on(tester, CheerSettingsSheet.friendKey('u1')), isFalse);
    expect(_on(tester, CheerSettingsSheet.friendKey('u2')), isFalse);
  });

  testWidgets('turning the all switch off saves mute_all=true', (tester) async {
    final api = FakeCheersApi();
    await _pump(tester, api);
    expect(_on(tester, CheerSettingsSheet.muteAllKey), isTrue);

    await tester.tap(find.byKey(CheerSettingsSheet.muteAllKey));
    await tester.pumpAndSettle();

    expect(api.updateCalls, [(true, null, null)]);
    expect(_on(tester, CheerSettingsSheet.muteAllKey), isFalse);

    await tester.tap(find.byKey(CheerSettingsSheet.muteAllKey));
    await tester.pumpAndSettle();
    expect(api.updateCalls.last, (false, null, null));
    expect(_on(tester, CheerSettingsSheet.muteAllKey), isTrue);
  });

  testWidgets('turning a friend off saves muted=true for that friend',
      (tester) async {
    final api = FakeCheersApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(CheerSettingsSheet.friendKey('u1')));
    await tester.pumpAndSettle();

    expect(api.updateCalls, [(null, 'u1', true)]);
    expect(_on(tester, CheerSettingsSheet.friendKey('u1')), isFalse);
    expect(_on(tester, CheerSettingsSheet.friendKey('u2')), isTrue);

    await tester.tap(find.byKey(CheerSettingsSheet.friendKey('u1')));
    await tester.pumpAndSettle();
    expect(api.updateCalls.last, (null, 'u1', false));
    expect(_on(tester, CheerSettingsSheet.friendKey('u1')), isTrue);
  });

  testWidgets('a failed save puts the switch back and says why',
      (tester) async {
    final api = FakeCheersApi()..settingsError = apiError(400, 'invalid');
    await _pump(tester, api);

    await tester.tap(find.byKey(CheerSettingsSheet.muteAllKey));
    await tester.pumpAndSettle();

    expect(api.updateCalls, hasLength(1));
    expect(_on(tester, CheerSettingsSheet.muteAllKey), isTrue);
    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);

    await tester.tap(find.byKey(CheerSettingsSheet.friendKey('u2')));
    await tester.pumpAndSettle();
    expect(_on(tester, CheerSettingsSheet.friendKey('u2')), isTrue);
  });

  testWidgets('with no friends only the all switch shows', (tester) async {
    await _pump(tester, FakeCheersApi(), friends: []);

    expect(find.byKey(CheerSettingsSheet.muteAllKey), findsOneWidget);
    expect(find.text('친구별 응원 알림'), findsNothing);
  });
}
