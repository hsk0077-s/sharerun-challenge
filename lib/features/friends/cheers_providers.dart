import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import 'cheers_models.dart';

/// What the cheer screens need from the server. Tests swap in a fake.
abstract class CheersApi {
  Future<List<FriendRun>> runs();
  Future<void> send(String friendUid, String activityId, CheerReaction reaction);
  Future<CheerInbox> inbox();
  Future<void> markSeen();
  Future<CheerSettings> settings();

  /// Either [muteAll], or [friendUid] with [muted].
  Future<CheerSettings> updateSettings({
    bool? muteAll,
    String? friendUid,
    bool? muted,
  });
}

class _SecuredCheersApi implements CheersApi {
  const _SecuredCheersApi(this._ref);
  final Ref _ref;

  @override
  Future<List<FriendRun>> runs() =>
      _ref.read(securedActionApiClientProvider).fetchFriendRuns();

  @override
  Future<void> send(
    String friendUid,
    String activityId,
    CheerReaction reaction,
  ) =>
      _ref.read(securedActionApiClientProvider).sendCheer(
            friendUid: friendUid,
            activityId: activityId,
            reaction: reaction.wire,
          );

  @override
  Future<CheerInbox> inbox() =>
      _ref.read(securedActionApiClientProvider).fetchCheerInbox();

  @override
  Future<void> markSeen() =>
      _ref.read(securedActionApiClientProvider).markCheerInboxSeen();

  @override
  Future<CheerSettings> settings() =>
      _ref.read(securedActionApiClientProvider).fetchCheerSettings();

  @override
  Future<CheerSettings> updateSettings({
    bool? muteAll,
    String? friendUid,
    bool? muted,
  }) =>
      _ref.read(securedActionApiClientProvider).updateCheerSettings(
            muteAll: muteAll,
            friendUid: friendUid,
            muted: muted,
          );
}

final cheersApiProvider = Provider<CheersApi>((ref) => _SecuredCheersApi(ref));

/// Friends' verified runs from the last 7 days. Server data only.
final friendRunsProvider = FutureProvider.autoDispose<List<FriendRun>>(
  (ref) => ref.watch(cheersApiProvider).runs(),
);

final cheerInboxProvider = FutureProvider.autoDispose<CheerInbox>(
  (ref) => ref.watch(cheersApiProvider).inbox(),
);

final cheerSettingsProvider = FutureProvider.autoDispose<CheerSettings>(
  (ref) => ref.watch(cheersApiProvider).settings(),
);

/// "Now". Tests replace it so "today" and "yesterday" are fixed.
final cheerClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
