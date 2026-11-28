/// What the server decided for one uploaded run, for the summary's one line.
///
/// The watch never works out a reward itself. It shows only what
/// `POST /actions/runs/validate` answered:
///   * `verified` — the run counted,
///   * `value_token_reward` — VALUE credited for this run (after the daily cap),
///   * `daily_cap_applied` — today's cap cut the reward.
/// Until the run is uploaded the line says it will be confirmed after upload.
enum RunRewardKind {
  /// Not uploaded yet (offline, or the last try failed).
  pending,

  /// An upload is on its way; the server has not answered yet.
  checking,

  /// Verified and VALUE was credited. [RunReward.value] is the amount.
  confirmed,

  /// Verified, but today's cap left nothing to credit.
  capReached,

  /// Verified with nothing to credit for another reason (for example a race
  /// run that pays later). The run itself still counts.
  noReward,

  /// The server did not accept the run as a verified run.
  notCounted,
}

class RunReward {
  const RunReward._(this.kind, [this.value = 0]);

  static const pending = RunReward._(RunRewardKind.pending);
  static const checking = RunReward._(RunRewardKind.checking);

  /// The summary line for a finished run, or null to hide it.
  ///
  /// Hidden when nothing was queued to upload ([queued] false, for example a
  /// zero-distance run). Otherwise the server's answer if there is one, else
  /// "checking" while an upload is on its way, else "confirmed after upload".
  static RunReward? forSummary({
    required bool queued,
    required RunReward? answer,
    required bool uploading,
  }) {
    if (answer != null) return answer;
    if (!queued) return null;
    return uploading ? checking : pending;
  }

  final RunRewardKind kind;

  /// VALUE credited. Only set for [RunRewardKind.confirmed].
  final int value;

  /// The server's reply to one validate upload. [status] is the HTTP status.
  ///
  /// 2xx: read `verified`, `value_token_reward`, `daily_cap_applied`.
  /// 400/409/413/422: the server will never accept this body, so it did not count.
  /// Anything else (offline, 429, 5xx) is still pending and returns null.
  static RunReward? fromReply(int status, Map<String, Object?> body) {
    if (status >= 200 && status < 300) {
      if (body['verified'] != true) return const RunReward._(RunRewardKind.notCounted);
      final raw = body['value_token_reward'];
      final value = raw is num && raw.isFinite ? raw.toInt() : 0;
      if (value > 0) return RunReward._(RunRewardKind.confirmed, value);
      if (body['daily_cap_applied'] == true) {
        return const RunReward._(RunRewardKind.capReached);
      }
      return const RunReward._(RunRewardKind.noReward);
    }
    if (status == 400 || status == 409 || status == 413 || status == 422) {
      return const RunReward._(RunRewardKind.notCounted);
    }
    return null;
  }

  /// The `watchUiRows` key for this line.
  String get copyKey => switch (kind) {
        RunRewardKind.pending => 'rewardPending',
        RunRewardKind.checking => 'rewardChecking',
        RunRewardKind.confirmed => 'rewardConfirmed',
        RunRewardKind.capReached => 'rewardCapReached',
        RunRewardKind.noReward => 'rewardNone',
        RunRewardKind.notCounted => 'rewardNotCounted',
      };

  @override
  bool operator ==(Object other) =>
      other is RunReward && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => 'RunReward($kind, $value)';
}
