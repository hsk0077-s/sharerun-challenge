import '../api/secured_action_api_client.dart';
import '../models/winner_reward_action.dart';

class RewardRepository {
  RewardRepository(this._securedActionApiClient);

  final SecuredActionApiClient _securedActionApiClient;

  Future<void> applyWinnerReward({
    required String activityId,
    required WinnerRewardAction action,
  }) {
    return _securedActionApiClient.applyWinnerReward(
      activityId: activityId,
      action: action,
    );
  }
}
