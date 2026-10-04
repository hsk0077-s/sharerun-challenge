import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_exception.dart';
import '../../features/jena_validation/models/jena_validation_request.dart';
import '../../features/jena_validation/models/jena_validation_result.dart';
import '../../features/run_tracking/models/route_point.dart';
import '../../features/shop/cosmetics_catalog.dart';
import '../../features/shop/shop_request_ids.dart';
import '../models/company_tournament_config.dart';
import '../models/pedometer_harvest_result.dart';
import '../models/personal_sponsor_donation.dart';
import '../models/share_to_dia_view.dart';
import '../models/tournament_join_result.dart';
import '../models/winner_reward_action.dart';

class ChallengeRoomCreateResult {
  const ChallengeRoomCreateResult({
    required this.wallet,
    required this.tournamentId,
    required this.entryFeeShare,
  });

  final PedometerHarvestResult wallet;
  final String tournamentId;
  final int entryFeeShare;
}

class FriendGhostUseResult {
  const FriendGhostUseResult({required this.status, this.paceSecPerKm});

  final String status;
  final double? paceSecPerKm;

  factory FriendGhostUseResult.fromJson(Map<String, dynamic> json) {
    final raw = json['pace_sec_per_km'] ?? json['paceSecPerKm'];
    return FriendGhostUseResult(
      status: json['status'] as String? ?? '',
      paceSecPerKm: raw is num && raw > 0 ? raw.toDouble() : null,
    );
  }
}

class ShopCatalogPrice {
  const ShopCatalogPrice({
    required this.id,
    required this.diamondCost,
    this.shareCost = 0,
    this.valueCost = 0,
  });

  final String id;
  final int diamondCost;
  final int shareCost;
  final int valueCost;

  factory ShopCatalogPrice.fromJson(Map<String, dynamic> json) {
    final cost = json['diamond_cost'];
    final share = json['share_cost'];
    final value = json['value_cost'];
    return ShopCatalogPrice(
      id: json['id'] as String? ?? '',
      diamondCost: cost is num ? cost.toInt() : 0,
      shareCost: share is num ? share.toInt() : 0,
      valueCost: value is num ? value.toInt() : 0,
    );
  }
}

