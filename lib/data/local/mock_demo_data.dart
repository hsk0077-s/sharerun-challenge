import '../models/activity_model.dart';
import '../models/crew_member_ranking_model.dart';
import '../models/crew_ranking_model.dart';
import '../models/diamond_box_model.dart';
import '../models/sponsor_live_buff_model.dart';
import '../models/tournament_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../models/economy_state_model.dart';
import '../models/wallet_transaction_model.dart';
/// Static read-only demo data for UI-only local runs (USE_LOCAL_MOCK_DATA=true).
abstract final class MockDemoData {
  static const mockUid = 'local-mock-user';

  static UserModel userProfile() {
    final now = DateTime.now();
    return UserModel(
      uid: mockUid,
      watchType: WatchType.garmin,
      wallet: WalletModel(
        shareBalance: 90000,
        valueTokenBalance: 5200,
        diamondBalance: 5,
        totalDonationValue: 300,
      ),
      tier: 3,
      healthDataConsent: false,
      sensitiveDataConsent: false,
      termsAccepted: true,
      pushNotificationsEnabled: false,
      nickname: '달리기부자45',
      preliminaryRunsCount: 3,
      dailyDistance: 3.5,
      activityStreakCount: 3,
      runningShoeMileage: 420,
      economy: EconomyStateModel(
        signupRewardClaimed: true,
        trialRunCount: 3,
        trialMilestoneRewardClaimed: false,
        firstTierGranted: false,
        referralCode: 'SRC8A2F91',
        referredByUid: null,
        referralPayoutCount: 2,
        dailyMining: DailyMiningModel(
          dateKey:
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          earnedKm: 3.5,
          earnedSrvTokens: 35,
        ),
      ),
    );
  }

  static List<WalletTransactionModel> walletTransactions() {
    final now = DateTime(2026, 6, 22);
    return [
      WalletTransactionModel(
        id: 'mock-tx-signup',
        type: 'onboarding_signup_reward',
        shareAmount: 0,
        valueAmount: 100,
        diamondAmount: 0,
        createdAt: now.subtract(const Duration(days: 2)),
        tournamentId: null,
      ),
      WalletTransactionModel(
        id: 'mock-tx-mint',
        type: 'effort_value_mint',
        shareAmount: 0,
        valueAmount: 32,
        diamondAmount: 0,
        createdAt: now,
        tournamentId: null,
      ),
      WalletTransactionModel(
        id: 'mock-tx-referral',
        type: 'referral_reward',
        shareAmount: 0,
        valueAmount: 300,
        diamondAmount: 0,
        createdAt: now.subtract(const Duration(days: 1)),
        tournamentId: null,
      ),
      WalletTransactionModel(
        id: 'mock-tx-web3',
        type: 'web3_transfer',
        shareAmount: 0,
        valueAmount: -100,
        diamondAmount: 0,
        createdAt: now.subtract(const Duration(hours: 3)),
        tournamentId: null,
      ),
    ];
  }

  static SponsorLiveBuffModel activeSponsorBuff() {
    return const SponsorLiveBuffModel(
      sponsorName: '김민수',
      message: '현재 김민수님이 당신의 완주를 후원하고 있습니다',
    );
  }

  static List<TournamentModel> tournaments() {
    return [
      TournamentModel.fromJson(
        id: 'mock-tournament-rookie',
        json: {
          'title': 'Rookie 3K UNICEF Run',
          'targetDistanceKm': 3,
          'entryFeeShare': 100,
          'winnerRewardValue': 500,
          'donationValue': 200,
          'minParticipantsBep': 10,
          'maxParticipants': 100,
          'participantCount': 4,
          'requiredTier': 1,
          'status': 'recruiting',
          'sponsorName': 'UNICEF Partner',
          'sponsorBillboardMessages': [
            '🏃 UNICEF Partner: 오늘도 3K 완주에 도전하세요!',
            '💚 러너 여러분의 발걸음이 아이들에게 전달됩니다',
            '🎯 참가비의 일부가 기부 풀로 적립됩니다',
          ],
        },
      ),
      TournamentModel.fromJson(
        id: 'mock-tournament-sprint',
        json: {
          'title': 'Neon 5K Sprint',
          'targetDistanceKm': 5,
          'entryFeeShare': 200,
          'winnerRewardValue': 800,
          'donationValue': 350,
          'minParticipantsBep': 8,
          'maxParticipants': 50,
          'participantCount': 12,
          'requiredTier': 1,
          'status': 'active',
          'sponsorName': 'SRC Sponsor',
          'sponsorBillboardMessages': [
            '⚡ Neon 5K Sprint — SRC 스폰서가 응원합니다!',
            '🔥 완주 시 밸류 토큰 채굴 보너스 이벤트 진행 중',
            '🏆 크루원과 함께 페이스를 맞춰 보세요',
          ],
        },
      ),
    ];
  }

