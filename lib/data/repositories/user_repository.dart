import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/async/stream_guards.dart';
import '../../core/constants/firestore_paths.dart';
import '../api/secured_action_api_client.dart';
import '../firebase/firestore_service.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository(
    this._firestoreService, {
    SecuredActionApiClient? securedActionApiClient,
  }) : _securedActionApiClient = securedActionApiClient;

  final FirestoreService _firestoreService;
  final SecuredActionApiClient? _securedActionApiClient;

  /// Matches `validUserCreate` in firestore.rules — extra keys or non-zero
  /// wallet / tier != 1 are rejected.
  Future<void> ensureUserDocument({
    required String uid,
    String watchType = 'none',
  }) async {
    final userRef = _firestoreService.doc(FirestorePaths.user(uid));
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      // Existing docs must not be touched here. A merge of uid/updatedAt
      // fails validUserProfileUpdate when watchType or sensitiveDataConsent
      // is missing (permission-denied on every ensureUserDocument call).
      return;
    }

    // Create payload must match validUserCreate (watchType always none).
    // [watchType] is applied later via updateWatchType, not on create.
    assert(watchType.isNotEmpty);
    return userRef.set({
      'uid': uid,
      'watchType': 'none',
      'tier': 1,
      'sensitiveDataConsent': false,
      'termsAccepted': false,
      'pushNotificationsEnabled': false,
      'wallet': {
        'shareBalance': 0,
        'diamondBalance': 0,
        'valueTokenBalance': 0,
        'totalDonationValue': 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> watchUserTier(String uid) {
    return onStreamErrorEmit<int>(
      _firestoreService.doc(FirestorePaths.user(uid)).snapshots().map(
        (snapshot) {
          final data = snapshot.data();
          return (data?['tier'] as num?)?.toInt() ?? 1;
        },
      ),
      1,
      debugLabel: 'watchUserTier',
    );
  }

  Stream<UserModel> watchUserProfile(String uid) {
    return onStreamErrorEmit<UserModel>(
      _firestoreService.doc(FirestorePaths.user(uid)).snapshots().asyncMap(
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
      ),
      UserModel.dashboardDefault(uid: uid),
      debugLabel: 'watchUserProfile',
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
  /// Donation totals are server-owned (sponsor webhook / winner reward).
  Future<void> recordDonation({
    required String uid,
    required int amountWon,
    required String angelTierCode,
  }) async {
    debugPrint(
      'recordDonation skipped (server-owned ledger): uid=$uid amount=$amountWon',
    );
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

  /// Pedometer SHARE minting is server-owned. Client no longer writes the ledger.
  Future<void> addShareBalance({
    required String uid,
    required int shareAmount,
  }) async {
    debugPrint(
      'addShareBalance skipped (server-owned wallet): uid=$uid amount=$shareAmount',
    );
  }

  /// Stamp-tour DIA minting is server-owned. Client no longer writes the ledger.
  Future<void> addDiamondBalance({
    required String uid,
    required int diamondAmount,
  }) async {
    debugPrint(
      'addDiamondBalance skipped (server-owned wallet): uid=$uid amount=$diamondAmount',
    );
  }

  /// Economy flags and balances are backend-owned. Client writes are ignored.
  Future<void> mergeEconomyState({
    required String uid,
    int? shareDelta,
    int? diamondDelta,
    int? valueDelta,
    bool? hasCPR,
    bool? hasSafeGuard,
    bool? isSponsored,
  }) async {
    debugPrint(
      'mergeEconomyState skipped (server-owned wallet): uid=$uid',
    );
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

  /// Guest login profile — create via [ensureUserDocument], then terms.
  Future<void> bootstrapGuestProfile({required String uid}) async {
    await ensureUserDocument(uid: uid);
    try {
      await acceptTerms(uid: uid, pushNotificationsEnabled: false);
    } catch (e) {
      debugPrint('bootstrapGuestProfile terms: $e');
    }
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

  /// Signup reward is minted by `POST /actions/onboarding/claim-signup`.
  Future<void> applySignupReward({
    required String uid,
    required int shareAmount,
    String? referralCode,
  }) async {
    await ensureUserDocument(uid: uid);
    final api = _securedActionApiClient;
    if (api == null) {
      debugPrint('applySignupReward skipped: secured API client missing');
      return;
    }
    await api.claimSignupReward();
    final code = referralCode?.trim();
    if (code != null && code.isNotEmpty) {
      try {
        await api.applyReferralCode(code);
      } catch (e) {
        debugPrint('applyReferralCode: $e');
      }
    }
  }

  Future<void> updateTrialRunCount({
    required String uid,
    required int trialRunCount,
  }) {
    debugPrint(
      'updateTrialRunCount skipped (server-owned economy): uid=$uid count=$trialRunCount',
    );
    return Future<void>.value();
  }

  /// Trial completion rewards and tier grants are minted by run validation.
  Future<void> completePreliminaryEvaluation({
    required String uid,
    required int tierRank,
    required String tierCode,
    required int averagePaceSeconds,
    required int trialShareReward,
  }) async {
    debugPrint(
      'completePreliminaryEvaluation skipped (server-owned economy): uid=$uid',
    );
  }

  /// Referral payouts are applied by the secured run-validation / referral APIs.
  Future<void> enqueueReferralUnlock({
    required String referredUid,
    required int rewardShare,
    required int maxPayouts,
  }) async {
    debugPrint(
      'enqueueReferralUnlock skipped (server-owned economy): referred=$referredUid',
    );
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

  /// Nickname only — DIA fee must be charged by a secured API, not the client.
  Future<void> updateNicknameWithDiaFee({
    required String uid,
    required String nickname,
    required int diaFee,
  }) async {
    await ensureUserDocument(uid: uid);
    await _firestoreService.doc(FirestorePaths.user(uid)).set({
      'nickname': nickname,
      'nicknameUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
        if (routeName != null) 'routeName': routeName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE NOTIFICATION] 시스템 알림 클라우드 업로드 성공');
    } catch (e) {
      debugPrint('[FIRESTORE NOTIFICATION] 시스템 알림 업로드 실패: $e');
    }
  }

  /// Jena 샌드배깅 탐지 패킷 — tier is server-owned.
  Future<void> forceSetTierFromJena({
    required String uid,
    required int tierRank,
    required String tierCode,
  }) {
    debugPrint(
      'forceSetTierFromJena skipped (server-owned economy): uid=$uid',
    );
    return Future<void>.value();
  }
}
