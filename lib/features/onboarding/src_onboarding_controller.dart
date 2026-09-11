import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers/app_providers.dart';
import '../../app/root_navigator.dart';
import '../../app/router/route_names.dart';
import '../../core/constants/economy_constants.dart';
import '../../core/constants/impact_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/user_model.dart';
import '../pedometer/kst_calendar.dart';
import '../wallet/providers/wallet_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 요구사항 1 — 25단계 하이브리드 티어 (동물군 × 메달 등급)
// ─────────────────────────────────────────────────────────────────────────────

/// 5대 동물군 (페이스가 빠를수록 상위) + 미심사 임시 등급 `snail`.
///
/// `snail`은 25티어 산식 밖에 두며, [TierAnimal.values] 인덱싱에
/// 끼어들지 않도록 **항상 마지막**에 둔다.
enum TierAnimal {
  turtle,
  rabbit,
  wolf,
  gazelle,
  cheetah,
  snail,
}

/// 스펙 alias — [TierAnimal]과 동일.
typedef AnimalGroup = TierAnimal;

extension TierAnimalX on TierAnimal {
  String get code => switch (this) {
        TierAnimal.turtle => 'turtle',
        TierAnimal.rabbit => 'rabbit',
        TierAnimal.wolf => 'wolf',
        TierAnimal.gazelle => 'gazelle',
        TierAnimal.cheetah => 'cheetah',
        TierAnimal.snail => 'snail',
      };

  String get labelKo => switch (this) {
        TierAnimal.turtle => '거북이',
        TierAnimal.rabbit => '토끼',
        TierAnimal.wolf => '늑대',
        TierAnimal.gazelle => '가젤',
        TierAnimal.cheetah => '치타',
        TierAnimal.snail => '달팽이',
      };

  String get emoji => switch (this) {
        TierAnimal.turtle => '🐢',
        TierAnimal.rabbit => '🐇',
        TierAnimal.wolf => '🐺',
        TierAnimal.gazelle => '🦌',
        TierAnimal.cheetah => '🐆',
        TierAnimal.snail => '🐌',
      };
}

/// 5대 세부 메달 등급 (마스터가 동물군 내 최상위).
enum TierMedal {
  bronze,
  silver,
  gold,
  diamond,
  master,
}

/// 스펙 alias — [TierMedal]과 동일. 달팽이 등급에서는 UI에 노출하지 않는다.
typedef SubTier = TierMedal;

extension TierMedalX on TierMedal {
  String get code => switch (this) {
        TierMedal.bronze => 'bronze',
        TierMedal.silver => 'silver',
        TierMedal.gold => 'gold',
        TierMedal.diamond => 'diamond',
        TierMedal.master => 'master',
      };

  String get labelKo => switch (this) {
        TierMedal.bronze => '브론즈',
        TierMedal.silver => '실버',
        TierMedal.gold => '골드',
        TierMedal.diamond => '다이아',
        TierMedal.master => '마스터',
      };

  /// UI 메달 틴트 — [AppColors] 팔레트와 연결.
  Color get medalColor => switch (this) {
        TierMedal.bronze => AppColors.tierMedalBronze,
        TierMedal.silver => AppColors.tierMedalSilver,
        TierMedal.gold => AppColors.tierMedalGold,
        TierMedal.diamond => AppColors.tierMedalDiamond,
        TierMedal.master => AppColors.tierMedalMaster,
      };
}

/// 동물군 × 메달 = 총 25티어. 평균 페이스(초/km)로 산정.
/// `snail`은 예비 심사 미완/우회 전용 임시 등급이며 서브 티어 수식에서 제외한다.
@immutable
class UserTier {
  const UserTier({
    TierAnimal? animal,
    TierMedal? medal,
    AnimalGroup? group,
    SubTier? subTier,
  })  : animal = animal ?? group ?? TierAnimal.snail,
        medal = medal ?? subTier ?? TierMedal.bronze;

  final TierAnimal animal;
  final TierMedal medal;

  AnimalGroup get group => animal;
  SubTier get subTier => medal;

  bool get isSnail => animal == TierAnimal.snail;
  bool get isUnrated => isSnail;

  /// 해금 비교용. 달팽이 0 → 거북이 1 → … → 치타 5.
  int get animalUnlockRank {
    if (isSnail) return 0;
    final index = rankedAnimals.indexOf(animal);
    return index < 0 ? 0 : index + 1;
  }

  /// 미심사 폴백 — 서브 티어는 저장만 하고 UI에는 쓰지 않는다.
  static const unratedFallback = UserTier(
    group: AnimalGroup.snail,
    subTier: SubTier.bronze,
  );

  /// 홈/마이페이지 한글 등급. 달팽이는 서브 티어 없이 **'달팽이'**만.
  String get koreanName =>
      isSnail ? '달팽이' : '${animal.labelKo} ${medal.labelKo}';

  String get englishName => isSnail
      ? 'Snail (Unrated)'
      : '${_titleCase(animal.code)} ${_titleCase(medal.code)}';

  String get displayNameKo => isSnail ? '달팽이' : '${medal.labelKo} ${animal.labelKo}';

  String get displayNameWithEmoji => '${animal.emoji} $koreanName';

  /// Chibi SD 의인화 러닝 마스코트 + 목걸이 메달 에셋.
  /// 달팽이: 실망하고 한숨 쉬는 깜찍한 비주얼.
  String get avatarAssetPath => switch (group) {
        AnimalGroup.snail =>
          'assets/images/characters/chibi_snail_disappointed.png',
        AnimalGroup.turtle =>
          'assets/images/characters/chibi_turtle_gold_medal.png',
        AnimalGroup.rabbit =>
          'assets/images/characters/chibi_rabbit_gold_medal.png',
        AnimalGroup.wolf =>
          'assets/images/characters/chibi_wolf_gold_medal.png',
        AnimalGroup.gazelle =>
          'assets/images/characters/chibi_gazelle_gold_medal.png',
        AnimalGroup.cheetah =>
          'assets/images/characters/chibi_cheetah_gold_medal.png',
      };

  /// 만보기 전용 — 금메달 없는 순수 티어 마스코트.
  String get pureAvatarAssetPath => isSnail
      ? 'assets/images/characters/chibi_snail_running.png'
      : 'assets/images/characters/chibi_${animal.code}_pure.png';

  /// 만보기 일일 목표 거리.
  double get targetKm => switch (group) {
        AnimalGroup.snail => 3.0,
        AnimalGroup.turtle => 5.0,
        AnimalGroup.rabbit || AnimalGroup.wolf => 7.0,
        AnimalGroup.gazelle || AnimalGroup.cheetah => 10.0,
      };

  /// 만보기 일일 목표 걸음 수 (1 SHARE = 1km 환산과 별개, 3.0km ≈ 4,500보).
  int get targetSteps => switch (group) {
        AnimalGroup.snail => 4500,
        AnimalGroup.turtle => 7500,
        AnimalGroup.rabbit || AnimalGroup.wolf => 10500,
        AnimalGroup.gazelle || AnimalGroup.cheetah => 15000,
      };

  /// 만보기 SHARE 드랍 주기(km).
  double get dropIntervalKm => switch (group) {
        AnimalGroup.snail => 0.05,
        AnimalGroup.turtle => 0.1,
        AnimalGroup.rabbit || AnimalGroup.wolf => 0.14,
        AnimalGroup.gazelle || AnimalGroup.cheetah => 0.2,
      };

  /// 만보기 일일 최대 채굴 SHARE.
  int get maxDailyShare => isSnail ? 60 : 50;

  /// 만보기 거리 상한 — 전 티어 목표의 최대값.
  static const pedometerKmCeiling = 10.0;

  /// 현재 km 기준 생성되어야 할 미수집 포함 드랍 개수(이미 주운 분 포함).
  int pendingShareDrops(double km) {
    final interval = dropIntervalKm;
    if (interval <= 0) return 0;
    final capped = km < 0 ? 0.0 : (km > targetKm ? targetKm : km);
    final earned = (capped / interval).floor();
    if (earned < 0) return 0;
    if (earned > maxDailyShare) return maxDailyShare;
    return earned;
  }

  /// 만보기 캔버스 파스텔.
  Color get walkCanvasStart => switch (group) {
        AnimalGroup.snail => const Color(0xFFE8EDE4),
        AnimalGroup.turtle => const Color(0xFFDFF5EA),
        AnimalGroup.rabbit => const Color(0xFFFFF0E3),
        AnimalGroup.wolf => const Color(0xFFE8EEF3),
        AnimalGroup.gazelle => const Color(0xFFF7ECDD),
        AnimalGroup.cheetah => const Color(0xFFFFF1D6),
      };

  Color get walkCanvasEnd => switch (group) {
        AnimalGroup.snail => const Color(0xFFD5DDD0),
        AnimalGroup.turtle => const Color(0xFFBFE8D4),
        AnimalGroup.rabbit => const Color(0xFFFFD9C2),
        AnimalGroup.wolf => const Color(0xFFD2DCE6),
        AnimalGroup.gazelle => const Color(0xFFE8D4B8),
        AnimalGroup.cheetah => const Color(0xFFFFE0A3),
      };

