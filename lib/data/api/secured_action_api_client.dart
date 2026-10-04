import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_exception.dart';
import '../../features/jena_validation/models/jena_validation_request.dart';
import '../../features/jena_validation/models/jena_validation_result.dart';
import '../../features/run_tracking/models/route_point.dart';
import '../models/pedometer_harvest_result.dart';
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

class SecuredActionApiClient {
  SecuredActionApiClient({
    required this.baseUri,
    required this.firebaseAuth,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUri;
  final FirebaseAuth firebaseAuth;
  final http.Client _httpClient;

  Future<TournamentJoinResult> joinTournament({
    required String tournamentId,
  }) async {
    final json = await _post(
      '/actions/tournaments/join',
      {'tournament_id': tournamentId},
    );
    return TournamentJoinResult.fromJson(json);
  }

  Future<JenaValidationResult> validateRun({
    required JenaValidationRequest request,
    required List<RoutePoint> routePoints,
  }) async {
    final json = request.toJson()
      ..remove('user_id')
      ..['gps_route'] = routePoints.map((point) => point.toJson()).toList();

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

  /// Debits 500 VALUE on the server ledger. The device must not debit first.
  Future<PedometerHarvestResult> donateHallOfFame() async {
    final json = await _post('/actions/hall-of-fame/donate', const {});
    return PedometerHarvestResult.fromJson(json);
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

  /// Buys one catalog item. DIA debit and shopInventory live in one server transaction.
  Future<PedometerHarvestResult> purchaseShopItem(String itemId) async {
    final json = await _post('/actions/shop/purchase', {'item_id': itemId});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Decrements one account inventory doc. Rejects when quantity is already 0.
  Future<void> useShopItem(String itemId) async {
    await _post('/actions/shop/use', {'item_id': itemId});
  }

  /// Debits 100 DIA and stores the nickname in one server transaction.
  Future<PedometerHarvestResult> changeNickname(String nickname) async {
    final json = await _post('/actions/profile/nickname', {'nickname': nickname});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Creates a crew and debits the server founding cost.
  Future<PedometerHarvestResult> foundCrew(String name) async {
    final json = await _post('/actions/crew/found', {'name': name});
    return PedometerHarvestResult.fromJson(json);
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

  /// Once per account. Credits 500 SHARE (`trialCompletionRewardSrv`).
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
