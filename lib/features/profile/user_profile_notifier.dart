import 'dart:async' show StreamSubscription;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers/app_providers.dart';
import '../../core/config/app_env.dart';
import '../../core/strings/app_strings.dart';
import '../../data/models/personal_sponsor_donation.dart';
import '../../data/models/user_model.dart';
import '../onboarding/src_onboarding_controller.dart';
import '../wallet/debug_local_wallet_store.dart';
import '../wallet/providers/debug_local_share_history_provider.dart';
import '../wallet/providers/wallet_provider.dart';

/// 유저 프로필 반응형 상태 + 성별 Firestore/로컬 동기화.
class UserProfileNotifier extends Notifier<UserProfile> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  int _profileListenGeneration = 0;
  String? _profileListenUid;
  int _profilePermissionRetries = 0;

  @override
  UserProfile build() {
    ref.onDispose(_stopFirestoreProfile);
    ref.listen<AsyncValue<UserModel>>(activeUserProfileProvider, (_, next) {
      next.whenData(_applyCloudProfile);
    });
    ref.listen(authStateChangesProvider, (_, __) {
      _syncProfileSubscription();
    });
    // Cold start: auth may still be loading. Do not read `state` here.
    _syncProfileSubscription();
    final initial = ref.read(activeUserProfileProvider).asData?.value ??
        UserModel.dashboardDefault(uid: '');
    return initial;
  }

  /// Resolves uid from auth providers only. Do not read [state] here:
  /// [build] calls this before the notifier is initialized, and Riverpod
  /// would throw `Tried to read the state of an uninitialized provider`.
  String? _currentUid() {
    final auth = ref.read(authStateChangesProvider).asData?.value;
    if (auth != null && auth.uid.isNotEmpty) return auth.uid;
    final persisted = ref.read(persistedAuthSessionProvider)?.uid;
    if (persisted != null && persisted.isNotEmpty) return persisted;
    return null;
  }

  /// 로그인된 uid의 Firestore 문서를 구독한다.
  ///
  /// 로그아웃으로 auth가 null이 되면 이전 폰 세션 uid로 다시 구독하지 않는다.
  /// 그 구독이 남으면 `permission-denied`가 반복된다. 계정이 바뀌면 이전
  /// 구독을 끊고 새 uid로만 다시 연다.
  void _syncProfileSubscription() {
    final auth = ref.read(authStateChangesProvider);
    final target = profileSubscriptionTarget(
      authResolved: auth.hasValue || auth.hasError,
      authUid: auth.asData?.value?.uid,
      persistedUid: ref.read(persistedAuthSessionProvider)?.uid,
    );
    if (target == null) {
      _stopFirestoreProfile();
      return;
    }
    if (target == _profileListenUid && _profileSubscription != null) return;
    _startFirestoreProfile(target);
  }

  void _stopFirestoreProfile() {
    _profileListenGeneration++;
    _profileListenUid = null;
    _profilePermissionRetries = 0;
    final previous = _profileSubscription;
    _profileSubscription = null;
    previous?.cancel();
  }

  void _startFirestoreProfile(String uid) {
    if (AppEnv.useLocalMockData) {
      _stopFirestoreProfile();
      return;
    }
    if (_profileListenUid != uid) _profilePermissionRetries = 0;
    final generation = ++_profileListenGeneration;
    _profileListenUid = uid;
    final previous = _profileSubscription;
    _profileSubscription = null;
    previous?.cancel();
    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (generation != _profileListenGeneration) return;
        if (!snapshot.exists) return;
        final raw = snapshot.data();
        if (raw == null) return;
        final data = Map<String, dynamic>.from(raw);
        data['uid'] = uid;
        _applyCloudProfile(UserModel.fromJson(data));
      },
      onError: (Object error) {
        if (generation != _profileListenGeneration) return;
        final live = _liveAuthUid();
        if (!shouldReportProfileSubscriptionError(
          subscribedUid: uid,
          liveAuthUid: live,
        )) {
          return;
        }
        // 로그인 직후 토큰이 Firestore에 닿기 전에 한 번 거부될 수 있다.
        if (isFirestorePermissionDenied(error) &&
            _profilePermissionRetries < 1) {
          _profilePermissionRetries++;
          Future<void>.delayed(const Duration(milliseconds: 350), () {
            if (generation != _profileListenGeneration) return;
            if (_liveAuthUid() != uid) return;
            _startFirestoreProfile(uid);
          });
          return;
        }
        debugPrint('Firestore 프로필 구독 실패: $error');
      },
    );
  }

  /// Auth 스트림보다 Firebase 현재 사용자가 먼저 바뀐다. 로그아웃이면 null이다.
  /// null을 이전 세션 uid로 바꾸면, 끊어야 할 구독의 거부를 다시 찍게 된다.
  String? _liveAuthUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return ref.read(authStateChangesProvider).asData?.value?.uid;
    }
  }

  void _applyCloudProfile(UserModel profile) {
    try {
      state = retainOptimisticDonationTotals(
        local: state,
        remote: profile,
      );
    } catch (_) {
      // `build()` may deliver the first cloud snapshot before `state` exists.
      state = retainOptimisticDonationTotals(
        local: profile,
        remote: profile,
      );
    }
    ref.read(walletProvider.notifier).replaceFromRemote(profile.wallet);
  }

  /// Donation totals on screen are the server profile. Phone totals do not win.
  static UserModel retainOptimisticDonationTotals({
    required UserModel local,
    required UserModel remote,
    int? durableDonationCount,
    int? durableDonationAmount,
    bool durableSponsored = false,
  }) {
    return remote;
  }

  /// Same uid resolution as shop receipts: auth, persisted session, then profile.
  String? _receiptUid() {
    final authUid = _currentUid();
    if (authUid != null && authUid.isNotEmpty) return authUid;
    final profileUid = state.uid;
    if (profileUid.isNotEmpty) return profileUid;
    return null;
  }

  /// 소비/구매 클라우드 영수증. `users/{uid}/wallet_transactions`.
  /// VALUE donations also land in the local history ledger so History still
  /// lists them when Firestore create is denied (USB / legacy rules).
  Future<void> writeTransactionReceipt({
    required String title,
    required int amount,
    required String assetType,
  }) async {
    final uid = _receiptUid();
    if (uid == null || uid.isEmpty) return;
    if (assetType == 'VALUE') {
      try {
        final prefs = await SharedPreferences.getInstance();
        await DebugLocalWalletStore.recordClientHistory(
          prefs: prefs,
          uid: uid,
          title: title,
          amount: amount,
          assetType: assetType,
        );
        ref.read(debugLocalShareHistoryProvider.notifier).replace(
              DebugLocalWalletStore.cachedHistory(uid),
            );
      } catch (e) {
        debugPrint('writeTransactionReceipt local VALUE history: $e');
      }
    }
    await ref.read(walletRepositoryProvider).logClientWalletTransaction(
          uid: uid,
          title: title,
          amount: amount,
          assetType: assetType,
        );
  }

  /// 성별을 즉시 반영하고 Firestore에 merge 기록한다.
  Future<void> updateGender(String newGender) async {
    final normalized = UserModel.normalizeGender(newGender);
    state = state.copyWith(gender: normalized);
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
    try {
      await ref.read(userRepositoryProvider).updateGender(
            uid: uid,
            gender: normalized,
          );
    } catch (_) {
      // 로컬 mock / 오프라인 — 낙관적 상태는 유지한다.
    }
  }

  Future<void> toggleGender() {
    return updateGender(state.gender == 'female' ? 'male' : 'female');
  }

  /// SHARE 개인 후원. 금액과 천사 실적은 서버가 정하고, 화면은 그 응답만 쓴다.
  /// [amount]는 호출부 양수 가드이며 차감액이 아니다.
  /// 상점 VALUE 기부는 [assetType]을 `VALUE`로 넘긴다.
  Future<PersonalSponsorDonation?> processDonation(
    int amount, {
    String assetType = 'SHARE',
    String? receiptTitle,
    String purpose = 'donation',
  }) async {
    if (amount <= 0) return null;
    if (assetType == 'SHARE') {
      return _confirmPersonalSponsor(purpose: purpose);
    }
    final won = amount * AngelEconomy.shareToWon;
    final nextCount = state.donationCount + 1;
    final nextAmount = state.cumulativeDonationAmount + won;
    state = state.copyWith(
      donationCount: nextCount,
      cumulativeDonationAmount: nextAmount,
      isSponsored: true,
    );
    final uid = _receiptUid();
    if (uid != null && uid.isNotEmpty) {
      try {
        await ref.read(userRepositoryProvider).mergeEconomyState(
              uid: uid,
              valueDelta: assetType == 'VALUE' ? -amount : null,
              isSponsored: true,
            );
      } catch (e) {
        debugPrint('processDonation mergeEconomyState: $e');
      }
      if (kDebugMode && assetType == 'VALUE') {
        try {
          final wallet = ref.read(walletProvider);
          await ref.read(walletRepositoryProvider).persistDebugShopSpend(
                uid: uid,
                shareBalance: wallet.shareBalance,
                diamondBalance: wallet.diamondBalance,
                valueBalance: wallet.valueBalance,
              );
        } catch (e) {
          debugPrint('processDonation persistDebugShopSpend: $e');
        }
      }
    }
    await writeTransactionReceipt(
      title: receiptTitle ?? AppStrings.storeDonateHistoryTitle,
      amount: -amount,
      assetType: assetType,
    );
    return null;
  }

  /// Applies a server-confirmed sponsor donation onto the profile on screen.
  static UserModel confirmedSponsorshipProfile({
    required UserModel local,
    required PersonalSponsorDonation confirmed,
  }) {
    return local.copyWith(
      donationCount: confirmed.donationCount,
      cumulativeDonationAmount: confirmed.cumulativeDonationAmount,
      isSponsored: confirmed.isSponsored,
    );
  }

  Future<PersonalSponsorDonation> _confirmPersonalSponsor({
    required String purpose,
  }) async {
    final uid = _receiptUid();
    if (uid == null || uid.isEmpty) {
      throw StateError('Personal sponsor requires a signed-in user.');
    }
    final confirmed = await ref.read(userRepositoryProvider).recordDonation(
          uid: uid,
          purpose: purpose,
        );
    state = confirmedSponsorshipProfile(local: state, confirmed: confirmed);
    ref.read(walletProvider.notifier).applyWalletSnapshot(
          shareBalance: confirmed.shareBalance,
          diamondBalance: confirmed.diamondBalance,
          valueBalance: confirmed.valueTokenBalance,
        );
    return confirmed;
  }

  /// 상점 글로벌 펀딩 — VALUE 차감 후 클라우드 영수증 발행.
  Future<void> donateValue(int amount) {
    return processDonation(amount, assetType: 'VALUE');
  }

  /// 상점 아이템 구매 — DIA 차감 + CPR 플래그 클라우드 반영.
  Future<void> persistShopPurchase({
    required int diamondFee,
    required bool markCpr,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
    if (markCpr) {
      state = state.copyWith(hasCPR: true);
    }
    try {
      await ref.read(userRepositoryProvider).mergeEconomyState(
            uid: uid,
            diamondDelta: diamondFee == 0 ? null : -diamondFee.abs(),
            hasCPR: markCpr ? true : null,
          );
    } catch (e) {
      debugPrint('persistShopPurchase: $e');
    }
    if (kDebugMode) {
      try {
        final wallet = ref.read(walletProvider);
        await ref.read(walletRepositoryProvider).persistDebugShopSpend(
              uid: uid,
              shareBalance: wallet.shareBalance,
              diamondBalance: wallet.diamondBalance,
              valueBalance: wallet.valueBalance,
              hasCPR: markCpr ? true : null,
            );
      } catch (e) {
        debugPrint('persistShopPurchase Firestore: $e');
      }
    }
  }

  /// 만보기 동전 UI. SHARE 원장은 서버 전용이라 클라이언트에서 가산하지 않는다.
  Future<void> creditShare(int amount) async {
    if (amount <= 0) return;
    debugPrint('creditShare skipped (server-owned wallet): amount=$amount');
  }
}

final userProfileNotifierProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);

final userGenderProvider = Provider<String>((ref) {
  return UserModel.normalizeGender(
    ref.watch(userProfileNotifierProvider).gender,
  );
});

/// 스펙 alias — [userProfileNotifierProvider]와 동일.
final userProfileProvider = userProfileNotifierProvider;

final userAngelTierProvider = Provider<AngelTier>((ref) {
  return ref.watch(userProfileProvider).angelTier;
});

/// Which `users/{uid}` document the profile listener should follow.
///
/// A resolved signed-out auth state must not fall back to the persisted uid.
/// That fallback resubscribes to the previous account after logout and
/// Firestore answers permission-denied.
String? profileSubscriptionTarget({
  required bool authResolved,
  required String? authUid,
  String? persistedUid,
}) {
  final live = authUid?.trim() ?? '';
  if (live.isNotEmpty) return live;
  if (authResolved) return null;
  final persisted = persistedUid?.trim() ?? '';
  if (persisted.isNotEmpty) return persisted;
  return null;
}

/// permission-denied on the listener we are dropping (logout or account
/// switch) is expected. Only a denial for the account still signed in is logged.
bool shouldReportProfileSubscriptionError({
  required String subscribedUid,
  required String? liveAuthUid,
}) {
  final subscribed = subscribedUid.trim();
  final live = liveAuthUid?.trim() ?? '';
  return subscribed.isNotEmpty && live.isNotEmpty && live == subscribed;
}

bool isFirestorePermissionDenied(Object error) {
  return error.toString().contains('permission-denied');
}
