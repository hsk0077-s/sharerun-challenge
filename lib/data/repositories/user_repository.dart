import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<void> ensureUserDocument({
    required String uid,
    String watchType = 'none',
  }) async {
    final userRef = _firestoreService.doc(FirestorePaths.user(uid));
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      return userRef.set({
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return userRef.set({
      'uid': uid,
      'watchType': watchType,
      'tier': 0,
      'nickname': '',
      'gender': 'male',
      'donationCount': 0,
      'cumulativeDonationAmount': 0,
      'dailyDistance': 0,
      'activityStreakCount': 0,
      'runningShoeMileage': 0,
      'streakBonusWeekKey': '',
      'shoeAlertTierSent': 0,
      'goldenHourAlertDateKey': '',
      'lastJenaPendingNotifiedId': '',
      'preferredRunHour': 19,
      'preliminaryRunsCount': 0,
      'healthDataConsent': false,
      'sensitiveDataConsent': false,
      'termsAccepted': false,
      'pushNotificationsEnabled': false,
      'wallet': {
        'shareBalance': 0,
        'diamondBalance': 0,
        'valueTokenBalance': 0,
        'totalDonationValue': 0,
      },
      'economy': {
        'signupRewardClaimed': false,
        'trialRunCount': 0,
        'trialMilestoneRewardClaimed': false,
        'firstTierGranted': false,
        'referralPayoutCount': 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<int> watchUserTier(String uid) {
    return _firestoreService.doc(FirestorePaths.user(uid)).snapshots().map(
      (snapshot) {
        final data = snapshot.data();
        return (data?['tier'] as num?)?.toInt() ?? 1;
      },
    );
  }

  Stream<UserModel> watchUserProfile(String uid) {
    return _firestoreService.doc(FirestorePaths.user(uid)).snapshots().asyncMap(
      (snapshot) async {
        if (!snapshot.exists || snapshot.data() == null) {
          // New user: seed a default document, never throw to the UI stream.
          try {
            await ensureUserDocument(uid: uid);
          } catch (_) {
            // Permission / offline — still return an in-memory default.
          }
          return UserModel.dashboardDefault(uid: uid);
        }

        try {
          final data = Map<String, dynamic>.from(snapshot.data()!);
          data['uid'] = data['uid'] ?? uid;
          return UserModel.fromJson(data);
        } catch (_) {
          return UserModel.dashboardDefault(uid: uid);
        }
      },
    );
  }

  Future<void> updateHealthDataConsent({
    required String uid,
    required bool consent,
  }) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'healthDataConsent': consent,
      'sensitiveDataConsent': consent,
      'healthDataConsentUpdatedAt': FieldValue.serverTimestamp(),
      'sensitiveDataConsentUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSensitiveDataConsent({
    required String uid,
    required bool consent,
  }) {
    return updateHealthDataConsent(uid: uid, consent: consent);
  }

  Future<void> updateWatchType({
    required String uid,
    required WatchType watchType,
  }) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'watchType': watchType.code,
      'watchTypeUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 성별 영구 동기화 — GCP Firestore merge.
  Future<void> updateGender({
    required String uid,
    required String gender,
  }) {
    final normalized = UserModel.normalizeGender(gender);
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'gender': normalized,
      'genderUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 후원 1건 원자 누적 + 천사 등급 코드 기록.
  Future<void> recordDonation({
    required String uid,
    required int amountWon,
    required String angelTierCode,
  }) async {
    if (amountWon < 0) {
      throw ArgumentError.value(amountWon, 'amountWon');
    }
    await ensureUserDocument(uid: uid);
    final userRef = _firestoreService.doc(FirestorePaths.user(uid));
    await _firestoreService.runTransaction((transaction) async {
      transaction.set(
        userRef,
        {
          'donationCount': FieldValue.increment(1),
          'cumulativeDonationAmount': FieldValue.increment(amountWon),
          'angelTierCode': angelTierCode,
          'lastDonationAmountWon': amountWon,
          'lastDonatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Users.watch_api_token 매핑 — 어뷰징 차단 Jena 파이프라인 핸드오프.
  Future<void> mapWatchApiToken({
    required String uid,
    required String watchApiToken,
    required WatchType watchType,
  }) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'watch_api_token': watchApiToken,
      'watchApiToken': watchApiToken,
      'watchLinkPendingType': watchType.code,
      'isDeviceConnected': true,
      'watchApiTokenUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Atomically increments `wallet.shareBalance` for pedometer claims.
  Future<void> addShareBalance({
    required String uid,
    required int shareAmount,
  }) async {
    if (shareAmount <= 0) {
      return;
    }
    final userRef = _firestoreService.doc(FirestorePaths.user(uid));
    await ensureUserDocument(uid: uid);
    await userRef.set({
      'wallet.shareBalance': FieldValue.increment(shareAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Atomically increments `wallet.diamondBalance` for stamp-tour rewards.
  Future<void> addDiamondBalance({
    required String uid,
    required int diamondAmount,
  }) async {
    if (diamondAmount <= 0) {
      return;
    }
    final userRef = _firestoreService.doc(FirestorePaths.user(uid));
    await ensureUserDocument(uid: uid);
    await userRef.set({
      'wallet.diamondBalance': FieldValue.increment(diamondAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 잔액 증감 + 아이템/스폰서 플래그. 재설치 복원용 원장.
  Future<void> mergeEconomyState({
    required String uid,
    int? shareDelta,
    int? diamondDelta,
    int? valueDelta,
    bool? hasCPR,
    bool? isSponsored,
  }) async {
    if (uid.isEmpty) return;
    final share = shareDelta ?? 0;
    final diamond = diamondDelta ?? 0;
    final value = valueDelta ?? 0;
    if (share == 0 &&
        diamond == 0 &&
        value == 0 &&
        hasCPR == null &&
        isSponsored == null) {
      return;
    }
    await ensureUserDocument(uid: uid);
    await _firestoreService.doc(FirestorePaths.user(uid)).set({
      if (share != 0) 'wallet.shareBalance': FieldValue.increment(share),
      if (diamond != 0) 'wallet.diamondBalance': FieldValue.increment(diamond),
      if (value != 0) 'wallet.valueTokenBalance': FieldValue.increment(value),
      if (hasCPR != null) 'hasCPR': hasCPR,
      if (isSponsored != null) 'isSponsored': isSponsored,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 네이티브 헬스 연동 완료 — 관리 대시보드 조회용 플래그.
  Future<void> completeNativeDeviceOnboarding({required String uid}) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'isOnboardingCompleted': true,
      'isDeviceConnected': true,
      'connectedDeviceType': 'NATIVE',
      'watchType': WatchType.galaxyWatch.code,
      'healthDataConsent': true,
      'sensitiveDataConsent': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 기기 연동 건너뛰기 — 온보딩만 완료 처리.
  Future<void> skipDeviceOnboarding({required String uid}) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'isOnboardingCompleted': true,
      'isDeviceConnected': false,
      'connectedDeviceType': 'NONE',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptTerms({
    required String uid,
    required bool pushNotificationsEnabled,
  }) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'termsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'pushNotificationsUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Guest login profile — skips onboarding and marks the account as test-only.
  Future<void> bootstrapGuestProfile({required String uid}) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'uid': uid,
      'watchType': 'none',
      'tier': 1,
      'isGuest': true,
      'healthDataConsent': false,
      'sensitiveDataConsent': false,
      'termsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'pushNotificationsEnabled': false,
      'wallet': {
        'shareBalance': 0,
        'diamondBalance': 0,
        'valueTokenBalance': 0,
        'totalDonationValue': 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePushSettings({
    required String uid,
    required bool enabled,
    String? fcmToken,
  }) {
    final payload = <String, dynamic>{
      'pushNotificationsEnabled': enabled,
      'pushNotificationsUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fcmToken != null) {
      payload['fcmToken'] = fcmToken;
      payload['fcmTokenUpdatedAt'] = FieldValue.serverTimestamp();
    }
    return _firestoreService.doc(FirestorePaths.user(uid)).set(
          payload,
          SetOptions(merge: true),
        );
  }

  /// 온보딩 2단계 — 위치(필수) / 건강정보 HR(선택) 분리 동의.
  Future<void> updateOnboardingConsents({
    required String uid,
    required bool locationConsent,
    required bool healthHrConsent,
  }) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'termsAccepted': locationConsent,
      'sensitiveDataConsent': locationConsent,
      'healthDataConsent': healthHrConsent,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'sensitiveDataConsentUpdatedAt': FieldValue.serverTimestamp(),
      'healthDataConsentUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 1단계 신규 가입 보상 100 SHARE (+ 선택 추천코드).
  Future<void> applySignupReward({
    required String uid,
    required int shareAmount,
    String? referralCode,
  }) async {
    if (shareAmount <= 0) return;
    final payload = <String, dynamic>{
      'wallet.shareBalance': FieldValue.increment(shareAmount),
      'economy.signupRewardClaimed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final code = referralCode?.trim();
    if (code != null && code.isNotEmpty) {
      payload['economy.referredByCode'] = code;
    }
    await ensureUserDocument(uid: uid);
    await _firestoreService.doc(FirestorePaths.user(uid)).set(
          payload,
          SetOptions(merge: true),
        );
  }

  Future<void> updateTrialRunCount({
    required String uid,
    required int trialRunCount,
  }) {
    final count = trialRunCount.clamp(0, 5);
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'preliminaryRunsCount': count,
      'economy.trialRunCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 4단계 완료 — 티어 확정 + 500 SHARE + 추천 지연 지급 트리거 준비.
  Future<void> completePreliminaryEvaluation({
    required String uid,
    required int tierRank,
    required String tierCode,
    required int averagePaceSeconds,
    required int trialShareReward,
  }) async {
    await ensureUserDocument(uid: uid);
    await _firestoreService.doc(FirestorePaths.user(uid)).set({
      'tier': tierRank,
      'tierCode': tierCode,
      'averagePaceSeconds': averagePaceSeconds,
      'preliminaryRunsCount': 5,
      'economy.trialRunCount': 5,
      'economy.trialMilestoneRewardClaimed': true,
      'economy.firstTierGranted': true,
      if (trialShareReward > 0)
        'wallet.shareBalance': FieldValue.increment(trialShareReward),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 추천인 300 SHARE 지연 보상 — 백엔드 락 해제 지시 (최대 [maxPayouts]명).
  Future<void> enqueueReferralUnlock({
    required String referredUid,
    required int rewardShare,
    required int maxPayouts,
  }) async {
    await _firestoreService.doc(FirestorePaths.user(referredUid)).set({
      'economy.referralUnlockPending': true,
      'economy.referralUnlockRewardShare': rewardShare,
      'economy.referralUnlockMaxPayouts': maxPayouts,
      'economy.referralUnlockRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 최초 닉네임 설정 — DIA 차감 없음.
  Future<void> setInitialNickname({
    required String uid,
    required String nickname,
  }) async {
    await ensureUserDocument(uid: uid);
    await _firestoreService.doc(FirestorePaths.user(uid)).set({
      'nickname': nickname,
      'nicknameSetAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 닉네임 변경 + 100 DIA 원자적 차감.
  Future<void> updateNicknameWithDiaFee({
    required String uid,
    required String nickname,
    required int diaFee,
  }) async {
    if (diaFee < 0) {
      throw ArgumentError.value(diaFee, 'diaFee');
    }
    final userRef = _firestoreService.doc(FirestorePaths.user(uid));
    await ensureUserDocument(uid: uid);
    await _firestoreService.runTransaction((transaction) async {
      final snap = await transaction.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      final wallet = data['wallet'];
      final walletMap = switch (wallet) {
        final Map<String, dynamic> m => m,
        final Map m => Map<String, dynamic>.from(m),
        _ => <String, dynamic>{},
      };
      final currentDia = (walletMap['diamondBalance'] as num?)?.toInt() ?? 0;
      if (currentDia < diaFee) {
        throw StateError('DIA 잔액 부족: 필요 $diaFee, 보유 $currentDia');
      }
      transaction.set(
        userRef,
        {
          'nickname': nickname,
          'wallet.diamondBalance': FieldValue.increment(-diaFee),
          'nicknameUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> updateRetentionFields({
    required String uid,
    double? dailyDistance,
    int? activityStreakCount,
    double? runningShoeMileage,
    String? streakBonusWeekKey,
    int? shoeAlertTierSent,
    String? goldenHourAlertDateKey,
    String? lastJenaPendingNotifiedId,
  }) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      if (dailyDistance != null) 'dailyDistance': dailyDistance,
      if (activityStreakCount != null) 'activityStreakCount': activityStreakCount,
      if (runningShoeMileage != null) 'runningShoeMileage': runningShoeMileage,
      if (streakBonusWeekKey != null) 'streakBonusWeekKey': streakBonusWeekKey,
      if (shoeAlertTierSent != null) 'shoeAlertTierSent': shoeAlertTierSent,
      if (goldenHourAlertDateKey != null)
        'goldenHourAlertDateKey': goldenHourAlertDateKey,
      if (lastJenaPendingNotifiedId != null)
        'lastJenaPendingNotifiedId': lastJenaPendingNotifiedId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 리텐션 푸시 백엔드 큐. Cloud Function / FCM 워커가 소비한다.
  /// 알림센터 복원용으로 `users/{uid}/notifications`에도 동일 본문을 적재한다.
  Future<void> enqueueRetentionPush({
    required String uid,
    required String code,
    required String title,
    required String body,
    String? routeName,
    Map<String, String>? extra,
  }) async {
    if (uid.isEmpty) return;
    try {
      await _firestoreService
          .collection(FirestorePaths.userRetentionPushes(uid))
          .doc()
          .set({
        'code': code,
        'title': title,
        'body': body,
        if (routeName != null) 'routeName': routeName,
        if (extra != null) 'extra': extra,
        'delivered': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FIRESTORE NOTIFICATION] retentionPushes 적재 실패: $e');
    }
    try {
      await _firestoreService
          .collection(FirestorePaths.userNotifications(uid))
          .add({
        'title': title,
        'body': body,
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE NOTIFICATION] 시스템 알림 클라우드 업로드 성공');
    } catch (e) {
      debugPrint('[FIRESTORE NOTIFICATION] 시스템 알림 업로드 실패: $e');
    }
  }

  /// Jena 샌드배깅 탐지 패킷 — 강제 승급.
  Future<void> forceSetTierFromJena({
    required String uid,
    required int tierRank,
    required String tierCode,
  }) {
    return _firestoreService.doc(FirestorePaths.user(uid)).set({
      'tier': tierRank,
      'tierCode': tierCode,
      'jenaForcePromoted': true,
      'jenaForcePromotedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
