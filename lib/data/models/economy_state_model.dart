import '../../core/constants/economy_constants.dart';

class DailyMiningModel {
  const DailyMiningModel({
    required this.dateKey,
    required this.earnedKm,
    required this.earnedSrvTokens,
  });

  final String dateKey;
  final double earnedKm;
  final int earnedSrvTokens;

  double get kmProgress =>
      (earnedKm / EconomyConstants.dailyCapKm).clamp(0.0, 1.0);

  double get tokenProgress =>
      (earnedSrvTokens / EconomyConstants.dailyCapSrvTokens).clamp(0.0, 1.0);

  bool get isCapReached =>
      earnedKm >= EconomyConstants.dailyCapKm ||
      earnedSrvTokens >= EconomyConstants.dailyCapSrvTokens;

  factory DailyMiningModel.empty() {
    return const DailyMiningModel(
      dateKey: '',
      earnedKm: 0,
      earnedSrvTokens: 0,
    );
  }

  factory DailyMiningModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DailyMiningModel.empty();
    }
    return DailyMiningModel(
      dateKey: json['dateKey'] as String? ?? '',
      earnedKm: (json['earnedKm'] as num?)?.toDouble() ?? 0,
      earnedSrvTokens: (json['earnedSrvTokens'] as num?)?.toInt() ?? 0,
    );
  }
}

class EconomyStateModel {
  const EconomyStateModel({
    required this.signupRewardClaimed,
    required this.trialRunCount,
    required this.trialMilestoneRewardClaimed,
    required this.firstTierGranted,
    required this.referralCode,
    required this.referredByUid,
    required this.referralPayoutCount,
    required this.dailyMining,
  });

  final bool signupRewardClaimed;
  final int trialRunCount;
  final bool trialMilestoneRewardClaimed;
  final bool firstTierGranted;
  final String? referralCode;
  final String? referredByUid;
  final int referralPayoutCount;
  final DailyMiningModel dailyMining;

  double get trialProgress =>
      (trialRunCount / EconomyConstants.trialRunsRequired).clamp(0.0, 1.0);

  double get referralProgress =>
      (referralPayoutCount / EconomyConstants.maxReferralPayouts)
          .clamp(0.0, 1.0);

  factory EconomyStateModel.empty() {
    return EconomyStateModel(
      signupRewardClaimed: false,
      trialRunCount: 0,
      trialMilestoneRewardClaimed: false,
      firstTierGranted: false,
      referralCode: null,
      referredByUid: null,
      referralPayoutCount: 0,
      dailyMining: DailyMiningModel.empty(),
    );
  }

  factory EconomyStateModel.fromJson({
    Map<String, dynamic>? economy,
    Map<String, dynamic>? dailyMining,
  }) {
    economy ??= {};
    return EconomyStateModel(
      signupRewardClaimed: economy['signupRewardClaimed'] as bool? ?? false,
      trialRunCount: (economy['trialRunCount'] as num?)?.toInt() ?? 0,
      trialMilestoneRewardClaimed:
          economy['trialMilestoneRewardClaimed'] as bool? ?? false,
      firstTierGranted: economy['firstTierGranted'] as bool? ?? false,
      referralCode: economy['referralCode'] as String?,
      referredByUid: economy['referredByUid'] as String?,
      referralPayoutCount:
          (economy['referralPayoutCount'] as num?)?.toInt() ?? 0,
      dailyMining: DailyMiningModel.fromJson(dailyMining),
    );
  }
}