  static List<DiamondBoxModel> diamondBoxes() {
    return [
      DiamondBoxModel.fromJson(
        id: 'mock-box-park',
        json: {
          'title': 'Park Gate Diamond',
          'latitude': 37.5665,
          'longitude': 126.9780,
          'rewardDiamond': 3,
          'active': true,
        },
      ),
    ];
  }

  static List<ActivityModel> activities() {
    final now = DateTime.now();
    return [
      ActivityModel(
        id: 'mock-act-pending',
        userId: mockUid,
        distanceKm: 3.0,
        durationSeconds: 1080,
        averagePaceSecondsPerKm: 360,
        completedAt: now,
        validationStatus: ActivityValidationStatus.pending,
        jenaReason: 'pending',
      ),
      ActivityModel(
        id: 'mock-act-today',
        userId: mockUid,
        distanceKm: 2.1,
        durationSeconds: 720,
        averagePaceSecondsPerKm: 342.8,
        completedAt: DateTime(now.year, now.month, now.day, 7, 20),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
      ActivityModel(
        id: 'mock-act-yday',
        userId: mockUid,
        distanceKm: 1.4,
        durationSeconds: 480,
        averagePaceSecondsPerKm: 342.8,
        completedAt: now.subtract(const Duration(days: 1)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
      ActivityModel(
        id: 'mock-act-2d',
        userId: mockUid,
        distanceKm: 1.8,
        durationSeconds: 600,
        averagePaceSecondsPerKm: 333.3,
        completedAt: now.subtract(const Duration(days: 2)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
      ActivityModel(
        id: 'mock-act-1',
        userId: mockUid,
        distanceKm: 10.2,
        durationSeconds: 3180,
        averagePaceSecondsPerKm: 311.7,
        completedAt: now.subtract(const Duration(days: 1)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
      ActivityModel(
        id: 'mock-act-2',
        userId: mockUid,
        distanceKm: 5.5,
        durationSeconds: 1740,
        averagePaceSecondsPerKm: 316.3,
        completedAt: now.subtract(const Duration(days: 3)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
      ActivityModel(
        id: 'mock-act-3',
        userId: mockUid,
        distanceKm: 421.95,
        durationSeconds: 85800,
        averagePaceSecondsPerKm: 203.4,
        completedAt: now.subtract(const Duration(days: 120)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
      ActivityModel(
        id: 'mock-act-4',
        userId: mockUid,
        distanceKm: 8.0,
        durationSeconds: 2520,
        averagePaceSecondsPerKm: 315,
        completedAt: now.subtract(const Duration(days: 7)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
      ActivityModel(
        id: 'mock-act-5',
        userId: mockUid,
        distanceKm: 17.3,
        durationSeconds: 5580,
        averagePaceSecondsPerKm: 322.5,
        completedAt: now.subtract(const Duration(days: 14)),
        validationStatus: ActivityValidationStatus.verified,
        jenaReason: 'verified',
      ),
    ];
  }

  static List<CrewMemberRankingModel> crewMemberRankings() {
    return [
      CrewMemberRankingModel.fromJson(
        id: 'member-1',
        json: {
          'name': '민지',
          'attendanceRate': 96,
          'averagePaceSecondsPerKm': 298,
          'weeklyDistanceKm': 42.5,
        },
      ),
      CrewMemberRankingModel.fromJson(
        id: 'member-2',
        json: {
          'name': '준호',
          'attendanceRate': 88,
          'averagePaceSecondsPerKm': 315,
          'weeklyDistanceKm': 36.0,
        },
      ),
      CrewMemberRankingModel.fromJson(
        id: 'member-3',
        json: {
          'name': '서연',
          'attendanceRate': 92,
          'averagePaceSecondsPerKm': 332,
          'weeklyDistanceKm': 28.4,
        },
      ),
      CrewMemberRankingModel.fromJson(
        id: 'member-4',
        json: {
          'name': '태윤',
          'attendanceRate': 74,
          'averagePaceSecondsPerKm': 348,
          'weeklyDistanceKm': 18.2,
        },
      ),
    ];
  }

  static List<CrewRankingModel> crews() {
    return [
      CrewRankingModel.fromJson(
        id: 'mock-crew-neon',
        json: {
          'name': 'Neon Runners',
          'totalValue': 3200,
          'memberCount': 12,
        },
      ),
    ];
  }
}
