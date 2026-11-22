import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/features/friends/cheers_models.dart';
import 'package:share_run_challenge/features/friends/cheers_providers.dart';
import 'package:share_run_challenge/features/friends/friends_models.dart';
import 'package:share_run_challenge/features/friends/friends_providers.dart';

import '../../support/ko_localization.dart';

/// 32 characters, like the server's token_urlsafe(24).
const testToken = 'abcDEF123_-xyz456ABC789defGHI012a';

ApiException apiError(int status, String detail) =>
    ApiException(statusCode: status, detail: detail);

class FakeFriendsApi implements FriendsApi {
  FakeFriendsApi({List<Friend>? friends}) : friends = [...?friends];

  final List<Friend> friends;
  Object? listError;
  Object? inviteError;
  Object? acceptError;
  FriendInvite invite = FriendInvite(
    token: testToken,
    qrPayload: 'sharerun-friend:$testToken',
    expiresAt: DateTime.utc(2026, 11, 22, 12, 30),
  );
  FriendAcceptResult acceptResult =
      const FriendAcceptResult(status: 'added', friendUid: 'u-new');

  final acceptCalls = <String>[];
  final removeCalls = <String>[];
  final blockCalls = <(String, String?)>[];
  var inviteCalls = 0;

  @override
  Future<FriendInvite> createInvite() async {
    inviteCalls++;
    final error = inviteError;
    if (error != null) throw error;
    return invite;
  }

  @override
  Future<FriendAcceptResult> accept(String token) async {
    acceptCalls.add(token);
    final error = acceptError;
    if (error != null) throw error;
    return acceptResult;
  }

  @override
  Future<List<Friend>> list() async {
    final error = listError;
    if (error != null) throw error;
    return [...friends];
  }

  @override
  Future<void> remove(String friendUid) async {
    removeCalls.add(friendUid);
    friends.removeWhere((f) => f.uid == friendUid);
  }

  @override
  Future<void> block(String targetUid, {String? reportReason}) async {
    blockCalls.add((targetUid, reportReason));
    friends.removeWhere((f) => f.uid == targetUid);
  }
}

class FakeCheersApi implements CheersApi {
  FakeCheersApi({
    List<FriendRun>? runs,
    List<ReceivedCheer>? cheers,
    this.unread = 0,
    CheerSettings? settings,
  })  : runList = [...?runs],
        cheerList = [...?cheers],
        current = settings ??
            const CheerSettings(muteAll: false, mutedFriends: []);

  List<FriendRun> runList;
  final List<ReceivedCheer> cheerList;
  int unread;
  CheerSettings current;
  Object? runsError;
  Object? sendError;
  Object? settingsError;

  var runsCalls = 0;
  var markSeenCalls = 0;
  final sendCalls = <(String, String, CheerReaction)>[];
  final updateCalls = <(bool?, String?, bool?)>[];

  @override
  Future<List<FriendRun>> runs() async {
    runsCalls++;
    final error = runsError;
    if (error != null) throw error;
    return [...runList];
  }

  @override
  Future<void> send(
    String friendUid,
    String activityId,
    CheerReaction reaction,
  ) async {
    sendCalls.add((friendUid, activityId, reaction));
    final error = sendError;
    if (error != null) throw error;
  }

  @override
  Future<CheerInbox> inbox() async =>
      CheerInbox(cheers: [...cheerList], unreadCount: unread);

  @override
  Future<void> markSeen() async {
    markSeenCalls++;
    unread = 0;
  }

  @override
  Future<CheerSettings> settings() async => current;

  @override
  Future<CheerSettings> updateSettings({
    bool? muteAll,
    String? friendUid,
    bool? muted,
  }) async {
    updateCalls.add((muteAll, friendUid, muted));
    final error = settingsError;
    if (error != null) throw error;
    if (muteAll != null) current = current.copyWith(muteAll: muteAll);
    if (friendUid != null && muted != null) {
      current = current.copyWith(mutedFriends: [
        for (final uid in current.mutedFriends)
          if (uid != friendUid) uid,
        if (muted) friendUid,
      ]);
    }
    return current;
  }
}

FriendRun testRun({
  String id = 'r1',
  String friend = 'u1',
  String nickname = 'Mina',
  double km = 5.2,
  int seconds = 1805,
  String date = '2026-11-22',
  String? reaction,
}) =>
    FriendRun(
      activityId: id,
      friendUid: friend,
      nickname: nickname,
      distanceKm: km,
      durationSeconds: seconds,
      kstDate: date,
      myReactionWire: reaction,
    );

/// 12:00 KST on 2026-11-22.
DateTime testNow() => DateTime.utc(2026, 11, 22, 3);

Widget friendsApp({
  required Widget home,
  required FakeFriendsApi api,
  FakeCheersApi? cheers,
  GoRouter? router,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      friendsApiProvider.overrideWithValue(api),
      cheersApiProvider.overrideWithValue(cheers ?? FakeCheersApi()),
      cheerClockProvider.overrideWithValue(testNow),
      ...overrides,
    ],
    child: router != null
        ? MaterialApp.router(
            routerConfig: router,
            locale: koTestLocale,
            supportedLocales: koTestSupportedLocales,
            localizationsDelegates: koTestDelegates,
          )
        : MaterialApp(
            locale: koTestLocale,
            supportedLocales: koTestSupportedLocales,
            localizationsDelegates: koTestDelegates,
            home: home,
          ),
  );
}
