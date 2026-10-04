/// Payload for Crew tab 「새 크루 창설하기」.
///
/// Rules compare nested `wallet.shareBalance`, not a literal dotted key.
/// `Transaction.update` sends `wallet.shareBalance` as a field path.
/// `set(merge)` does not, and a leftover literal key must not win in rules.
abstract final class CrewFoundingWrite {
  /// Same number as `SrcWalletPaymentSystem.crewCreateShareCost`.
  /// Clients cannot debit this in `firestore.rules`; the server charges it.
  static const shareCost = 30000;

  static final crewIdPattern = RegExp(r'^[A-Za-z0-9]{20}$');

  /// Keys merged onto `users/{uid}` besides `updatedAt` (server timestamp).
  static const userMergeKeys = <String>[
    'wallet.shareBalance',
    'ownedCrewId',
  ];

  static bool isCrewId(String id) => crewIdPattern.hasMatch(id);

  /// Null when [shareCost] is not the fixed founding cost or balance is short.
  static int? shareAfter({
    required int availableShare,
    required int shareCost,
  }) {
    if (shareCost != CrewFoundingWrite.shareCost) return null;
    if (availableShare < shareCost) return null;
    return availableShare - shareCost;
  }

  static Map<String, Object> userMergeFields({
    required int shareAfter,
    required String crewId,
  }) {
    if (shareAfter < 0) {
      throw ArgumentError.value(shareAfter, 'shareAfter');
    }
    if (!isCrewId(crewId)) {
      throw ArgumentError.value(crewId, 'crewId');
    }
    return {
      'wallet.shareBalance': shareAfter,
      'ownedCrewId': crewId,
    };
  }

  /// Crew document fields besides `createdAt` (server timestamp).
  static Map<String, Object> crewFields({
    required String name,
    required String ownerUid,
    required int shareCost,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      throw ArgumentError.value(name, 'name');
    }
    if (ownerUid.isEmpty) {
      throw ArgumentError.value(ownerUid, 'ownerUid');
    }
    if (shareCost != CrewFoundingWrite.shareCost) {
      throw ArgumentError.value(shareCost, 'shareCost');
    }
    return {
      'name': trimmed,
      'ownerUid': ownerUid,
      'totalValue': 0,
      'memberCount': 1,
      'shareCost': shareCost,
    };
  }
}
