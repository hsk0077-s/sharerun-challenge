/// Friend cheer models. They mirror `/actions/friends/runs` and
/// `/actions/cheers/*`. Nothing here carries a place, a route or a start time.
library;

/// The five fixed cheers. There is no free text.
enum CheerReaction {
  clap('clap', '👏'),
  fire('fire', '🔥'),
  muscle('muscle', '💪'),
  heart('heart', '❤️'),
  thumbs('thumbs', '👍');

  const CheerReaction(this.wire, this.emoji);

  /// The value the server sends and accepts.
  final String wire;
  final String emoji;

  /// Null for a value this app version does not know.
  static CheerReaction? fromWire(Object? value) {
    for (final reaction in values) {
      if (reaction.wire == value) return reaction;
    }
    return null;
  }
}

/// One verified run of a friend: distance, time and the KST date only.
class FriendRun {
  const FriendRun({
    required this.activityId,
    required this.friendUid,
    required this.nickname,
    required this.distanceKm,
    required this.durationSeconds,
    required this.kstDate,
    this.myReactionWire,
  });

  final String activityId;
  final String friendUid;

  /// May be empty. The screen then shows a stand-in name.
  final String nickname;
  final double distanceKm;
  final int durationSeconds;

  /// "YYYY-MM-DD" in Korea time.
  final String kstDate;

  /// What the server says this person already sent. Kept raw so a value from a
  /// newer server still counts as "already cheered".
  final String? myReactionWire;

  bool get cheered => myReactionWire != null;
  CheerReaction? get myReaction => CheerReaction.fromWire(myReactionWire);

  /// Null when the row has no usable id.
  static FriendRun? tryParse(Object? json) {
    if (json is! Map) return null;
    final activityId = json['activity_id'];
    final friendUid = json['friend_uid'];
    if (activityId is! String || activityId.isEmpty) return null;
    if (friendUid is! String || friendUid.isEmpty) return null;
    final reaction = json['my_reaction'];
    return FriendRun(
      activityId: activityId,
      friendUid: friendUid,
      nickname: json['nickname'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      kstDate: json['kst_date'] as String? ?? '',
      myReactionWire: reaction is String && reaction.isNotEmpty ? reaction : null,
    );
  }

  static List<FriendRun> listFromJson(Map<String, dynamic> json) {
    final rows = json['runs'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (FriendRun.tryParse(row) case final run?) run,
    ];
  }
}

/// One cheer received.
class ReceivedCheer {
  const ReceivedCheer({
    required this.fromUid,
    required this.nickname,
    required this.activityId,
    required this.reaction,
    this.createdAt,
  });

  final String fromUid;
  final String nickname;
  final String activityId;
  final CheerReaction reaction;
  final DateTime? createdAt;

  /// Null for a row with a cheer this app does not know. The row is skipped.
  static ReceivedCheer? tryParse(Object? json) {
    if (json is! Map) return null;
    final reaction = CheerReaction.fromWire(json['reaction']);
    final fromUid = json['from_uid'];
    if (reaction == null || fromUid is! String || fromUid.isEmpty) return null;
    return ReceivedCheer(
      fromUid: fromUid,
      nickname: json['nickname'] as String? ?? '',
      activityId: json['activity_id'] as String? ?? '',
      reaction: reaction,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class CheerInbox {
  const CheerInbox({required this.cheers, required this.unreadCount});

  final List<ReceivedCheer> cheers;
  final int unreadCount;

  factory CheerInbox.fromJson(Map<String, dynamic> json) {
    final rows = json['cheers'];
    return CheerInbox(
      cheers: [
        if (rows is List)
          for (final row in rows)
            if (ReceivedCheer.tryParse(row) case final cheer?) cheer,
      ],
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CheerSettings {
  const CheerSettings({required this.muteAll, required this.mutedFriends});

  final bool muteAll;
  final List<String> mutedFriends;

  factory CheerSettings.fromJson(Map<String, dynamic> json) {
    final muted = json['muted_friends'];
    return CheerSettings(
      muteAll: json['mute_all'] == true,
      mutedFriends: [
        if (muted is List)
          for (final uid in muted)
            if (uid is String) uid,
      ],
    );
  }

  CheerSettings copyWith({bool? muteAll, List<String>? mutedFriends}) {
    return CheerSettings(
      muteAll: muteAll ?? this.muteAll,
      mutedFriends: mutedFriends ?? this.mutedFriends,
    );
  }
}
