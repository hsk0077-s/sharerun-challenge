import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../data/models/shop_item_model.dart';
import '../battle_pass_grant.dart';
import '../cosmetics_catalog.dart';

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
    this.boostRunCount = 0,
    this.stepIncubatorCount = 0,
    this.battlePassTier = '',
    this.battlePassRewardIds = const [],
    this.ownedCosmeticIds = const {},
    this.loadout = const CosmeticLoadout(),
  });

  static const cprId = 'record_cpr_ticket';
  static const safeGuardId = 'record_safe_guard';
  static const ghostPaceId = 'ghost_pace_match';
  static const battlePassId = battlePassItemId;
  static const battlePassPlusId = battlePassPlusItemId;
  static const coachOnePointId = 'coach_one_point_ticket';
  static const extraEntryId = 'extra_entry_ticket';
  static const friendGhostId = 'friend_ghost_pace';
  static const friendGhostPackId = 'friend_ghost_pace_10pack';
  static const crewCheerId = 'crew_cheer_flag';
  static const boostRunId = 'boost_run';
  static const stepIncubatorId = 'step_incubator';

  final int cprCount;
  final int safeGuardCount;
  final int ghostPaceCount;
  final int battlePassCount;
  final int coachOnePointCount;
  final int extraEntryCount;
  final int friendGhostCount;
  final int crewCheerCount;
  final int boostRunCount;
  final int stepIncubatorCount;
  final String battlePassTier;
  final List<String> battlePassRewardIds;
  final Set<String> ownedCosmeticIds;
  final CosmeticLoadout loadout;

  BattlePassGrant get battlePass => BattlePassGrant(
        tier: battlePassTier,
        rewardIds: battlePassRewardIds,
      );

  bool get isEmpty =>
      cprCount <= 0 &&
      safeGuardCount <= 0 &&
      ghostPaceCount <= 0 &&
      battlePassCount <= 0 &&
      coachOnePointCount <= 0 &&
      extraEntryCount <= 0 &&
      friendGhostCount <= 0 &&
      crewCheerCount <= 0 &&
      boostRunCount <= 0 &&
      stepIncubatorCount <= 0;

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
      case boostRunId:
        return boostRunCount;
      case stepIncubatorId:
        return stepIncubatorCount;
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
      boostRunCount: quantities[boostRunId] ?? 0,
      stepIncubatorCount: quantities[stepIncubatorId] ?? 0,
    );
  }

  static ServerShopInventory fromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return fromDocMaps({
      for (final doc in snap.docs) doc.id: doc.data(),
    });
  }

  /// Inventory docs including cosmetic ownership and the equip loadout.
  static ServerShopInventory fromDocMaps(
    Map<String, Map<String, dynamic>> docs,
  ) {
    final quantities = <String, int>{};
    var grant = const BattlePassGrant();
    final owned = <String>{};
    var loadout = const CosmeticLoadout();
    for (final entry in docs.entries) {
      final data = entry.value;
      if (entry.key == cosmeticLoadoutDocId) {
        loadout = CosmeticLoadout.fromDoc(data);
        continue;
      }
      quantities[entry.key] = _qty(data['quantity']);
      if (entry.key == battlePassId) grant = battlePassGrantFromDoc(data);
      final category = data['category'];
      if (_qty(data['quantity']) >= 1 &&
          category is String &&
          cosmeticCategories.contains(category)) {
        owned.add(entry.key);
      }
    }
    return fromQuantities(quantities)
        .withBattlePass(grant)
        .withCosmetics(owned, loadout);
  }

  ServerShopInventory withBattlePass(BattlePassGrant grant) {
    return ServerShopInventory(
      cprCount: cprCount,
      safeGuardCount: safeGuardCount,
      ghostPaceCount: ghostPaceCount,
      battlePassCount: battlePassCount,
      coachOnePointCount: coachOnePointCount,
      extraEntryCount: extraEntryCount,
      friendGhostCount: friendGhostCount,
      crewCheerCount: crewCheerCount,
      boostRunCount: boostRunCount,
      stepIncubatorCount: stepIncubatorCount,
      battlePassTier: grant.tier,
      battlePassRewardIds: grant.rewardIds,
      ownedCosmeticIds: ownedCosmeticIds,
      loadout: loadout,
    );
  }

  ServerShopInventory withCosmetics(
    Set<String> owned,
    CosmeticLoadout equipped,
  ) {
    return ServerShopInventory(
      cprCount: cprCount,
      safeGuardCount: safeGuardCount,
      ghostPaceCount: ghostPaceCount,
      battlePassCount: battlePassCount,
      coachOnePointCount: coachOnePointCount,
      extraEntryCount: extraEntryCount,
      friendGhostCount: friendGhostCount,
      crewCheerCount: crewCheerCount,
      boostRunCount: boostRunCount,
      stepIncubatorCount: stepIncubatorCount,
      battlePassTier: battlePassTier,
      battlePassRewardIds: battlePassRewardIds,
      ownedCosmeticIds: Set.unmodifiable(owned),
      loadout: equipped,
    );
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