class SecuredActionApiClient {
  SecuredActionApiClient({
    required this.baseUri,
    required this.firebaseAuth,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUri;
  final FirebaseAuth firebaseAuth;
  final http.Client _httpClient;
  final ShopRequestIds _requestIds = ShopRequestIds();

  Future<TournamentJoinResult> joinTournament({
    required String tournamentId,
    bool useExtraEntry = false,
    String entryMethod = 'share',
  }) async {
    final json = await _post(
      '/actions/tournaments/join',
      {
        'tournament_id': tournamentId,
        if (useExtraEntry) 'use_extra_entry': true,
        if (entryMethod == 'ticket') 'entry_method': 'ticket',
      },
    );
    return TournamentJoinResult.fromJson(json);
  }

  Future<CompanyTournamentConfig> fetchCompanyTournamentConfig() async {
    final json = await _get('/actions/company-tournament/config');
    return CompanyTournamentConfig.fromJson(json);
  }

  /// Grants the one signup ticket when this account has never received it.
  Future<int> ensureSignupFreeTicket() async {
    final json = await _post('/actions/wallet/signup-ticket', const {});
    final balance = json['free_ticket_balance'];
    if (balance is num) return balance.toInt();
    return 0;
  }

  Future<JenaValidationResult> validateRun({
    required JenaValidationRequest request,
    required List<RoutePoint> routePoints,
    String? tournamentId,
  }) async {
    final json = request.toJson()
      ..remove('user_id')
      ..['gps_route'] = routePoints.map((point) => point.toJson()).toList();
    final raceId = tournamentId?.trim() ?? '';
    if (raceId.isNotEmpty) json['tournament_id'] = raceId;

    final response = await _post(
      '/actions/runs/validate',
      json,
    );
    return JenaValidationResult.fromJson(response);
  }

  Future<void> collectDiamondBox({
    required String boxId,
    required double latitude,
    required double longitude,
  }) async {
    await _post(
      '/actions/diamond-boxes/collect',
      {
        'box_id': boxId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<void> requestRefund({
    required int shareAmount,
  }) async {
    await _post(
      '/actions/wallet/refund',
      {'share_amount': shareAmount},
    );
  }

  Future<PedometerHarvestResult> harvestPedometerShare({
    required int claimedSteps,
  }) async {
    final json = await _post(
      '/actions/pedometer/harvest',
      {'claimed_steps': claimedSteps},
    );
    return PedometerHarvestResult.fromJson(json);
  }

  /// Debug one-shot QA grant. Release builds must not call this.
  Future<PedometerHarvestResult> grantDebugTestWallet1m({
    String grantSecret = '',
  }) async {
    final json = await _post(
      '/actions/debug/test-grant-1m',
      {
        if (kDebugMode) 'debug_client': true,
        if (grantSecret.isNotEmpty) 'grant_secret': grantSecret,
      },
    );
    return PedometerHarvestResult.fromJson(json);
  }

  Future<void> transferValueToWeb3({
    required String destinationAddress,
    required int amountSrv,
    required String transferChannel,
  }) async {
    await _post(
      '/actions/web3/transfer',
      {
        'destination_address': destinationAddress,
        'amount_srv': amountSrv,
        'transfer_channel': transferChannel,
      },
    );
  }

  Future<ShareToDiaView> quoteShareToDia() async {
    final json = await _post('/actions/wallet/share-to-dia/quote', const {});
    return ShareToDiaView.fromJson(json);
  }

  Future<ShareToDiaView> exchangeShareToDia(int diaAmount) async {
    final json = await _post('/actions/wallet/share-to-dia', {
      'dia_amount': diaAmount,
    });
    return ShareToDiaView.fromJson(json);
  }

  /// Debits 500 VALUE on the server ledger. The device must not debit first.
  Future<PedometerHarvestResult> donateHallOfFame() async {
    final json = await _post('/actions/hall-of-fame/donate', const {});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Debits the server personal-sponsor SHARE price once per [purpose] attempt.
  /// A dropped response retries the same request id and is not charged twice.
  Future<PersonalSponsorDonation> donatePersonalSponsor({
    required String purpose,
  }) async {
    final json = await _postWithRequest(
      '/actions/sponsorship/donate',
      {'purpose': purpose},
      'personal-sponsor:$purpose',
    );
    return PersonalSponsorDonation.fromJson(json);
  }

  Future<void> applyWinnerReward({
    required String activityId,
    required WinnerRewardAction action,
  }) async {
    await _post(
      '/actions/rewards/winner',
      {
        'activity_id': activityId,
        'action': action.transactionType,
      },
    );
  }

  Future<void> deleteAccount() async {
    await _post('/actions/account/delete', const {});
  }

  Future<void> activateCoachPlus(String productId) async {
    await _post(
      '/actions/coach-plus/activate',
      {'product_id': productId},
    );
  }

  Future<void> claimSignupReward() async {
    await _post('/actions/onboarding/claim-signup', const {});
  }

  Future<List<ShopCatalogPrice>> fetchShopCatalog() async {
    final json = await _post('/actions/shop/catalog', const {});
    final rows = json['items'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) ShopCatalogPrice.fromJson(row),
    ];
  }

  Future<CosmeticsCatalog> fetchCosmeticsCatalog() async {
    final json = await _post('/actions/shop/cosmetics', const {});
    return CosmeticsCatalog.fromJson(json);
  }

  /// Buys one cosmetic. The request id makes a retry charge DIA once.
  Future<PedometerHarvestResult> purchaseCosmetic(String itemId) async {
    final json = await _postWithRequest(
      '/actions/shop/purchase',
      {'item_id': itemId},
      'buy:$itemId',
    );
    return PedometerHarvestResult.fromJson(json);
  }

  /// Equips or clears one owned cosmetic. DIA is not charged.
  Future<String> equipCosmetic({
    required String itemId,
    required bool equip,
  }) async {
    final json = await _postWithRequest(
      '/actions/shop/cosmetics/equip',
      {'item_id': itemId, 'equip': equip},
      'equip:$itemId:$equip',
    );
    final status = json['status'];
    return status is String ? status : '';
  }

  /// Buys one catalog item. DIA debit and shopInventory live in one server transaction.
  ///
  /// Priced items send a stable request id. A retry of the same attempt reuses
  /// it so a lost response cannot charge DIA twice.
  Future<PedometerHarvestResult> purchaseShopItem(String itemId) async {
    final json = await _postStreakAware(
      '/actions/shop/purchase',
      itemId,
      'buy:$itemId',
    );
    return PedometerHarvestResult.fromJson(json);
  }

  /// Designates today or yesterday (KST) as a rest day. The server spends the
  /// weekly free use first, then one held ticket.
  Future<PedometerHarvestResult> useRestDay(String dayKey) async {
    final json = await _postWithRequest(
      '/actions/shop/use',
      {
        'item_id': 'rest_day_ticket',
        'rest_day': dayKey,
      },
      'use:rest_day_ticket:$dayKey',
    );
    return PedometerHarvestResult.fromJson(json);
  }

  /// Decrements one account inventory doc. Rejects when quantity is already 0.
  Future<void> useShopItem(String itemId) async {
    await _postStreakAware('/actions/shop/use', itemId, 'use:$itemId');
  }

  /// Spends one 코치 원포인트권 for this run. The same [requestId] is one charge.
  Future<String> useCoachOnePoint(String requestId) async {
    final json = await _post('/actions/shop/use', {
      'item_id': 'coach_one_point_ticket',
      'request_id': requestId,
    });
    final status = json['status'];
    return status is String ? status : '';
  }

  /// Once per KST day. Covers yesterday when a 세이프가드 is already held.
  Future<String> applyHeldSafeguard(String dayKey) async {
    final json = await _post('/actions/shop/use', {
      'item_id': 'record_safe_guard',
      'request_id': 'safeguard-auto-$dayKey',
    });
    final status = json['status'];
    return status is String ? status : '';
  }

  Future<Map<String, dynamic>> _postWithRequest(
    String path,
    Map<String, dynamic> fields,
    String retryKey,
  ) async {
    final requestId = _requestIds.begin(retryKey);
    try {
      final json = await _post(path, {...fields, 'request_id': requestId});
      _requestIds.succeed(retryKey);
      return json;
    } on ApiException catch (error) {
      _requestIds.failed(
        retryKey,
        requestId,
        retryable: error.statusCode >= 500,
      );
      rethrow;
    } catch (_) {
      _requestIds.failed(retryKey, requestId, retryable: true);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _postStreakAware(
    String path,
    String itemId,
    String retryKey,
  ) async {
    final streak = requestPricedShopItemIds.contains(itemId);
    final requestId = streak ? _requestIds.begin(retryKey) : null;
    final body = <String, dynamic>{
      'item_id': itemId,
      if (requestId != null) 'request_id': requestId,
    };
    try {
      final json = await _post(path, body);
      if (streak) _requestIds.succeed(retryKey);
      return json;
    } on ApiException catch (error) {
      if (streak) {
        _requestIds.failed(
          retryKey,
          requestId!,
          retryable: error.statusCode >= 500,
        );
      }
      rethrow;
    } catch (_) {
      if (streak) _requestIds.failed(retryKey, requestId!, retryable: true);
      rethrow;
    }
  }

  /// Debits 100 DIA and stores the nickname in one server transaction.
  Future<PedometerHarvestResult> changeNickname(String nickname) async {
    final json = await _post('/actions/profile/nickname', {'nickname': nickname});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Creates a crew. [payWith] is `dia` or `share`. The server debits the price.
  Future<PedometerHarvestResult> foundCrew(
    String name, {
    required String payWith,
  }) async {
    const retryKey = 'crew-create';
    final requestId = _requestIds.begin(retryKey);
    try {
      final json = await _post('/actions/crew/found', {
        'name': name,
        'pay_with': payWith,
        'request_id': requestId,
      });
      _requestIds.succeed(retryKey);
      return PedometerHarvestResult.fromJson(json);
    } on ApiException catch (error) {
      _requestIds.failed(
        retryKey,
        requestId,
        retryable: error.statusCode >= 500,
      );
      rethrow;
    } catch (_) {
      _requestIds.failed(retryKey, requestId, retryable: true);
      rethrow;
    }
  }

  /// Spends one 친구 고스트 페이스 for [friendUid]'s verified run.
  Future<FriendGhostUseResult> useFriendGhost({
    required String friendUid,
    required String activityId,
  }) async {
    const retryKey = 'use:friend_ghost_pace';
    final requestId = _requestIds.begin(retryKey);
    try {
      final json = await _post('/actions/shop/use', {
        'item_id': 'friend_ghost_pace',
        'request_id': requestId,
        'friend_uid': friendUid,
        'activity_id': activityId,
      });
      _requestIds.succeed(retryKey);
      return FriendGhostUseResult.fromJson(json);
    } on ApiException catch (error) {
      _requestIds.failed(
        retryKey,
        requestId,
        retryable: error.statusCode >= 500,
      );
      rethrow;
    } catch (_) {
      _requestIds.failed(retryKey, requestId, retryable: true);
      rethrow;
    }
  }

  /// Creates a challenge room and debits the server entry fee for that distance.
  Future<ChallengeRoomCreateResult> createChallengeRoom({
    required String title,
    required int distanceKm,
  }) async {
    final json = await _post('/actions/tournaments/create-room', {
      'title': title,
      'distance_km': distanceKm,
    });
    final id = json['tournament_id'];
    final fee = json['entry_fee_share'];
    if (id is! String || id.isEmpty || fee is! num) {
      throw StateError('Challenge room missing from server response.');
    }
    return ChallengeRoomCreateResult(
      wallet: PedometerHarvestResult.fromJson(json),
      tournamentId: id,
      entryFeeShare: fee.toInt(),
    );
  }

  /// Debits a server-owned crew price. The client does not send the amount.
  Future<PedometerHarvestResult> spendCrewAction(String action) async {
    final json = await _post('/actions/crew/spend', {'action': action});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Debits the server crew-gift price and grants CPR plus Safeguard.
  Future<PedometerHarvestResult> grantCrewItems() async {
    final json = await _post('/actions/shop/crew-gift', const {});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Once per KST week. Credits [EconomyConstants.streakBonusDia] on the server.
  Future<PedometerHarvestResult> claimStreakBonus() async {
    final json = await _post('/actions/rewards/streak', const {});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Once per account. Credits 5,000 SHARE (`trialCompletionRewardSrv`).
  Future<PedometerHarvestResult> claimTrialReward() async {
    final json = await _post('/actions/onboarding/claim-trial', const {});
    return PedometerHarvestResult.fromJson(json);
  }

  Future<void> applyReferralCode(String referralCode) async {
    await _post(
      '/actions/referrals/apply',
      {'referral_code': referralCode},
    );
  }

  /// Records who invited this user. Does not credit a reward.
  Future<void> redeemReferralCode(String code) async {
    await _post(
      '/actions/referrals/redeem',
      {'code': code},
    );
  }

  /// Server-issued invite code. Same code on every call; no UI yet.
  Future<String> getOrCreateInviteCode() async {
    final json = await _post('/actions/referrals/code', const {});
    final code = json['referral_code'];
    if (code is! String || code.isEmpty) {
      throw StateError('Invite code missing from server response.');
    }
    return code;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await _firebaseIdToken();

    final response = await _httpClient.post(
      baseUri.resolve(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _firebaseIdToken();
    final response = await _httpClient.get(
      baseUri.resolve(path),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    if (response.body.isEmpty) {
      return const {};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fresh Firebase ID token. Cached/emulator leftovers are what Cloud Run
  /// rejects as `Invalid Firebase ID token`.
  Future<String> _firebaseIdToken() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Firebase ID token is required.');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Firebase ID token is required.');
    }
    return token;
  }
}
