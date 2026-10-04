import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/api/api_exception.dart';
import '../iap/providers/coach_plus_providers.dart';
import 'providers/server_shop_inventory_provider.dart';
import 'shop_request_ids.dart';

/// Server statuses that open Coach+ pace cues for this run.
bool coachOnePointStatusUnlocks(String status) {
  return status == 'used' || status == 'already_used';
}

/// True only after the server confirms this run spent a 코치 원포인트권.
/// Coach+ subscribers never spend one; their profile already opens the cues.
final coachOnePointRunProvider =
    NotifierProvider<CoachOnePointRunNotifier, bool>(
  CoachOnePointRunNotifier.new,
);

class CoachOnePointRunNotifier extends Notifier<bool> {
  var _busy = false;
  var _unlocked = false;
  var _generation = 0;
  String? _requestId;

  @override
  bool build() => false;

  Future<void> claimIfNeeded() async {
    if (_unlocked || _busy) return;
    if (ref.read(coachPlusActiveProvider)) return;
    final owned = ref
            .read(serverShopInventoryProvider)
            .asData
            ?.value
            .coachOnePointCount ??
        0;
    if (owned <= 0 && _requestId == null) return;
    final generation = _generation;
    _busy = true;
    _requestId ??= mintShopRequestId();
    try {
      final status = await ref
          .read(securedActionApiClientProvider)
          .useCoachOnePoint(_requestId!);
      if (generation != _generation) return;
      if (coachOnePointStatusUnlocks(status)) {
        _unlocked = true;
        _requestId = null;
        state = true;
      } else {
        state = false;
        _requestId = null;
      }
    } on ApiException catch (error) {
      if (generation != _generation) return;
      state = false;
      if (error.statusCode < 500) _requestId = null;
    } catch (_) {
      if (generation != _generation) return;
      state = false;
    } finally {
      if (generation == _generation) _busy = false;
    }
  }

  void endRun() {
    _generation += 1;
    _unlocked = false;
    _busy = false;
    _requestId = null;
    state = false;
  }
}
