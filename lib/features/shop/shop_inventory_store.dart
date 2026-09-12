import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Client-owned shop inventory.
///
/// Server [mergeEconomyState] is a no-op and Firestore `hasCPR` only covers
/// CPR, so CPR / Safeguard / Star Boost / SHARE pack must survive kill +
/// relaunch in SharedPreferences.
class ShopInventorySnapshot {
  const ShopInventorySnapshot({
    this.cprCount = 0,
    this.safeGuardCount = 0,
    this.starBoostCount = 0,
    this.sharePackCount = 0,
  });

  final int cprCount;
  final int safeGuardCount;
  final int starBoostCount;
  final int sharePackCount;

  bool get hasOwnedItems =>
      cprCount > 0 ||
      safeGuardCount > 0 ||
      starBoostCount > 0 ||
      sharePackCount > 0;

  Map<String, int> toJson() => {
        'cprCount': cprCount,
        'safeGuardCount': safeGuardCount,
        'starBoostCount': starBoostCount,
        'sharePackCount': sharePackCount,
      };

  factory ShopInventorySnapshot.fromJson(Map<String, dynamic> json) {
    return ShopInventorySnapshot(
      cprCount: _nonNeg(json['cprCount']),
      safeGuardCount: _nonNeg(json['safeGuardCount']),
      starBoostCount: _nonNeg(json['starBoostCount']),
      sharePackCount: _nonNeg(json['sharePackCount']),
    );
  }

  static ShopInventorySnapshot mergeMax(
    ShopInventorySnapshot a,
    ShopInventorySnapshot b,
  ) {
    return ShopInventorySnapshot(
      cprCount: a.cprCount > b.cprCount ? a.cprCount : b.cprCount,
      safeGuardCount: a.safeGuardCount > b.safeGuardCount
          ? a.safeGuardCount
          : b.safeGuardCount,
      starBoostCount: a.starBoostCount > b.starBoostCount
          ? a.starBoostCount
          : b.starBoostCount,
      sharePackCount: a.sharePackCount > b.sharePackCount
          ? a.sharePackCount
          : b.sharePackCount,
    );
  }

  static int _nonNeg(Object? raw) {
    if (raw is num) {
      final value = raw.toInt();
      return value < 0 ? 0 : value;
    }
    return 0;
  }
}

abstract final class ShopInventoryStore {
  static const prefsKey = 'shopInventory_local';

  static String prefsKeyForUid(String uid) => 'shopInventory_$uid';

  static ShopInventorySnapshot parse(String? raw) {
    if (raw == null || raw.isEmpty) return const ShopInventorySnapshot();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ShopInventorySnapshot();
      return ShopInventorySnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const ShopInventorySnapshot();
    }
  }

  static String encode(ShopInventorySnapshot inventory) =>
      jsonEncode(inventory.toJson());

  static ShopInventorySnapshot hydrate(
    SharedPreferences prefs, {
    String uid = '',
  }) {
    final local = parse(prefs.getString(prefsKey));
    if (uid.isEmpty) return local;
    return ShopInventorySnapshot.mergeMax(
      local,
      parse(prefs.getString(prefsKeyForUid(uid))),
    );
  }

  static Future<void> persist({
    required SharedPreferences prefs,
    required ShopInventorySnapshot inventory,
    String uid = '',
  }) async {
    final encoded = encode(inventory);
    await prefs.setString(prefsKey, encoded);
    if (uid.isNotEmpty) {
      await prefs.setString(prefsKeyForUid(uid), encoded);
    }
  }
}