  /// Firestore `tier` int 호환 (0=달팽이 미배정, 1=브론즈 거북이 … 25=마스터 치타).
  int get rankScore {
    if (isSnail) return 0;
    final animalBase = switch (animal) {
      TierAnimal.turtle => 0,
      TierAnimal.rabbit => 5,
      TierAnimal.wolf => 10,
      TierAnimal.gazelle => 15,
      TierAnimal.cheetah => 20,
      TierAnimal.snail => 0,
    };
    final medalBonus = switch (medal) {
      TierMedal.bronze => 1,
      TierMedal.silver => 2,
      TierMedal.gold => 3,
      TierMedal.diamond => 4,
      TierMedal.master => 5,
    };
    return animalBase + medalBonus;
  }

  String get firestoreCode =>
      isSnail ? 'snail_unrated' : '${animal.code}_${medal.code}';

  static const List<TierAnimal> rankedAnimals = <TierAnimal>[
    TierAnimal.turtle,
    TierAnimal.rabbit,
    TierAnimal.wolf,
    TierAnimal.gazelle,
    TierAnimal.cheetah,
  ];

  static UserTier? tryFromRankScore(int score) {
    if (score < 1 || score > 25) return null;
    final animal = rankedAnimals[(score - 1) ~/ 5];
    final medal = TierMedal.values[(score - 1) % 5];
    return UserTier(animal: animal, medal: medal);
  }

  /// 5회 예비 완주 전·심사 우회 시 달팽이 강제 폴백.
  static UserTier resolveForProgress({
    required int preliminaryRunPacesLength,
    UserTier? assigned,
    int firestoreRank = 0,
  }) {
    if (preliminaryRunPacesLength < EconomyConstants.trialRunsRequired) {
      return const UserTier(
        group: AnimalGroup.snail,
        subTier: SubTier.bronze,
      );
    }
    if (assigned != null && !assigned.isSnail) {
      return assigned;
    }
    return tryFromRankScore(firestoreRank) ??
        const UserTier(
          group: AnimalGroup.snail,
          subTier: SubTier.bronze,
        );
  }

