enum WinnerRewardAction {
  claimAll,
  donateHalf,
  donateAll,
}

extension WinnerRewardActionLabel on WinnerRewardAction {
  String get transactionType {
    return switch (this) {
      WinnerRewardAction.claimAll => 'winner_reward_claim_all',
      WinnerRewardAction.donateHalf => 'winner_reward_donate_half',
      WinnerRewardAction.donateAll => 'winner_reward_donate_all',
    };
  }
}
