/// Friend connection models. They mirror the server answers of
/// `/actions/friends/*`. Nothing here carries a place, a route or a run record.
class FriendInvite {
  const FriendInvite({
    required this.token,
    required this.qrPayload,
    required this.expiresAt,
  });

  final String token;

  /// "sharerun-friend:TOKEN". It is shown and shared as text. It is not
  /// drawn as a QR code.
  final String qrPayload;
  final DateTime? expiresAt;

  factory FriendInvite.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? '';
    final payload = json['qr_payload'] as String? ?? '';
    return FriendInvite(
      token: token,
      qrPayload: payload.isNotEmpty ? payload : 'sharerun-friend:$token',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
    );
  }
}

class FriendAcceptResult {
  const FriendAcceptResult({required this.status, required this.friendUid});

  /// "added" or "already_friends".
  final String status;
  final String friendUid;

  bool get alreadyFriends => status == 'already_friends';

  factory FriendAcceptResult.fromJson(Map<String, dynamic> json) {
    return FriendAcceptResult(
      status: json['status'] as String? ?? 'added',
      friendUid: json['friend_uid'] as String? ?? '',
    );
  }
}

class Friend {
  const Friend({required this.uid, required this.nickname, this.createdAt});

  final String uid;

  /// May be empty. The screen then shows a stand-in name.
  final String nickname;
  final DateTime? createdAt;

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      uid: json['uid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// Why a person is reported while being blocked. The server accepts exactly
/// these five.
enum FriendReportReason {
  offensiveName('offensive_name'),
  sexual('sexual'),
  hate('hate'),
  spam('spam'),
  other('other');

  const FriendReportReason(this.wire);
  final String wire;
}
