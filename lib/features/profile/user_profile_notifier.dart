import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/config/app_env.dart';
import '../../data/models/user_model.dart';
import '../onboarding/src_onboarding_controller.dart';
import '../shop/providers/shop_tab_provider.dart';
import '../wallet/providers/wallet_provider.dart';

/// 유저 프로필 반응형 상태 + 성별 Firestore/로컬 동기화.
class UserProfileNotifier extends Notifier<UserProfile> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;

  @override
  UserProfile build() {
    ref.onDispose(() {
      _profileSubscription?.cancel();
    });
    ref.listen<AsyncValue<UserModel>>(activeUserProfileProvider, (_, next) {
      next.whenData(_applyCloudProfile);
    });
    ref.listen(authStateChangesProvider, (_, next) {
      listenToFirestoreProfile(uid: next.asData?.value?.uid);
    });
    final initial = ref.read(activeUserProfileProvider).asData?.value ??
        UserModel.dashboardDefault(uid: '');
    // Pass uid from auth/session providers — never from `state`, which is
    // uninitialized until this `build()` returns (cold-start ErrorWidget).
    listenToFirestoreProfile(uid: _currentUid() ?? initial.uid);
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

  /// 로그인 직후 Firestore 유저 문서를 실시간 구독해 자산·아이템을 복원한다.
  void listenToFirestoreProfile({String? uid}) {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    final resolved =
        (uid != null && uid.isNotEmpty) ? uid : (_currentUid() ?? '');
    if (resolved.isEmpty || AppEnv.useLocalMockData) return;
    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(resolved)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) return;
        final raw = snapshot.data();
        if (raw == null) return;
        final data = Map<String, dynamic>.from(raw);
        data['uid'] = resolved;
        _applyCloudProfile(UserModel.fromJson(data));
      },
      onError: (Object e) {
        debugPrint('Firestore 프로필 구독 실패: $e');
      },
    );
  }

  void _applyCloudProfile(UserModel profile) {
    state = profile;
    ref.read(walletProvider.notifier).replaceFromRemote(profile.wallet);
    if (profile.hasCPR) {
      ref.read(shopTabProvider.notifier).restoreCprOwned();
    }
  }

  /// 소비/구매 클라우드 영수증. `users/{uid}/wallet_transactions`.
  Future<void> writeTransactionReceipt({
    required String title,
    required int amount,
    required String assetType,
  }) async {
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
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

  /// 후원 성공 정산. [amount]는 SHARE 단위이며 100 SHARE = 100원.
  /// 상점 VALUE 기부는 [assetType]을 `VALUE`로 넘긴다.
  Future<void> processDonation(
    int amount, {
    String assetType = 'SHARE',
  }) async {
    if (amount <= 0) return;
    final won = amount * AngelEconomy.shareToWon;
    final nextCount = state.donationCount + 1;
    final nextAmount = state.cumulativeDonationAmount + won;
    final nextTier = AngelTierX.resolve(
      donationCount: nextCount,
      cumulativeDonationAmount: nextAmount,
    );
    state = state.copyWith(
      donationCount: nextCount,
      cumulativeDonationAmount: nextAmount,
      isSponsored: true,
    );
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) return;
    try {
      await ref.read(userRepositoryProvider).recordDonation(
            uid: uid,
            amountWon: won,
            angelTierCode: nextTier.code,
          );
    } catch (_) {
      // 로컬 mock / 오프라인 — 낙관적 승급은 유지한다.
    }
    try {
      await ref.read(userRepositoryProvider).mergeEconomyState(
            uid: uid,
            shareDelta: assetType == 'SHARE' ? -amount : null,
            valueDelta: assetType == 'VALUE' ? -amount : null,
            isSponsored: true,
          );
    } catch (e) {
      debugPrint('processDonation mergeEconomyState: $e');
    }
    if (kDebugMode && assetType == 'SHARE') {
      try {
        await ref.read(walletRepositoryProvider).persistDebugShareSpend(
              uid: uid,
              shareDelta: -amount,
              donationCount: nextCount,
              cumulativeDonationAmount: nextAmount,
              isSponsored: true,
            );
      } catch (e) {
        debugPrint('processDonation persistDebugShareSpend: $e');
      }
    }
    await writeTransactionReceipt(
      title: assetType == 'VALUE' ? '유니세프 글로벌 기부 펀딩 참여 🕊️' : '유니세프 기부 완료 🕊️',
      amount: -amount,
      assetType: assetType,
    );
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
      ref.read(shopTabProvider.notifier).restoreCprOwned();
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
