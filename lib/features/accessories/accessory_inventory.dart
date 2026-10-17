import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';

/// 내가 산 소품(서버 `shopInventory`의 `category: accessory`)과 입고 있는 것.
@immutable
class AccessoryInventory {
  const AccessoryInventory({this.owned = const {}, this.worn = const {}});

  final Set<String> owned;

  /// 칸 이름(`head` …) → 입은 소품 id.
  final Map<String, String> worn;

  bool owns(String id) => owned.contains(id);
  bool isWorn(String id) => worn.containsValue(id);

  static const loadoutDocId = 'accessory_loadout';

  static AccessoryInventory fromDocs(Map<String, Map<String, dynamic>> docs) {
    final owned = <String>{};
    var worn = <String, String>{};
    for (final entry in docs.entries) {
      final data = entry.value;
      if (entry.key == loadoutDocId) {
        final slots = data['slots'];
        if (slots is Map) {
          worn = {
            for (final e in slots.entries)
              if (e.key is String && e.value is String && (e.value as String).isNotEmpty)
                e.key as String: e.value as String,
          };
        }
        continue;
      }
      final quantity = data['quantity'];
      if (data['category'] == 'accessory' && quantity is num && quantity >= 1) {
        owned.add(entry.key);
      }
    }
    return AccessoryInventory(owned: owned, worn: worn);
  }
}

final accessoryInventoryProvider = StreamProvider<AccessoryInventory>((ref) {
  try {
    if (Firebase.apps.isEmpty) return Stream.value(const AccessoryInventory());
  } catch (_) {
    return Stream.value(const AccessoryInventory());
  }
  final authUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final sessionUid = ref.watch(persistedAuthSessionProvider)?.uid ?? '';
  final uid = authUid.isNotEmpty ? authUid : sessionUid;
  if (uid.isEmpty) return Stream.value(const AccessoryInventory());
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('shopInventory')
      .snapshots()
      .map((snap) => AccessoryInventory.fromDocs({
            for (final doc in snap.docs) doc.id: doc.data(),
          }));
});
