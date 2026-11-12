import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import 'world_tour_coordinator.dart';
import 'world_tour_models.dart';
import 'world_tour_pending_store.dart';

/// Production API: the secured-action client already holds the base URL and
/// the Firebase token.
class _SecuredWorldTourApi implements WorldTourApi {
  const _SecuredWorldTourApi(this._ref);
  final Ref _ref;

  @override
  Future<WorldTourMe> fetchMe() =>
      _ref.read(securedActionApiClientProvider).fetchWorldTourMe();

  @override
  Future<WorldTourAttachResult> attach({
    required String missionId,
    required String activityId,
  }) =>
      _ref.read(securedActionApiClientProvider).attachWorldTourRun(
            missionId: missionId,
            activityId: activityId,
          );
}

final worldTourApiProvider = Provider<WorldTourApi>(
  (ref) => _SecuredWorldTourApi(ref),
);

final worldTourPendingStoreProvider = Provider<WorldTourPendingStore>(
  (ref) => WorldTourPendingStore(),
);

final worldTourCoordinatorProvider = Provider<WorldTourCoordinator>(
  (ref) => WorldTourCoordinator(
    api: () => ref.read(worldTourApiProvider),
    store: ref.read(worldTourPendingStoreProvider),
  ),
);

/// The catalog with this user's progress, and the passport. Server data only.
final worldTourMeProvider = FutureProvider.autoDispose<WorldTourMe>(
  (ref) => ref.watch(worldTourApiProvider).fetchMe(),
);
