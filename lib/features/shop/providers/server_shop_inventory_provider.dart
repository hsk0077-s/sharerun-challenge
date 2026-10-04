import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/shop_item_model.dart';

/// Account inventory from `users/{uid}/shopInventory/{itemId}.quantity`.
///
/// Shop purchase already writes this in the same transaction as the diamond
/// debit. Display reads it. Device SharedPreferences are not a count.
class ServerShopInventory {
  const ServerShopInventory({
    this.cprCount = 0,
    this.safeGuardCount = 0,
    this.ghostPaceCount = 0,
    this.battlePassCount = 0,
    this.coachOnePointCount = 0,
    this.extraEntryCount = 0,
    this.friendGhostCount = 0,
    this.crewCheerCount = 0,
  });

  static const cprId = 'record_cpr_ticket';
  static const safeGuardId = 'record_safe_guard';
  static const ghostPaceId = 'ghost_pace_match';
  static const battlePassId = 'battle_run_pass';
  static const coachOnePointId = 'coach_one_point_ticket';
  static const extraEntryId = 'extra_entry_ticket';
  static const friendGhostId = 'friend_ghost_pace';
  static const friendGhostPackId = 'friend_ghost_pace_10pack';
  static const crewCheerId = 'crew_cheer_flag';

  final int cprCount;
  final int safeGuardCount;
  final int ghostPaceCount;
  final int battlePassCount;
  final int coachOnePointCount;
  final int extraEntryCount;
  final int friendGhostCount;
  final int crewCheerCount;

  bool get isEmpty =>
      cprCount <= 0 &&
      safeGuardCount <= 0 &&
      ghostPaceCount <= 0 &&
      battlePassCount <= 0 &&
      coachOnePointCount <= 0 &&
      extraEntryCount <= 0 &&
      friendGhostCount <= 0 &&
      crewCheerCount <= 0;

  int countFor(String itemId) {
    switch (itemId) {
      case cprId:
        return cprCount;
      case safeGuardId:
        return safeGuardCount;
      case ghostPaceId:
        return ghostPaceCount;
      case battlePassId:
        return battlePassCount;
      case coachOnePointId:
        return coachOnePointCount;
      case extraEntryId:
        return extraEntryCount;
      case friendGhostId:
      case friendGhostPackId:
        return friendGhostCount;
      case crewCheerId:
        return crewCheerCount;
      default:
        return 0;
    }
  }

  static int _qty(Object? raw) {
    if (raw is int) return raw < 0 ? 0 : raw;
    if (raw is num) {
      final value = raw.toInt();
      return value < 0 ? 0 : value;
    }
    return 0;
  }

  /// Maps catalog document ids to counts. Unknown ids stay at 0 on every phone.
  static ServerShopInventory fromQuantities(Map<String, int> quantities) {
    return ServerShopInventory(
      cprCount: quantities[cprId] ?? 0,
      safeGuardCount: quantities[safeGuardId] ?? 0,
      ghostPaceCount: quantities[ghostPaceId] ?? 0,
      battlePassCount: quantities[battlePassId] ?? 0,
      coachOnePointCount: quantities[coachOnePointId] ?? 0,
      extraEntryCount: quantities[extraEntryId] ?? 0,
      friendGhostCount: quantities[friendGhostId] ?? 0,
      crewCheerCount: quantities[crewCheerId] ?? 0,
    );
  }

  static ServerShopInventory fromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final quantities = <String, int>{};
    for (final doc in snap.docs) {
      quantities[doc.id] = _qty(doc.data()['quantity']);
    }
    return fromQuantities(quantities);
  }
}

String? serverShopItemTitle(String itemId) {
  for (final item in ShopItemModel.catalog) {
    if (item.id == itemId) return item.title;
  }
  return null;
}

final serverShopInventoryProvider = StreamProvider<ServerShopInventory>((ref) {
  if (!_firestoreReady()) {
    return Stream.value(const ServerShopInventory());
  }
  final authUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final sessionUid = ref.watch(persistedAuthSessionProvider)?.uid ?? '';
  final uid = authUid.isNotEmpty ? authUid : sessionUid;
  if (uid.isEmpty) return Stream.value(const ServerShopInventory());
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('shopInventory')
      .snapshots()
      .map(ServerShopInventory.fromSnapshot);
});

bool _firestoreReady() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
