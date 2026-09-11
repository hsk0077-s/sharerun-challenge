/// Body of `POST /actions/tournaments/join`.
class TournamentJoinResult {
  const TournamentJoinResult({
    this.accepted = true,
    this.status = '',
    this.shareCredited = 0,
    this.shareBalance,
  });

  final bool accepted;
  final String status;
  final int shareCredited;
  final int? shareBalance;

  bool get alreadyJoined => status == 'already_joined';

  factory TournamentJoinResult.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return const TournamentJoinResult();
    }
    return TournamentJoinResult(
      accepted: json['accepted'] as bool? ?? true,
      status: json['status'] as String? ?? '',
      shareCredited: _readInt(json, const [
            'share_credited',
            'shareCredited',
          ]) ??
          0,
      shareBalance: _readInt(json, const [
        'share_balance',
        'shareBalance',
      ]),
    );
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toInt();
    }
    return null;
  }
}
