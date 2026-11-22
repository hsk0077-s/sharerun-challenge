import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import 'friends_models.dart';

/// What the friend screens need from the server. Tests swap in a fake.
abstract class FriendsApi {
  Future<FriendInvite> createInvite();
  Future<FriendAcceptResult> accept(String token);
  Future<List<Friend>> list();
  Future<void> remove(String friendUid);
  Future<void> block(String targetUid, {String? reportReason});
}

/// Production API: the secured-action client already holds the base URL and
/// the Firebase token.
class _SecuredFriendsApi implements FriendsApi {
  const _SecuredFriendsApi(this._ref);
  final Ref _ref;

  @override
  Future<FriendInvite> createInvite() =>
      _ref.read(securedActionApiClientProvider).createFriendInvite();

  @override
  Future<FriendAcceptResult> accept(String token) =>
      _ref.read(securedActionApiClientProvider).acceptFriendInvite(token);

  @override
  Future<List<Friend>> list() =>
      _ref.read(securedActionApiClientProvider).fetchFriends();

  @override
  Future<void> remove(String friendUid) =>
      _ref.read(securedActionApiClientProvider).removeFriend(friendUid);

  @override
  Future<void> block(String targetUid, {String? reportReason}) =>
      _ref.read(securedActionApiClientProvider).blockFriend(
            targetUid,
            reportReason: reportReason,
          );
}

final friendsApiProvider = Provider<FriendsApi>(
  (ref) => _SecuredFriendsApi(ref),
);

/// The friend list. Server data only.
final friendsListProvider = FutureProvider.autoDispose<List<Friend>>(
  (ref) => ref.watch(friendsApiProvider).list(),
);
