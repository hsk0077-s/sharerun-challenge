import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:share_run_challenge/core/api/api_exception.dart';
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

Widget friendsApp({
  required Widget home,
  required FakeFriendsApi api,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      friendsApiProvider.overrideWithValue(api),
      ...overrides,
    ],
    child: MaterialApp(
      locale: koTestLocale,
      supportedLocales: koTestSupportedLocales,
      localizationsDelegates: koTestDelegates,
      home: home,
    ),
  );
}
