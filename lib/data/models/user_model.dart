import 'wallet_model.dart';
import 'economy_state_model.dart';

enum WatchType {
  none,
  appleWatch,
  galaxyWatch,
  garmin,
  coros,
  suunto,
}

extension WatchTypeCode on WatchType {
  String get code {
    return switch (this) {
      WatchType.none => 'none',
      WatchType.appleWatch => 'apple_watch',
      WatchType.galaxyWatch => 'galaxy_watch',
      WatchType.garmin => 'garmin',
      WatchType.coros => 'coros',
      WatchType.suunto => 'suunto',
    };
  }

  String get displayLabel {
    return switch (this) {
      WatchType.none => '미연동',
      WatchType.appleWatch => 'Apple Watch',
      WatchType.galaxyWatch => 'Galaxy Watch',
      WatchType.garmin => 'Garmin',
      WatchType.coros => 'Coros',
      WatchType.suunto => 'Suunto',
    };
  }

  bool get isOsDirectTrack {
    return this == WatchType.appleWatch || this == WatchType.galaxyWatch;
  }

  bool get isApiTrack {
    return this == WatchType.garmin ||
        this == WatchType.coros ||
        this == WatchType.suunto;
  }

  static WatchType fromCode(String? code) {
    return switch (code) {
      'apple_watch' => WatchType.appleWatch,
      'galaxy_watch' => WatchType.galaxyWatch,
      'garmin' => WatchType.garmin,
      'coros' => WatchType.coros,
      'suunto' => WatchType.suunto,
      _ => WatchType.none,
    };
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.watchType,
    required this.wallet,
    required this.tier,
    required this.healthDataConsent,
    required this.sensitiveDataConsent,
    required this.termsAccepted,
    required this.pushNotificationsEnabled,
    required this.economy,
    this.nickname = '',
    this.preliminaryRunsCount = 0,
    this.gender = 'male',
    this.donationCount = 0,
    this.cumulativeDonationAmount = 0,
    this.dailyDistance = 0,
    this.activityStreakCount = 0,
    this.runningShoeMileage = 0,
    this.streakBonusWeekKey = '',
    this.shoeAlertTierSent = 0,
    this.goldenHourAlertDateKey = '',
    this.lastJenaPendingNotifiedId = '',
    this.preferredRunHour = 19,
    this.hasCPR = false,
    this.isSponsored = false,
  });

  final String uid;
  final WatchType watchType;
  final WalletModel wallet;
  final int tier;
  final bool healthDataConsent;
  final bool sensitiveDataConsent;
  final bool termsAccepted;
  final bool pushNotificationsEnabled;
  final EconomyStateModel economy;

  /// Display name shown on the main dashboard header.
  final String nickname;

  /// Completed solo grade-review runs (e.g. 3 of 5).
  final int preliminaryRunsCount;

  /// Profile gender — `'male'` | `'female'`. Default male.
  final String gender;

  /// 누적 후원 횟수. 0이면 예비 천사.
  final int donationCount;

  /// 누적 후원 금액(원). 100 SHARE = 100원.
  final int cumulativeDonationAmount;

  /// 당일 개인 채굴 거리(km).
  final double dailyDistance;

  /// 연속 출석 일수.
  final int activityStreakCount;

  /// 등록 러닝화 누적 주행(km).
  final double runningShoeMileage;

  /// 7일 스트릭 DIA 보너스를 지급한 ISO 주 키.
  final String streakBonusWeekKey;

  /// 러닝화 경보 단계. 0 / 80 / 100.
  final int shoeAlertTierSent;

  /// 골든아워 리마인더를 보낸 날짜 키.
  final String goldenHourAlertDateKey;

  /// Jena 보류 푸시를 보낸 세션 id.
  final String lastJenaPendingNotifiedId;

  /// 평소 러닝 시각(0–23). 기본 19시.
  final int preferredRunHour;

  /// 심폐소생권(CPR) 보유. 앱 재설치 후 Firestore에서 복원.
  final bool hasCPR;

  /// 스폰서/글로벌 기부 참여 여부. 앱 재설치 후 Firestore에서 복원.
  final bool isSponsored;

  /// Convenience alias used by dashboard wallet bindings.
  int get share => wallet.shareBalance;

  int get diamondBalance => wallet.diamondBalance;

  int get shareBalance => wallet.shareBalance;

  int get valueBalance => wallet.valueTokenBalance;

  /// JSON/원격 null·음수 방어. 항상 0 이상.
  int get safeDonationCount => donationCount < 0 ? 0 : donationCount;

  int get safeCumulativeDonationAmount =>
      cumulativeDonationAmount < 0 ? 0 : cumulativeDonationAmount;

  double get safeDailyDistance => dailyDistance < 0 ? 0 : dailyDistance;

  int get safeActivityStreakCount =>
      activityStreakCount < 0 ? 0 : activityStreakCount;

  double get safeRunningShoeMileage =>
      runningShoeMileage < 0 ? 0 : runningShoeMileage;

  static int nonNegativeInt(Object? raw) {
    if (raw is num) {
      final value = raw.toInt();
      return value < 0 ? 0 : value;
    }
    return 0;
  }

  static double nonNegativeDouble(Object? raw) {
    if (raw is num) {
      final value = raw.toDouble();
      return value < 0 ? 0 : value;
    }
    return 0;
  }

  bool get isFemale => gender == 'female';

  static int _preferredHour(Object? raw) {
    if (raw == null) return 19;
    final hour = UserModel.nonNegativeInt(raw);
    return hour > 23 ? 19 : hour;
  }

  static String normalizeGender(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == 'female' || value == 'f' || value == '여' || value == '여성') {
      return 'female';
    }
    return 'male';
  }

  UserModel copyWith({
    String? uid,
    WatchType? watchType,
    WalletModel? wallet,
    int? tier,
    bool? healthDataConsent,
    bool? sensitiveDataConsent,
    bool? termsAccepted,
    bool? pushNotificationsEnabled,
    EconomyStateModel? economy,
    String? nickname,
    int? preliminaryRunsCount,
    String? gender,
    int? donationCount,
    int? cumulativeDonationAmount,
    double? dailyDistance,
    int? activityStreakCount,
    double? runningShoeMileage,
    String? streakBonusWeekKey,
    int? shoeAlertTierSent,
    String? goldenHourAlertDateKey,
    String? lastJenaPendingNotifiedId,
    int? preferredRunHour,
    bool? hasCPR,
    bool? isSponsored,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      watchType: watchType ?? this.watchType,
      wallet: wallet ?? this.wallet,
      tier: tier ?? this.tier,
      healthDataConsent: healthDataConsent ?? this.healthDataConsent,
      sensitiveDataConsent: sensitiveDataConsent ?? this.sensitiveDataConsent,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      economy: economy ?? this.economy,
      nickname: nickname ?? this.nickname,
      preliminaryRunsCount: preliminaryRunsCount ?? this.preliminaryRunsCount,
      gender: gender ?? this.gender,
      donationCount: donationCount ?? this.donationCount,
      cumulativeDonationAmount:
          cumulativeDonationAmount ?? this.cumulativeDonationAmount,
      dailyDistance: dailyDistance ?? this.dailyDistance,
      activityStreakCount: activityStreakCount ?? this.activityStreakCount,
      runningShoeMileage: runningShoeMileage ?? this.runningShoeMileage,
      streakBonusWeekKey: streakBonusWeekKey ?? this.streakBonusWeekKey,
      shoeAlertTierSent: shoeAlertTierSent ?? this.shoeAlertTierSent,
      goldenHourAlertDateKey:
          goldenHourAlertDateKey ?? this.goldenHourAlertDateKey,
      lastJenaPendingNotifiedId:
          lastJenaPendingNotifiedId ?? this.lastJenaPendingNotifiedId,
      preferredRunHour: preferredRunHour ?? this.preferredRunHour,
      hasCPR: hasCPR ?? this.hasCPR,
      isSponsored: isSponsored ?? this.isSponsored,
    );
  }

  /// Default profile for brand-new users (no Firestore doc yet).
  factory UserModel.dashboardDefault({required String uid}) {
    return UserModel(
      uid: uid,
      watchType: WatchType.none,
      wallet: WalletModel.empty(),
      tier: 0, // 미배정
      healthDataConsent: false,
      sensitiveDataConsent: false,
      termsAccepted: false,
      pushNotificationsEnabled: false,
      nickname: '',
      preliminaryRunsCount: 0,
      gender: 'male',
      donationCount: 0,
      cumulativeDonationAmount: 0,
      dailyDistance: 0,
      activityStreakCount: 0,
      runningShoeMileage: 0,
      economy: EconomyStateModel.empty(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      final walletRaw = json['wallet'];
      final Map<String, dynamic>? walletMap = switch (walletRaw) {
        final Map<String, dynamic> m => m,
        final Map m => Map<String, dynamic>.from(m),
        _ => null,
      };

      final economyRaw = json['economy'];
      final Map<String, dynamic>? economyMap = switch (economyRaw) {
        final Map<String, dynamic> m => m,
        final Map m => Map<String, dynamic>.from(m),
        _ => null,
      };

      final dailyMiningRaw = json['dailyMining'];
      final Map<String, dynamic>? dailyMiningMap = switch (dailyMiningRaw) {
        final Map<String, dynamic> m => m,
        final Map m => Map<String, dynamic>.from(m),
        _ => null,
      };

      final economy = EconomyStateModel.fromJson(
        economy: economyMap,
        dailyMining: dailyMiningMap,
      );

      final nicknameRaw = (json['nickname'] as String?)?.trim();
      final displayNameRaw = (json['displayName'] as String?)?.trim();

      return UserModel(
        uid: json['uid'] as String? ?? '',
        watchType: WatchTypeCode.fromCode(json['watchType'] as String?),
        wallet: WalletModel.fromJson({
          if (json['shareBalance'] != null) 'shareBalance': json['shareBalance'],
          if (json['diamondBalance'] != null)
            'diamondBalance': json['diamondBalance'],
          if (json['valueBalance'] != null)
            'valueTokenBalance': json['valueBalance'],
          if (json['valueTokenBalance'] != null)
            'valueTokenBalance': json['valueTokenBalance'],
          ...?walletMap,
        }),
        tier: (json['tier'] as num?)?.toInt() ?? 0,
        healthDataConsent: json['healthDataConsent'] as bool? ??
            json['sensitiveDataConsent'] as bool? ??
            false,
        sensitiveDataConsent: json['sensitiveDataConsent'] as bool? ??
            json['healthDataConsent'] as bool? ??
            false,
        termsAccepted: json['termsAccepted'] as bool? ?? false,
        pushNotificationsEnabled:
            json['pushNotificationsEnabled'] as bool? ?? false,
        economy: economy,
        nickname: (nicknameRaw != null && nicknameRaw.isNotEmpty)
            ? nicknameRaw
            : ((displayNameRaw != null && displayNameRaw.isNotEmpty)
                ? displayNameRaw
                : ''),
        preliminaryRunsCount:
            (json['preliminaryRunsCount'] as num?)?.toInt() ??
                economy.trialRunCount,
        gender: UserModel.normalizeGender(json['gender'] as String?),
        donationCount: UserModel.nonNegativeInt(json['donationCount']),
        cumulativeDonationAmount:
            UserModel.nonNegativeInt(json['cumulativeDonationAmount']),
        dailyDistance: UserModel.nonNegativeDouble(json['dailyDistance']),
        activityStreakCount:
            UserModel.nonNegativeInt(json['activityStreakCount']),
        runningShoeMileage:
            UserModel.nonNegativeDouble(json['runningShoeMileage']),
        streakBonusWeekKey:
            (json['streakBonusWeekKey'] as String?)?.trim() ?? '',
        shoeAlertTierSent:
            UserModel.nonNegativeInt(json['shoeAlertTierSent']),
        goldenHourAlertDateKey:
            (json['goldenHourAlertDateKey'] as String?)?.trim() ?? '',
        lastJenaPendingNotifiedId:
            (json['lastJenaPendingNotifiedId'] as String?)?.trim() ?? '',
        preferredRunHour: _preferredHour(json['preferredRunHour']),
        hasCPR: json['hasCPR'] == true,
        isSponsored: json['isSponsored'] == true,
      );
    } catch (_) {
      return UserModel.dashboardDefault(
        uid: json['uid'] as String? ?? '',
      );
    }
  }
}

/// 스펙 alias — canonical persisted profile is [UserModel].
typedef UserProfile = UserModel;