  static String _titleCase(String raw) {
    if (raw.isEmpty) return raw;
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  /// 1km × 5회 평균 페이스(초/km) → 25티어. 경계 공백 없음.
  factory UserTier.fromAveragePaceSeconds(int paceSecPerKm) {
    final pace = paceSecPerKm < 0 ? 0 : paceSecPerKm;

    if (pace >= 450) {
      // 🐢 거북이
      if (pace <= 479) {
        return const UserTier(animal: TierAnimal.turtle, medal: TierMedal.master);
      }
      if (pace <= 509) {
        return const UserTier(
          animal: TierAnimal.turtle,
          medal: TierMedal.diamond,
        );
      }
      if (pace <= 539) {
        return const UserTier(animal: TierAnimal.turtle, medal: TierMedal.gold);
      }
      if (pace <= 569) {
        return const UserTier(
          animal: TierAnimal.turtle,
          medal: TierMedal.silver,
        );
      }
      return const UserTier(animal: TierAnimal.turtle, medal: TierMedal.bronze);
    }

    if (pace >= 360) {
      // 🐇 토끼 360~449
      if (pace <= 377) {
        return const UserTier(animal: TierAnimal.rabbit, medal: TierMedal.master);
      }
      if (pace <= 395) {
        return const UserTier(
          animal: TierAnimal.rabbit,
          medal: TierMedal.diamond,
        );
      }
      if (pace <= 413) {
        return const UserTier(animal: TierAnimal.rabbit, medal: TierMedal.gold);
      }
      if (pace <= 431) {
        return const UserTier(
          animal: TierAnimal.rabbit,
          medal: TierMedal.silver,
        );
      }
      return const UserTier(animal: TierAnimal.rabbit, medal: TierMedal.bronze);
    }

    if (pace >= 300) {
      // 🐺 늑대 300~359
      if (pace <= 311) {
        return const UserTier(animal: TierAnimal.wolf, medal: TierMedal.master);
      }
      if (pace <= 323) {
        return const UserTier(animal: TierAnimal.wolf, medal: TierMedal.diamond);
      }
      if (pace <= 335) {
        return const UserTier(animal: TierAnimal.wolf, medal: TierMedal.gold);
      }
      if (pace <= 347) {
        return const UserTier(animal: TierAnimal.wolf, medal: TierMedal.silver);
      }
      return const UserTier(animal: TierAnimal.wolf, medal: TierMedal.bronze);
    }

    if (pace >= 240) {
      // 🦌 가젤 240~299
      if (pace <= 251) {
        return const UserTier(
          animal: TierAnimal.gazelle,
          medal: TierMedal.master,
        );
      }
      if (pace <= 263) {
        return const UserTier(
          animal: TierAnimal.gazelle,
          medal: TierMedal.diamond,
        );
      }
      if (pace <= 275) {
        return const UserTier(animal: TierAnimal.gazelle, medal: TierMedal.gold);
      }
      if (pace <= 287) {
        return const UserTier(
          animal: TierAnimal.gazelle,
          medal: TierMedal.silver,
        );
      }
      return const UserTier(animal: TierAnimal.gazelle, medal: TierMedal.bronze);
    }

    // 🐆 치타 ≤239
    if (pace <= 199) {
      return const UserTier(animal: TierAnimal.cheetah, medal: TierMedal.master);
    }
    if (pace <= 209) {
      return const UserTier(
        animal: TierAnimal.cheetah,
        medal: TierMedal.diamond,
      );
    }
    if (pace <= 219) {
      return const UserTier(animal: TierAnimal.cheetah, medal: TierMedal.gold);
    }
    if (pace <= 229) {
      return const UserTier(animal: TierAnimal.cheetah, medal: TierMedal.silver);
    }
    return const UserTier(animal: TierAnimal.cheetah, medal: TierMedal.bronze);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTier && animal == other.animal && medal == other.medal;

  @override
  int get hashCode => Object.hash(animal, medal);
}

// ─────────────────────────────────────────────────────────────────────────────
// 천사(Angel) 후원 등급 — 0회 예비 천사 포함 6단계, 횟수 OR 금액 승급
// ─────────────────────────────────────────────────────────────────────────────

/// 100 SHARE = 100원.
abstract final class AngelEconomy {
  static const int shareToWon = 1;
}

enum AngelTier {
  preAngel,
  cupid,
  guardian,
  archangel,
  cherubim,
  seraphim,
}

extension AngelTierX on AngelTier {
  String get code => switch (this) {
        AngelTier.preAngel => 'pre_angel',
        AngelTier.cupid => 'cupid',
        AngelTier.guardian => 'guardian',
        AngelTier.archangel => 'archangel',
        AngelTier.cherubim => 'cherubim',
        AngelTier.seraphim => 'seraphim',
      };

  String get koreanName => switch (this) {
        AngelTier.preAngel => '예비 천사 (Pre-Angel)',
        AngelTier.cupid => '큐피드',
        AngelTier.guardian => '수호천사',
        AngelTier.archangel => '대천사',
        AngelTier.cherubim => '지천사',
        AngelTier.seraphim => '세라핌',
      };

  String get englishName => switch (this) {
        AngelTier.preAngel => 'Pre-Angel',
        AngelTier.cupid => 'Cupid',
        AngelTier.guardian => 'Guardian Angel',
        AngelTier.archangel => 'Archangel',
        AngelTier.cherubim => 'Cherubim',
        AngelTier.seraphim => 'Seraphim',
      };

  String get emoji => switch (this) {
        AngelTier.preAngel => '🩹',
        AngelTier.cupid => '🏹',
        AngelTier.guardian => '🛡️',
        AngelTier.archangel => '⚔️',
        AngelTier.cherubim => '👁️',
        AngelTier.seraphim => '👑',
      };

  String get avatarAssetPath => switch (this) {
        AngelTier.preAngel =>
          'assets/images/characters/chibi_pre_angel_bandaid.png',
        AngelTier.cupid => 'assets/images/characters/chibi_cupid_wing.png',
        AngelTier.guardian =>
          'assets/images/characters/chibi_guardian_wing.png',
        AngelTier.archangel =>
          'assets/images/characters/chibi_archangel_wing.png',
        AngelTier.cherubim =>
          'assets/images/characters/chibi_cherubim_wing.png',
        AngelTier.seraphim =>
          'assets/images/characters/chibi_seraphim_wing.png',
      };

  /// 승급에 필요한 최소 후원 횟수. 예비 천사는 0.
  int get minDonationCount => switch (this) {
        AngelTier.preAngel => 0,
        AngelTier.cupid => 1,
        AngelTier.guardian => 5,
        AngelTier.archangel => 20,
        AngelTier.cherubim => 50,
        AngelTier.seraphim => 100,
      };

  /// 승급에 필요한 최소 누적 금액(원). 큐피드·예비는 금액 기준 없음(0).
  int get minDonationAmountWon => switch (this) {
        AngelTier.preAngel => 0,
        AngelTier.cupid => 0,
        AngelTier.guardian => 50000,
        AngelTier.archangel => 300000,
        AngelTier.cherubim => 1000000,
        AngelTier.seraphim => 5000000,
      };

  AngelTier? get next {
    final i = index + 1;
    if (i >= AngelTier.values.length) return null;
    return AngelTier.values[i];
  }

  bool get isPreAngel => this == AngelTier.preAngel;
  bool get emphasizeNickname => index >= AngelTier.guardian.index;
  bool get goldNickname => index >= AngelTier.archangel.index;
  bool get entranceAnnounce => index >= AngelTier.cherubim.index;
  bool get neonAura => index >= AngelTier.cherubim.index;
  bool get rotatingHalo => this == AngelTier.seraphim;
  bool get showSeraphimVvip => this == AngelTier.seraphim;

  double get tokenBoostMultiplier =>
      index >= AngelTier.archangel.index ? 1.2 : 1.0;

  String get requirementLabel => switch (this) {
        AngelTier.preAngel => '후원 0회 · 1회 정산 시 큐피드 승급',
        AngelTier.cupid => '최초 1회 이상 후원 (SHARE 무관)',
        AngelTier.guardian => '누적 5회 또는 누적 50,000 SHARE 이상',
        AngelTier.archangel => '누적 20회 또는 누적 300,000 SHARE 이상',
        AngelTier.cherubim => '누적 50회 또는 누적 1,000,000 SHARE 이상',
        AngelTier.seraphim => '누적 100회 또는 누적 5,000,000 SHARE 이상',
      };

  String get rewardLabel => switch (this) {
        AngelTier.preAngel => '등에 귀여운 날개 반창고를 붙인 마스코트',
        AngelTier.cupid => '등 뒤 아기 날개 배지 장착',
        AngelTier.guardian => '은빛 날개 · 방 입장 시 닉네임 볼드 테두리 강조',
        AngelTier.archangel =>
          '황금 날개 · 골드 그라데이션 닉네임 · 개설 방 러너 1.2배 토큰 부스트',
        AngelTier.cherubim => '4익 날개 · 민트 오라 · 방 입장 시 단독 등장 팝업',
        AngelTier.seraphim => '6익 날개 · 골드 광배 회전 · 명예의 전당 VVIP 단독 배너',
      };

  /// 횟수 OR 금액 — 높은 쪽부터 판정.
  /// [donationCount]가 0이면 금액과 무관하게 무조건 [AngelTier.preAngel].
  static AngelTier resolve({
    required int donationCount,
    required int cumulativeDonationAmount,
  }) {
    final count = donationCount < 0 ? 0 : donationCount;
    final amount = cumulativeDonationAmount < 0 ? 0 : cumulativeDonationAmount;
    if (count == 0) return AngelTier.preAngel;
    if (count >= 100 || amount >= 5000000) return AngelTier.seraphim;
    if (count >= 50 || amount >= 1000000) return AngelTier.cherubim;
    if (count >= 20 || amount >= 300000) return AngelTier.archangel;
    if (count >= 5 || amount >= 50000) return AngelTier.guardian;
    return AngelTier.cupid;
  }

  /// 다음 등급까지 진척도. OR 조건이므로 횟수/금액 비율 중 높은 값.
  double progressToNext({
    required int donationCount,
    required int cumulativeDonationAmount,
  }) {
    final n = next;
    if (n == null) return 1.0;
    final countP = n.minDonationCount <= 0
        ? 1.0
        : donationCount / n.minDonationCount;
    final amountP = n.minDonationAmountWon <= 0
        ? 0.0
        : cumulativeDonationAmount / n.minDonationAmountWon;
    final best = countP > amountP ? countP : amountP;
    if (best.isNaN || best.isInfinite) return 0.0;
    return best.clamp(0.0, 1.0);
  }

  String nextGapLabel({
    required int donationCount,
    required int cumulativeDonationAmount,
  }) {
    final n = next;
    if (n == null) return '최고 천사 등급입니다';
    final remainCount = (n.minDonationCount - donationCount).clamp(0, 1 << 30);
    if (n.minDonationAmountWon <= 0) {
      return '${n.koreanName}까지 후원 $remainCount회';
    }
    final remainWon =
        (n.minDonationAmountWon - cumulativeDonationAmount).clamp(0, 1 << 30);
    return '${n.koreanName}까지 $remainCount회 또는 ${formatWon(remainWon)}';
  }

  static String formatWon(int won) {
    final digits = won.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return '${buf.toString()} SHARE';
  }
}

/// [UserProfile] 후원 실적 → 현재 천사 등급.
extension UserProfileAngelTierX on UserModel {
  AngelTier get angelTier => AngelTierX.resolve(
        donationCount: safeDonationCount,
        cumulativeDonationAmount: safeCumulativeDonationAmount,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 요구사항 2 — 온보딩 4단계 + 3.5 소프트 알림
// ─────────────────────────────────────────────────────────────────────────────

enum OnboardingPhase {
  /// 1단계: 소셜 가입 + 가입 보상 100 토큰
  socialSignup,

  /// 2단계: 위치(필수) / 건강정보(선택) 분리 동의
  sensitiveConsent,

  /// 3단계: HealthKit / Health Connect 기기 연동
  deviceSync,

  /// 3.5단계: 푸시 알림 Soft-prompt (바텀시트)
  pushSoftPrompt,

  /// 4단계: 5회 예비 심사 + 티어 판정 / 보상
  preliminaryEval,

  /// 온보딩 완료 → 메인
  completed,
}

extension OnboardingPhaseRoute on OnboardingPhase {
  /// go_router / [RouteNames] 선언적 경로.
  String get routePath => switch (this) {
        OnboardingPhase.socialSignup => RouteNames.login,
        OnboardingPhase.sensitiveConsent => RouteNames.termsAgreement,
        OnboardingPhase.deviceSync => RouteNames.smartWatchSync,
        OnboardingPhase.pushSoftPrompt => RouteNames.smartWatchSync,
        OnboardingPhase.preliminaryEval => RouteNames.preliminaryEval,
        OnboardingPhase.completed => RouteNames.mainDashboard,
      };
}

/// 홈 UI 스펙 alias — [OnboardingPhase]와 동일.
typedef OnboardingStep = OnboardingPhase;

/// 혼자 달리기 CTA — 온보딩 완료 또는 달팽이(심사 우회)는 자유 트래킹.
abstract final class SoloQuickStartRouting {
  static bool useFreeTracking({
    required SrcOnboardingState onboarding,
    required UserProfile profile,
    UserTier? resolvedTier,
  }) {
    if (onboarding.currentStep == OnboardingStep.completed) {
      return true;
    }
    final tier = resolvedTier ??
        UserTier.tryFromRankScore(profile.tier) ??
        onboarding.assignedTier ??
        UserTier.unratedFallback;
    return tier.isSnail || tier.group == AnimalGroup.snail;
  }
}

/// 테스트용 — 최근 러닝 1건을 Jena Pending으로 강제 주입.
abstract final class JenaPendingDebugSeed {
  static List<ActivityModel> injectLatestPending(
    List<ActivityModel> activities,
  ) {
    return ActivityModel.withLatestForcedPending(activities);
  }
}

/// Soft-prompt에 노출하는 웰니스 이득 카피.
abstract final class OnboardingSoftPromptCopy {
  static const title = '알림을 켜면 이런 이득이 있어요';
  static const benefits = <String>[
    '재화 실시간 입금 알림',
    '소속 크루 방장 전체 공지 긴급 수신',
    '러닝화 수명 도달에 따른 부상 방지 수명 알림',
  ];
}

@immutable
class SrcOnboardingState {
  const SrcOnboardingState({
    this.phase = OnboardingPhase.socialSignup,
    this.locationConsent = false,
    this.healthHrConsent = false,
    this.deviceSynced = false,
    this.nativeWatchLinked = false,
    this.isGarminConnected = false,
    this.softPromptVisible = false,
    this.softPromptApproved = false,
    this.signupRewardApplied = false,
    this.trialRewardApplied = false,
    this.preliminaryPaceSeconds = const [],
    this.assignedTier = UserTier.unratedFallback,
    this.displayNickname = '',
    this.nicknameStatus = const AsyncData(null),
    this.actionStatus = const AsyncData(null),
    this.lastError,
  });

  final OnboardingPhase phase;

  /// 홈 배너 구독용 — [phase]와 동일.
  OnboardingPhase get currentStep => phase;

  /// 필수 — 위치정보 수집·이용 동의.
  final bool locationConsent;

  /// 선택 — 건강정보(심박수) 수집·이용 동의.
  final bool healthHrConsent;

  /// HealthKit / Health Connect 연동 완료 여부.
  final bool deviceSynced;

  /// 네이티브 헬스(Apple Health / Health Connect) 권한 승인.
  final bool nativeWatchLinked;

  /// Garmin Connect OAuth 클라우드 연동 완료.
  final bool isGarminConnected;

  /// 3.5 Soft-prompt 바텀시트 표시 트리거.
  final bool softPromptVisible;

  final bool softPromptApproved;
  final bool signupRewardApplied;
  final bool trialRewardApplied;

  /// 1km 예비 러닝 페이스(초/km), 최대 5회.
  final List<int> preliminaryPaceSeconds;

  final UserTier? assignedTier;

  /// 홈 헤더에 바인딩하는 실시간 닉네임 (Firestore 스냅샷보다 우선).
  final String displayNickname;

  /// 닉네임 변경 AsyncValue (로딩/데이터/에러 UI 동기화).
  final AsyncValue<void> nicknameStatus;

  /// 온보딩 트랜잭션 AsyncValue.
  final AsyncValue<void> actionStatus;

  final String? lastError;

  /// 네이티브 또는 가민 중 최소 1개 연동 시 CTA 활성화.
  bool get canCompleteWatchLink =>
      nativeWatchLinked || isGarminConnected || deviceSynced;

  bool get canProceedFromConsent => locationConsent;

  bool get isPreliminaryComplete =>
      preliminaryPaceSeconds.length >= EconomyConstants.trialRunsRequired;

  int? get averagePaceSeconds {
    if (preliminaryPaceSeconds.isEmpty) return null;
    final sum = preliminaryPaceSeconds.fold<int>(0, (a, b) => a + b);
    return sum ~/ preliminaryPaceSeconds.length;
  }

  SrcOnboardingState copyWith({
    OnboardingPhase? phase,
    bool? locationConsent,
    bool? healthHrConsent,
    bool? deviceSynced,
    bool? nativeWatchLinked,
    bool? isGarminConnected,
    bool? softPromptVisible,
    bool? softPromptApproved,
    bool? signupRewardApplied,
    bool? trialRewardApplied,
    List<int>? preliminaryPaceSeconds,
    UserTier? assignedTier,
    bool clearAssignedTier = false,
    String? displayNickname,
    AsyncValue<void>? nicknameStatus,
    AsyncValue<void>? actionStatus,
    String? lastError,
    bool clearLastError = false,
  }) {
    return SrcOnboardingState(
      phase: phase ?? this.phase,
      locationConsent: locationConsent ?? this.locationConsent,
      healthHrConsent: healthHrConsent ?? this.healthHrConsent,
      deviceSynced: deviceSynced ?? this.deviceSynced,
      nativeWatchLinked: nativeWatchLinked ?? this.nativeWatchLinked,
      isGarminConnected: isGarminConnected ?? this.isGarminConnected,
      softPromptVisible: softPromptVisible ?? this.softPromptVisible,
      softPromptApproved: softPromptApproved ?? this.softPromptApproved,
      signupRewardApplied: signupRewardApplied ?? this.signupRewardApplied,
      trialRewardApplied: trialRewardApplied ?? this.trialRewardApplied,
      preliminaryPaceSeconds:
          preliminaryPaceSeconds ?? this.preliminaryPaceSeconds,
      assignedTier:
          clearAssignedTier ? null : (assignedTier ?? this.assignedTier),
      displayNickname: displayNickname ?? this.displayNickname,
      nicknameStatus: nicknameStatus ?? this.nicknameStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

/// 닉네임 유효성 / 비속어 / DIA 잔액 부족 등 도메인 예외.
class NicknameValidationException implements Exception {
  NicknameValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class InsufficientDiaException implements Exception {
  InsufficientDiaException({
    required this.requiredDia,
    required this.availableDia,
  });

  final int requiredDia;
  final int availableDia;

  @override
  String toString() =>
      'DIA 잔액 부족: 필요 $requiredDia, 보유 $availableDia';
}

/// 닉네임 실시간 필터 — 2~12자, 한글/영문/숫자, 특수문자·비속어 차단.
abstract final class NicknameValidator {
  static final RegExp pattern = RegExp(r'^[가-힣a-zA-Z0-9]{2,12}$');

  static const List<String> _profanityBlacklist = <String>[
    '시발',
    '씨발',
    '병신',
    '지랄',
    '좆',
    '존나',
    '개새끼',
    '씹',
    '니미',
    '느금',
    '섹스',
    '야동',
    '포르노',
    '성인물',
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'dick',
    'porn',
  ];

  /// 통과 또는 입력 중 공백이면 `null`. 위반 시 붉은 가이드 문구.
  static String? validate(String raw) {
    final nickname = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (nickname.isEmpty) return null;
    final lower = nickname.toLowerCase();
    for (final word in _profanityBlacklist) {
      if (lower.contains(word.toLowerCase())) {
        return '부적절한 단어가 포함되어 있습니다.';
      }
    }
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 공백 제외 2~12자여야 합니다.';
    }
    if (!pattern.hasMatch(nickname)) {
      return '닉네임은 한글/영문/숫자만 사용할 수 있습니다.';
    }
    return null;
  }
}

/// 만보기 Health 쿼리 — KST(UTC+9) 당일 00:00~현재, 통합 걸음만 단건 조회.
abstract final class PedometerKstClock {
  static const kstOffset = KstCalendar.offset;
  static const _stepTypes = [HealthDataType.STEPS];
  static const _stepAccess = [HealthDataAccess.READ];

  static ({DateTime startDate, DateTime endDate}) todayRange([DateTime? now]) =>
      KstCalendar.todayRange(now);

  static String dateKey([DateTime? now]) => KstCalendar.dateKey(now);

  static String dateKeyFromYmd(int year, int month, int day) =>
      KstCalendar.dateKeyFromYmd(year, month, day);

  static String backupStepsKey(String ymd) => '${ymd}_steps';

  static String backupKmKey(String ymd) => '${ymd}_km';

  /// KST 기준 이번 주 월요일~일요일.
  static List<({int year, int month, int day, String key})> thisWeekDays([
    DateTime? now,
  ]) =>
      KstCalendar.thisWeekDays(now);

  static Future<bool> requestAuthorization(Health health) async {
    try {
      await Permission.activityRecognition.request();
    } on PlatformException catch (e, st) {
      debugPrint('PedometerKstClock activityRecognition: $e\n$st');
    } catch (e, st) {
      debugPrint('PedometerKstClock activityRecognition: $e\n$st');
    }
    try {
      await health.configure();
      var granted = await health.hasPermissions(
        _stepTypes,
        permissions: _stepAccess,
      );
      if (granted != true) {
        granted = await health.requestAuthorization(
          _stepTypes,
          permissions: _stepAccess,
        );
      }
      return granted == true;
    } on PlatformException catch (e, st) {
      debugPrint('PedometerKstClock requestAuthorization: $e\n$st');
      return false;
    } catch (e, st) {
      debugPrint('PedometerKstClock requestAuthorization: $e\n$st');
      return false;
    }
  }

  static Future<int?> queryTodaySteps(
    Health health, {
    bool requestIfMissing = true,
  }) async {
    try {
      if (requestIfMissing) {
        await Permission.activityRecognition.request();
        await requestAuthorization(health);
      } else {
        await health.configure();
      }
      final range = todayRange();
      final total = await health.getTotalStepsInInterval(
        range.startDate,
        range.endDate,
      );
      if (total == null) return null;
      return total < 0 ? 0 : total;
    } on PlatformException catch (e, st) {
      debugPrint('PedometerKstClock getTotalStepsInInterval: $e\n$st');
      return null;
    } catch (e, st) {
      debugPrint('PedometerKstClock getTotalStepsInInterval: $e\n$st');
      return null;
    }
  }
}

/// 만보기 화면이 백그라운드→포그라운드로 복귀할 때 OS 헬스 걸음을 덮어쓴다.
mixin PedometerHealthLifecycle<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  Future<void> syncBackgroundSteps();
}

/// 1기기 1계정 — 포그라운드 재개 시에만 서버 세션 토큰을 검증한다.
abstract final class ConcurrentSessionManager {
  static const localTokenKey = 'local_session_token';
  static const serverTokenField = 'current_session_token';
  static var _inFlight = false;

  /// 네트워크 지연 유예 + 통신 실패 시 세션 유지(Fail-Safe).
  static Future<void> checkConcurrentLogin(
    String uid, {
    required bool fromForegroundResume,
    VoidCallback? onExpired,
  }) async {
    if (!fromForegroundResume) return;
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (uid.isEmpty) return;
      await Future.delayed(const Duration(seconds: 3));
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final server = snap.data()?[serverTokenField] as String?;
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString(localTokenKey);
      if (server == null || server.isEmpty) return;
      if (local == null || local.isEmpty) return;
      if (local != server) {
        onExpired?.call();
      }
    } catch (e) {
      return;
    } finally {
      _inFlight = false;
    }
  }
}

class _ConcurrentSessionResumeGate with WidgetsBindingObserver {
  _ConcurrentSessionResumeGate(this._onResumed);

  final VoidCallback _onResumed;
  AppLifecycleState? _last;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final becameResumed =
        state == AppLifecycleState.resumed && _last != AppLifecycleState.resumed;
    _last = state;
    if (!becameResumed) return;
    _onResumed();
  }
}

/// SRC 온보딩 상태 기계 + 티어/닉네임/Jena 승급 통로.
class SrcOnboardingController extends Notifier<SrcOnboardingState> {
  /// 홈 화면 하드코딩 임시 닉네임 — 미설정으로 취급.
  static const placeholderNickname = '달리기부자45';

  @override
  SrcOnboardingState build() {
    ref.listen<AsyncValue<UserModel>>(activeUserProfileProvider, (_, next) {
      next.whenData(_hydrateFromProfile);
    });
    final resumeGate = _ConcurrentSessionResumeGate(() {
      final uid = _currentUid();
      if (uid == null || uid.isEmpty) return;
      unawaited(
        ConcurrentSessionManager.checkConcurrentLogin(
          uid,
          fromForegroundResume: true,
          onExpired: _kickExpiredSession,
        ),
      );
    });
    WidgetsBinding.instance.addObserver(resumeGate);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(resumeGate);
    });
    ref.listen<PersistedUsername>(persistedUsernameProvider, (_, next) {
      if (!next.ready) return;
      final saved = next.value.trim();
      if (saved.isEmpty || isUnsetNickname(saved)) return;
      if (state.displayNickname.trim() == saved) return;
      if (state.displayNickname.isNotEmpty &&
          !isUnsetNickname(state.displayNickname)) {
        return;
      }
      state = state.copyWith(displayNickname: saved);
    });
    unawaited(_hydrateNicknameFromPrefs());
    final profile = ref.read(activeUserProfileProvider).asData?.value;
    if (profile != null) {
      return _stateFromProfile(profile);
    }
    return const SrcOnboardingState();
  }

  void _kickExpiredSession() {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }

  void _hydrateFromProfile(UserModel profile) {
    if (profile.uid.isEmpty) return;
    final next = _stateFromProfile(profile);
    // 로컬 예비 페이스/소프트프롬프트 진행 중이면 Firestore 스냅샷이 덮어쓰지 않음.
    if (state.preliminaryPaceSeconds.isNotEmpty &&
        !state.trialRewardApplied &&
        next.preliminaryPaceSeconds.isEmpty) {
      return;
    }
    if (state.softPromptVisible) return;
    final keepLocalNick = state.displayNickname.isNotEmpty &&
        !SrcOnboardingController.isUnsetNickname(state.displayNickname) &&
        SrcOnboardingController.isUnsetNickname(next.displayNickname);
    state = next.copyWith(
      actionStatus: state.actionStatus,
      nicknameStatus: state.nicknameStatus,
      displayNickname:
          keepLocalNick ? state.displayNickname : next.displayNickname,
      nativeWatchLinked: state.nativeWatchLinked || next.nativeWatchLinked,
      isGarminConnected: state.isGarminConnected || next.isGarminConnected,
    );
  }

  SrcOnboardingState _stateFromProfile(UserModel profile) {
    final economy = profile.economy;
    final phase = _inferPhase(profile);
    final assigned = UserTier.resolveForProgress(
      preliminaryRunPacesLength: economy.trialRunCount,
      assigned: UserTier.tryFromRankScore(profile.tier),
      firestoreRank: profile.tier,
    );
    return SrcOnboardingState(
      phase: phase,
      locationConsent: profile.sensitiveDataConsent || profile.termsAccepted,
      healthHrConsent: profile.healthDataConsent,
      deviceSynced: profile.watchType != WatchType.none,
      nativeWatchLinked: profile.watchType.isOsDirectTrack,
      isGarminConnected: profile.watchType == WatchType.garmin,
      signupRewardApplied: economy.signupRewardClaimed,
      trialRewardApplied: economy.trialMilestoneRewardClaimed,
      assignedTier: assigned,
      displayNickname: profile.nickname.trim(),
      preliminaryPaceSeconds: List<int>.filled(
        economy.trialRunCount.clamp(0, EconomyConstants.trialRunsRequired),
        0,
        growable: true,
      ),
    );
  }

  OnboardingPhase _inferPhase(UserModel profile) {
    if (profile.economy.firstTierGranted ||
        profile.economy.trialMilestoneRewardClaimed) {
      return OnboardingPhase.completed;
    }
    if (!profile.termsAccepted && !profile.sensitiveDataConsent) {
      if (profile.uid.isEmpty) return OnboardingPhase.socialSignup;
      return OnboardingPhase.sensitiveConsent;
    }
    if (profile.watchType == WatchType.none) {
      return OnboardingPhase.deviceSync;
    }
    if (profile.economy.trialRunCount < EconomyConstants.trialRunsRequired) {
      return OnboardingPhase.preliminaryEval;
    }
    return OnboardingPhase.completed;
  }

  String? _currentUid() {
    final auth = ref.read(authStateChangesProvider).asData?.value;
    if (auth != null && auth.uid.isNotEmpty) return auth.uid;
    final profile = ref.read(activeUserProfileProvider).asData?.value;
    if (profile != null && profile.uid.isNotEmpty) return profile.uid;
    return null;
  }

  String _requireUid() {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      throw StateError('로그인이 필요합니다.');
    }
    return uid;
  }

  Future<void> _hydrateNicknameFromPrefs() async {
    final saved = ref.read(persistedUsernameProvider).value.trim();
    if (saved.isEmpty || isUnsetNickname(saved)) return;
    if (state.displayNickname.isNotEmpty &&
        !isUnsetNickname(state.displayNickname)) {
      return;
    }
    state = state.copyWith(displayNickname: saved);
  }

  // ── 1단계: 소셜 가입 + 100 토큰 ──────────────────────────────────────────

  /// 구글/네이버/카카오 가입 직후 호출. 신규 축하 보상 100 SHARE 가산.
  Future<void> completeSocialSignup({
    String? referralCode,
  }) async {
    state = state.copyWith(
      actionStatus: const AsyncLoading(),
      clearLastError: true,
    );
    try {
      final uid = _requireUid();
      if (!state.signupRewardApplied) {
        await ref.read(userRepositoryProvider).applySignupReward(
              uid: uid,
              shareAmount: EconomyConstants.signupRewardSrv,
              referralCode: referralCode,
            );
      }
      state = state.copyWith(
        phase: OnboardingPhase.sensitiveConsent,
        signupRewardApplied: true,
        actionStatus: const AsyncData(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  // ── 2단계: 민감정보 분리 동의 ────────────────────────────────────────────

  void setLocationConsent(bool value) {
    state = state.copyWith(locationConsent: value, clearLastError: true);
  }

  void setHealthHrConsent(bool value) {
    state = state.copyWith(healthHrConsent: value, clearLastError: true);
  }

  /// 필수 위치 동의 검증 후 3단계로 진행. 건강정보(HR)는 선택.
  Future<void> submitSensitiveConsents() async {
    if (!state.locationConsent) {
      state = state.copyWith(
        lastError: '위치정보 수집 및 이용약관에 동의해야 합니다.',
        actionStatus: AsyncError(
          NicknameValidationException('위치정보 수집 및 이용약관에 동의해야 합니다.'),
          StackTrace.current,
        ),
      );
      throw NicknameValidationException('위치정보 수집 및 이용약관에 동의해야 합니다.');
    }

    state = state.copyWith(actionStatus: const AsyncLoading());
    try {
      final uid = _requireUid();
      await ref.read(userRepositoryProvider).updateOnboardingConsents(
            uid: uid,
            locationConsent: state.locationConsent,
            healthHrConsent: state.healthHrConsent,
          );
      state = state.copyWith(
        phase: OnboardingPhase.deviceSync,
        actionStatus: const AsyncData(null),
        clearLastError: true,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  // ── 3단계: 기기 연동 ─────────────────────────────────────────────────────

  /// 네이티브 헬스 권한 승인 — 토큰 매핑·Jena 준비 이벤트만 수행하고 단계는 유지.
  Future<void> recordNativeWatchAuthorization({
    required WatchType watchType,
  }) async {
    state = state.copyWith(
      actionStatus: const AsyncLoading(),
      clearLastError: true,
    );
    try {
      await _mapWatchApiTokenAndStageJena(
        watchType: watchType,
        watchApiToken: _syntheticWatchApiToken(watchType),
      );
      state = state.copyWith(
        nativeWatchLinked: true,
        actionStatus: const AsyncData(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        nativeWatchLinked: true,
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
    }
  }

  /// Garmin OAuth 성공 — `isGarminConnected`를 즉시 true로 승인.
  Future<void> markGarminConnected({String? watchApiToken}) async {
    state = state.copyWith(
      isGarminConnected: true,
      actionStatus: const AsyncLoading(),
      clearLastError: true,
    );
    try {
      await _mapWatchApiTokenAndStageJena(
        watchType: WatchType.garmin,
        watchApiToken: watchApiToken ??
            _syntheticWatchApiToken(WatchType.garmin),
      );
      final inOnboardingDeviceStep = state.phase == OnboardingPhase.deviceSync ||
          state.phase == OnboardingPhase.pushSoftPrompt;
      if (!inOnboardingDeviceStep) {
        final uid = _currentUid();
        if (uid != null) {
          await ref.read(userRepositoryProvider).updateWatchType(
                uid: uid,
                watchType: WatchType.garmin,
              );
        }
      }
      state = state.copyWith(
        isGarminConnected: true,
        actionStatus: const AsyncData(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        isGarminConnected: true,
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
    }
  }

  /// CTA 「연동 완료하고 시작하기」 — 네이티브 또는 가민이 1개 이상일 때만 3→3.5 전이.
  Future<void> completeWatchLinkAndStart({
    WatchType? preferredWatchType,
  }) async {
    if (!state.canCompleteWatchLink) {
      throw StateError('네이티브 또는 Garmin 연동이 필요합니다.');
    }
    final watchType = preferredWatchType ??
        (state.nativeWatchLinked
            ? WatchType.galaxyWatch
            : WatchType.garmin);
    await markDeviceSynced(watchType: watchType);
  }

  Future<void> _mapWatchApiTokenAndStageJena({
    required WatchType watchType,
    required String watchApiToken,
  }) async {
    final uid = _currentUid();
    if (uid != null && uid.isNotEmpty) {
      await ref.read(userRepositoryProvider).mapWatchApiToken(
            uid: uid,
            watchApiToken: watchApiToken,
            watchType: watchType,
          );
      try {
        await ref.read(activityRepositoryProvider).mapWatchApiToken(
              userId: uid,
              watchApiToken: watchApiToken,
              watchType: watchType,
            );
      } catch (_) {
        // Activities 핸드오프 실패가 Users 토큰 매핑을 롤백하지 않음.
      }
    }
    await ref.read(watchLinkTelemetryServiceProvider).stageForJenaPipeline(
          watchType: watchType,
        );
  }

  String _syntheticWatchApiToken(WatchType watchType) {
    final uid = _currentUid() ?? 'anon';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'src_${watchType.code}_${uid.hashCode.abs()}_$stamp';
  }

  /// HealthKit / Health Connect 연동 완료 플래그.
  Future<void> markDeviceSynced({
    WatchType watchType = WatchType.galaxyWatch,
  }) async {
    state = state.copyWith(actionStatus: const AsyncLoading());
    try {
      final uid = _requireUid();
      await ref.read(userRepositoryProvider).updateWatchType(
            uid: uid,
            watchType: watchType,
          );
      // 3완료 → 3.5 Soft-prompt 트리거 (4단계 직전).
      state = state.copyWith(
        deviceSynced: true,
        phase: OnboardingPhase.pushSoftPrompt,
        softPromptVisible: true,
        actionStatus: const AsyncData(null),
      );
      ref.read(onboardingSoftPromptVisibleProvider.notifier).setVisible(true);
    } catch (error, stackTrace) {
      state = state.copyWith(
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  /// 기기 연동 스킵 후에도 3.5 Soft-prompt를 거친다.
  void skipDeviceSyncAndShowSoftPrompt() {
    state = state.copyWith(
      deviceSynced: false,
      phase: OnboardingPhase.pushSoftPrompt,
      softPromptVisible: true,
    );
    ref.read(onboardingSoftPromptVisibleProvider.notifier).setVisible(true);
  }

  // ── 3.5 Soft-prompt ──────────────────────────────────────────────────────

  Future<void> approvePushSoftPrompt({String? fcmToken}) async {
    state = state.copyWith(actionStatus: const AsyncLoading());
    try {
      final uid = _requireUid();
      await ref.read(userRepositoryProvider).updatePushSettings(
            uid: uid,
            enabled: true,
            fcmToken: fcmToken,
          );
      _enterPreliminaryEval(approved: true);
    } catch (error, stackTrace) {
      state = state.copyWith(
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> declinePushSoftPrompt() async {
    try {
      final uid = _currentUid();
      if (uid != null) {
        await ref.read(userRepositoryProvider).updatePushSettings(
              uid: uid,
              enabled: false,
            );
      }
    } catch (_) {
      // Soft-prompt 거부는 온보딩을 막지 않음.
    }
    _enterPreliminaryEval(approved: false);
  }

  void _enterPreliminaryEval({required bool approved}) {
    ref.read(onboardingSoftPromptVisibleProvider.notifier).setVisible(false);
    state = state.copyWith(
      softPromptVisible: false,
      softPromptApproved: approved,
      phase: OnboardingPhase.preliminaryEval,
      actionStatus: const AsyncData(null),
      clearLastError: true,
    );
  }

  // ── 4단계: 5회 예비 심사 + 지연 추천 보상 ────────────────────────────────

  /// 1km 예비 러닝 1회 페이스(초/km) 기록. 5회 도달 시 티어 확정·보상.
  Future<UserTier?> recordPreliminaryPaceSeconds(int paceSecPerKm) async {
    if (paceSecPerKm < 0) {
      throw ArgumentError.value(paceSecPerKm, 'paceSecPerKm', '음수 불가');
    }
    if (state.trialRewardApplied || state.isPreliminaryComplete) {
      return state.assignedTier;
    }

    final nextPaces = List<int>.of(state.preliminaryPaceSeconds)
      ..add(paceSecPerKm);
    if (nextPaces.length > EconomyConstants.trialRunsRequired) {
      nextPaces.removeRange(
        0,
        nextPaces.length - EconomyConstants.trialRunsRequired,
      );
    }

    state = state.copyWith(
      preliminaryPaceSeconds: nextPaces,
      phase: OnboardingPhase.preliminaryEval,
      assignedTier: nextPaces.length < EconomyConstants.trialRunsRequired
          ? const UserTier(
              group: AnimalGroup.snail,
              subTier: SubTier.bronze,
            )
          : state.assignedTier,
    );

    if (nextPaces.length < EconomyConstants.trialRunsRequired) {
      final uid = _currentUid();
      if (uid != null) {
        await ref.read(userRepositoryProvider).updateTrialRunCount(
              uid: uid,
              trialRunCount: nextPaces.length,
            );
      }
      return null;
    }

    return _finalizePreliminaryEvaluation(nextPaces);
  }

  Future<UserTier> _finalizePreliminaryEvaluation(List<int> paces) async {
    state = state.copyWith(actionStatus: const AsyncLoading());
    try {
      final uid = _requireUid();
      final sum = paces.fold<int>(0, (a, b) => a + b);
      final avg = sum ~/ paces.length;
      final tier = UserTier.fromAveragePaceSeconds(avg);

      if (!state.trialRewardApplied) {
        ref
            .read(walletProvider.notifier)
            .chargeShare(EconomyConstants.trialCompletionRewardSrv);
      }

      await ref.read(userRepositoryProvider).completePreliminaryEvaluation(
            uid: uid,
            tierRank: tier.rankScore,
            tierCode: tier.firestoreCode,
            averagePaceSeconds: avg,
            trialShareReward: EconomyConstants.trialCompletionRewardSrv,
          );

      // 추천인 300 토큰 지연 지급 — 최대 10명 한도 락 해제 지시 (비동기 인계).
      // 실패해도 본인 온보딩 완료는 유지.
      unawaited(
        ref
            .read(userRepositoryProvider)
            .enqueueReferralUnlock(
              referredUid: uid,
              rewardShare: EconomyConstants.referralRewardSrv,
              maxPayouts: EconomyConstants.maxReferralPayouts,
            )
            .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'SrcOnboardingController referral unlock: $error\n$stackTrace',
          );
        }),
      );

      state = state.copyWith(
        assignedTier: tier,
        trialRewardApplied: true,
        phase: OnboardingPhase.completed,
        actionStatus: const AsyncData(null),
        clearLastError: true,
      );
      return tier;
    } catch (error, stackTrace) {
      state = state.copyWith(
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  // ── 요구사항 3: 닉네임 + 100 DIA + Jena 강제 승급 ────────────────────────

  /// 공백 제외 2~12자, 한글/영문/숫자만. 비속어 포함 시 에러.
  String validateNickname(String raw) {
    final nickname = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (nickname.isEmpty) {
      throw NicknameValidationException('닉네임은 공백 제외 2~12자여야 합니다.');
    }
    final live = liveNicknameError(raw);
    if (live != null) {
      throw NicknameValidationException(live);
    }
    return nickname;
  }

  /// 입력 중 실시간 검증. 통과 시 null.
  String? liveNicknameError(String raw) => NicknameValidator.validate(raw);

  static bool isUnsetNickname(String nickname) {
    final trimmed = nickname.trim();
    return trimmed.isEmpty || trimmed == placeholderNickname;
  }

  /// 최초 로그인 닉네임 설정 (DIA 수수료 없음).
  Future<void> setInitialNickname(String rawNickname) async {
    state = state.copyWith(
      nicknameStatus: const AsyncLoading(),
      clearLastError: true,
    );
    try {
      final nickname = validateNickname(rawNickname);
      final uid = _currentUid();
      if (uid != null && uid.isNotEmpty) {
        try {
          await ref.read(userRepositoryProvider).setInitialNickname(
                uid: uid,
                nickname: nickname,
              );
        } catch (error, stackTrace) {
          debugPrint(
            'SrcOnboardingController setInitialNickname persist: $error\n$stackTrace',
          );
        }
      }
      state = state.copyWith(
        displayNickname: nickname,
        nicknameStatus: const AsyncData(null),
      );
      await ref.read(persistedUsernameProvider.notifier).updateName(nickname);
    } catch (error, stackTrace) {
      state = state.copyWith(
        nicknameStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  /// 홈/마이페이지 닉네임 변경 alias — [updateNickname]과 동일.
  Future<void> changeUserNickname(String newName) => updateNickname(newName);

  /// 마이페이지 닉네임 변경 — 수수료 100 DIA 차감 후 Firestore 반영.
  Future<void> updateNickname(String rawNickname) async {
    state = state.copyWith(
      nicknameStatus: const AsyncLoading(),
      clearLastError: true,
    );
    try {
      final nickname = validateNickname(rawNickname);
      final uid = _requireUid();
      final fee = EconomyConstants.nicknameChangeFeeDia;
      final wallet = ref.read(walletProvider);

      if (wallet.diamondBalance < fee) {
        throw InsufficientDiaException(
          requiredDia: fee,
          availableDia: wallet.diamondBalance,
        );
      }

      ref.read(walletProvider.notifier).debitDia(fee);
      await ref.read(userRepositoryProvider).updateNicknameWithDiaFee(
            uid: uid,
            nickname: nickname,
            diaFee: fee,
          );
      await ref.read(walletRepositoryProvider).logClientWalletTransaction(
            uid: uid,
            title: '닉네임 변경 다이아 소모 🪙',
            amount: -fee,
            assetType: 'DIA',
          );

      state = state.copyWith(
        displayNickname: nickname,
        nicknameStatus: const AsyncData(null),
      );
      await ref.read(persistedUsernameProvider.notifier).updateName(nickname);
    } catch (error, stackTrace) {
      state = state.copyWith(
        nicknameStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  /// Jena 검시관 샌드배깅 탐지 → 타겟 티어로 강제 승급.
  Future<void> forcePromoteTierByJena(UserTier targetTier) async {
    state = state.copyWith(actionStatus: const AsyncLoading());
    try {
      final uid = _requireUid();
      final current = state.assignedTier;
      if (current != null && targetTier.rankScore <= current.rankScore) {
        // 강제 승급만 허용 (동급·강등 패킷은 무시).
        state = state.copyWith(actionStatus: const AsyncData(null));
        return;
      }

      await ref.read(userRepositoryProvider).forceSetTierFromJena(
            uid: uid,
            tierRank: targetTier.rankScore,
            tierCode: targetTier.firestoreCode,
          );

      state = state.copyWith(
        assignedTier: targetTier,
        actionStatus: const AsyncData(null),
        clearLastError: true,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        actionStatus: AsyncError(error, stackTrace),
        lastError: error.toString(),
      );
      rethrow;
    }
  }
}

final srcOnboardingControllerProvider =
    NotifierProvider<SrcOnboardingController, SrcOnboardingState>(
  SrcOnboardingController.new,
);

/// 홈 대시보드 구독 alias.
final onboardingProvider = srcOnboardingControllerProvider;

/// 3.5 Soft-prompt 바텀시트 표시 여부 (UI가 watch).
class OnboardingSoftPromptVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void setVisible(bool value) => state = value;
}

final onboardingSoftPromptVisibleProvider =
    NotifierProvider<OnboardingSoftPromptVisibleNotifier, bool>(
  OnboardingSoftPromptVisibleNotifier.new,
);

/// 현재 온보딩 단계의 go_router 경로.
final onboardingRoutePathProvider = Provider<String>((ref) {
  return ref.watch(srcOnboardingControllerProvider).phase.routePath;
});

/// 로컬 기기 영구 저장 닉네임 (앱 재시작 후에도 유지).
@immutable
class PersistedUsername {
  const PersistedUsername({this.value = '', this.ready = false});

  final String value;
  final bool ready;
}

class PersistedUsernameNotifier extends Notifier<PersistedUsername> {
  static const prefsKey = 'username';

  @override
  PersistedUsername build() {
    unawaited(_hydrate());
    return const PersistedUsername();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefsKey)?.trim() ?? '';
    state = PersistedUsername(value: saved, ready: true);
  }

  Future<void> updateName(String newName) async {
    final trimmed = newName.trim();
    state = PersistedUsername(value: trimmed, ready: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, trimmed);
  }
}

final persistedUsernameProvider =
    NotifierProvider<PersistedUsernameNotifier, PersistedUsername>(
  PersistedUsernameNotifier.new,
);

/// 홈 헤더 실시간 닉네임.
final userNicknameProvider = Provider<String>((ref) {
  final persisted = ref.watch(persistedUsernameProvider);
  if (persisted.ready &&
      persisted.value.isNotEmpty &&
      !SrcOnboardingController.isUnsetNickname(persisted.value)) {
    return persisted.value.trim();
  }
  final fromController =
      ref.watch(srcOnboardingControllerProvider).displayNickname.trim();
  if (fromController.isNotEmpty &&
      !SrcOnboardingController.isUnsetNickname(fromController)) {
    return fromController;
  }
  final profile = ref.watch(activeUserProfileProvider).asData?.value;
  return profile?.nickname.trim() ?? '';
});

/// 닉네임 미설정 시 홈 전면 시트 강제 표시.
final needsNicknameSetupProvider = Provider<bool>((ref) {
  final persisted = ref.watch(persistedUsernameProvider);
  if (!persisted.ready) return false;
  final profileAsync = ref.watch(activeUserProfileProvider);
  if (!profileAsync.hasValue) return false;
  return SrcOnboardingController.isUnsetNickname(
    ref.watch(userNicknameProvider),
  );
});

/// 5회 예선 페이스로 확정된 25티어. 미완주·우회는 달팽이 폴백.
final activeUserTierStructProvider = Provider<UserTier?>((ref) {
  final onboarding = ref.watch(srcOnboardingControllerProvider);
  final profile = ref.watch(activeUserProfileProvider).asData?.value;
  return UserTier.resolveForProgress(
    preliminaryRunPacesLength: onboarding.preliminaryPaceSeconds.length,
    assigned: onboarding.assignedTier,
    firestoreRank: profile?.tier ?? 0,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// 리텐션 — 일일 채굴 / 실천 스트릭 / 스마트 푸시 큐
// ─────────────────────────────────────────────────────────────────────────────

abstract final class RetentionCalendar {
  static String dateKey(DateTime d) => KstCalendar.dateKey(d);

  static String weekKey(DateTime d) {
    final kst = KstCalendar.toKst(d);
    final monday = DateTime.utc(kst.year, kst.month, kst.day)
        .subtract(Duration(days: kst.weekday - 1));
    return KstCalendar.dateKeyFromYmd(monday.year, monday.month, monday.day);
  }

  static DateTime dateOnly(DateTime d) {
    final kst = KstCalendar.toKst(d);
    return DateTime.utc(kst.year, kst.month, kst.day);
  }
}

abstract final class RetentionMetrics {
  static bool isJenaPassed(ActivityModel activity) {
    return activity.jenaStatus == ActivityStatus.passed ||
        activity.validationStatus == ActivityValidationStatus.verified;
  }

  static double kmOnDay(List<ActivityModel> activities, DateTime day) {
    final key = RetentionCalendar.dateKey(day);
    var sum = 0.0;
    for (final activity in activities) {
      final at = activity.completedAt;
      if (at == null || !isJenaPassed(activity)) continue;
      if (RetentionCalendar.dateKey(at) != key) continue;
      sum += activity.distanceKm;
    }
    return sum;
  }

  static double todayDistance({
    required UserProfile profile,
    required List<ActivityModel> activities,
    required DateTime now,
  }) {
    final fromActs = kmOnDay(activities, now);
    if (fromActs > 0) return fromActs;
    final mining = profile.economy.dailyMining;
    if (mining.dateKey == RetentionCalendar.dateKey(now) &&
        mining.earnedKm > 0) {
      return mining.earnedKm;
    }
    return profile.safeDailyDistance;
  }

  static bool qualifiesDay(List<ActivityModel> activities, DateTime day) {
    return kmOnDay(activities, day) >= EconomyConstants.streakMinKm;
  }

  static int streakCount(List<ActivityModel> activities, DateTime now) {
    var cursor = RetentionCalendar.dateOnly(now);
    if (!qualifiesDay(activities, cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (qualifiesDay(activities, cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static Set<int> markedWeekdays(
    List<ActivityModel> activities,
    DateTime now,
  ) {
    final monday = RetentionCalendar.dateOnly(now)
        .subtract(Duration(days: now.weekday - 1));
    final marked = <int>{};
    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (qualifiesDay(activities, day)) {
        marked.add(day.weekday);
      }
    }
    return marked;
  }

  static double shoeMileage({
    required UserProfile profile,
    required List<ActivityModel> activities,
  }) {
    var sum = 0.0;
    for (final activity in activities) {
      if (isJenaPassed(activity)) {
        sum += activity.distanceKm;
      }
    }
    return sum > profile.safeRunningShoeMileage
        ? sum
        : profile.safeRunningShoeMileage;
  }
}

class RetentionPushPayload {
  const RetentionPushPayload({
    required this.code,
    required this.title,
    required this.body,
    this.routeName,
    this.extra,
  });

  final String code;
  final String title;
  final String body;
  final String? routeName;
  final Map<String, String>? extra;
}

abstract final class RetentionAlertEngine {
  static bool inGoldenWindow(DateTime now, int preferredHour) {
    final hour = preferredHour.clamp(0, 23);
    if (now.hour == hour && now.minute < 30) return true;
    final prev = hour == 0 ? 23 : hour - 1;
    return now.hour == prev && now.minute >= 30;
  }

  static List<RetentionPushPayload> evaluate({
    required UserProfile profile,
    required List<ActivityModel> activities,
    required DateTime now,
    required double dailyKm,
    required double shoeKm,
  }) {
    final payloads = <RetentionPushPayload>[];
    final today = RetentionCalendar.dateKey(now);

    if (shoeKm >= ImpactConstants.shoeMileageGoalKm &&
        profile.shoeAlertTierSent < 100) {
      payloads.add(
        RetentionPushPayload(
          code: 'shoe_limit',
          title: '러닝화 수명 한도',
          body:
              '러너님, 등록하신 러닝화의 누적 수명이 ${shoeKm.round()}km에 도달했습니다. '
              '관절 보호와 완벽한 질주를 위해 쿠션 상태를 확인해 보세요! 👟',
        ),
      );
    } else if (shoeKm >= EconomyConstants.shoeMileageWarnKm &&
        profile.shoeAlertTierSent < 80) {
      payloads.add(
        RetentionPushPayload(
          code: 'shoe_warn',
          title: '러닝화 쿠션 점검',
          body:
              '러너님, 등록하신 러닝화의 누적 수명이 ${shoeKm.round()}km에 도달했습니다. '
              '관절 보호와 완벽한 질주를 위해 쿠션 상태를 확인해 보세요! 👟',
        ),
      );
    }

    if (dailyKm <= 0 &&
        profile.goldenHourAlertDateKey != today &&
        inGoldenWindow(now, profile.preferredRunHour)) {
      payloads.add(
        const RetentionPushPayload(
          code: 'golden_hour',
          title: '골든 아워 채굴',
          body:
              '오늘의 영웅이 될 준비가 되셨나요? 러너님만을 위한 골든 아워입니다. '
              '가볍게 달리고 일일 500원 채굴 캡을 달성해 보세요! 👼',
          routeName: RouteNames.preliminaryEvalName,
        ),
      );
    }

    ActivityModel? pending;
    for (final activity in activities) {
      if (activity.needsJenaAppeal) {
        pending = activity;
        break;
      }
    }
    if (pending != null &&
        pending.id != profile.lastJenaPendingNotifiedId) {
      payloads.add(
        RetentionPushPayload(
          code: 'jena_pending',
          title: '기록 검증 보류',
          body:
              '⚠️ 방금 완료하신 기록의 검증이 보류되었습니다. '
              '억울한 오탐지가 없도록 7일 이내에 원본 센서 로그로 '
              '소명 자료를 간편 제출해 주세요! 〉',
          routeName: RouteNames.appealCenter,
          extra: {'activityId': pending.id},
        ),
      );
    }

    return payloads;
  }
}

class RetentionAlertController extends Notifier<List<RetentionPushPayload>> {
  var _busy = false;
  var _shoeTierSent = 0;
  var _goldenDate = '';
  var _jenaId = '';
  var _streakWeek = '';

  @override
  List<RetentionPushPayload> build() {
    ref.listen<AsyncValue<UserModel>>(activeUserProfileProvider, (_, __) {
      unawaited(evaluate());
    });
    ref.listen<AsyncValue<List<ActivityModel>>>(
      recentActivitiesProvider,
      (_, __) {
        unawaited(evaluate());
      },
    );
    Future<void>.microtask(evaluate);
    return const [];
  }

  Future<void> evaluate() async {
    if (_busy) return;
    _busy = true;
    try {
      await _evaluateUnlocked();
    } finally {
      _busy = false;
    }
  }

  Future<void> _evaluateUnlocked() async {
    final profile = ref.read(activeUserProfileProvider).asData?.value;
    if (profile == null || profile.uid.isEmpty) return;
    final activities =
        ref.read(recentActivitiesProvider).value ?? const <ActivityModel>[];
    final now = DateTime.now();
    final daily = RetentionMetrics.todayDistance(
      profile: profile,
      activities: activities,
      now: now,
    );
    final streak = RetentionMetrics.streakCount(activities, now);
    final shoe = RetentionMetrics.shoeMileage(
      profile: profile,
      activities: activities,
    );
    final week = RetentionCalendar.weekKey(now);
    final shoeSent = profile.shoeAlertTierSent > _shoeTierSent
        ? profile.shoeAlertTierSent
        : _shoeTierSent;
    final goldenSent = _goldenDate.isNotEmpty
        ? _goldenDate
        : profile.goldenHourAlertDateKey;
    final jenaSent = _jenaId.isNotEmpty
        ? _jenaId
        : profile.lastJenaPendingNotifiedId;
    final streakWeekSent = _streakWeek.isNotEmpty
        ? _streakWeek
        : profile.streakBonusWeekKey;
    final gated = profile.copyWith(
      shoeAlertTierSent: shoeSent,
      goldenHourAlertDateKey: goldenSent,
      lastJenaPendingNotifiedId: jenaSent,
      streakBonusWeekKey: streakWeekSent,
    );
    final weekDone =
        RetentionMetrics.markedWeekdays(activities, now).length >=
            EconomyConstants.streakBonusDays;

    final repo = ref.read(userRepositoryProvider);
    final persist = <String, Object?>{};
    if ((profile.safeDailyDistance - daily).abs() > 0.05) {
      persist['dailyDistance'] = daily;
    }
    if (profile.safeActivityStreakCount != streak) {
      persist['activityStreakCount'] = streak;
    }
    if ((profile.safeRunningShoeMileage - shoe).abs() > 0.05) {
      persist['runningShoeMileage'] = shoe;
    }

    if (weekDone && gated.streakBonusWeekKey != week) {
      persist['streakBonusWeekKey'] = week;
      _streakWeek = week;
      try {
        await repo.addDiamondBalance(
          uid: profile.uid,
          diamondAmount: EconomyConstants.streakBonusDia,
        );
        ref.read(walletProvider.notifier).creditDia(
              EconomyConstants.streakBonusDia,
            );
      } catch (_) {}
    }

    final payloads = RetentionAlertEngine.evaluate(
      profile: gated,
      activities: activities,
      now: now,
      dailyKm: daily,
      shoeKm: shoe,
    );

    for (final payload in payloads) {
      try {
        await repo.enqueueRetentionPush(
          uid: profile.uid,
          code: payload.code,
          title: payload.title,
          body: payload.body,
          routeName: payload.routeName,
          extra: payload.extra,
        );
      } catch (_) {}
      debugPrint('RETENTION_PUSH [${payload.code}] ${payload.body}');
      if (payload.code == 'shoe_limit') {
        persist['shoeAlertTierSent'] = 100;
        _shoeTierSent = 100;
      } else if (payload.code == 'shoe_warn') {
        persist['shoeAlertTierSent'] = 80;
        _shoeTierSent = 80;
      } else if (payload.code == 'golden_hour') {
        persist['goldenHourAlertDateKey'] = RetentionCalendar.dateKey(now);
        _goldenDate = persist['goldenHourAlertDateKey'] as String;
      } else if (payload.code == 'jena_pending') {
        persist['lastJenaPendingNotifiedId'] =
            payload.extra?['activityId'] ?? '';
        _jenaId = persist['lastJenaPendingNotifiedId'] as String;
      }
    }

    if (persist.isNotEmpty) {
      try {
        await repo.updateRetentionFields(
          uid: profile.uid,
          dailyDistance: persist['dailyDistance'] as double?,
          activityStreakCount: persist['activityStreakCount'] as int?,
          runningShoeMileage: persist['runningShoeMileage'] as double?,
          streakBonusWeekKey: persist['streakBonusWeekKey'] as String?,
          shoeAlertTierSent: persist['shoeAlertTierSent'] as int?,
          goldenHourAlertDateKey: persist['goldenHourAlertDateKey'] as String?,
          lastJenaPendingNotifiedId:
              persist['lastJenaPendingNotifiedId'] as String?,
        );
      } catch (_) {}
    }

    if (payloads.isNotEmpty) {
      state = payloads;
    }
  }
}

final retentionAlertControllerProvider =
    NotifierProvider<RetentionAlertController, List<RetentionPushPayload>>(
  RetentionAlertController.new,
);

final retentionDailyKmProvider = Provider<double>((ref) {
  ref.watch(retentionAlertControllerProvider);
  final profile = ref.watch(activeUserProfileProvider).asData?.value ??
      UserModel.dashboardDefault(uid: '');
  final activities =
      ref.watch(recentActivitiesProvider).value ?? const <ActivityModel>[];
  return RetentionMetrics.todayDistance(
    profile: profile,
    activities: activities,
    now: DateTime.now(),
  );
});

final walkingPendingShareProvider = StateProvider<double>((ref) => 0.0);
