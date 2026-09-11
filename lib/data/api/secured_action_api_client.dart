import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_exception.dart';
import '../../features/jena_validation/models/jena_validation_request.dart';
import '../../features/jena_validation/models/jena_validation_result.dart';
import '../../features/run_tracking/models/route_point.dart';
import '../models/pedometer_harvest_result.dart';
import '../models/winner_reward_action.dart';

class SecuredActionApiClient {
  SecuredActionApiClient({
    required this.baseUri,
    required this.firebaseAuth,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUri;
  final FirebaseAuth firebaseAuth;
  final http.Client _httpClient;

  Future<void> joinTournament({
    required String tournamentId,
  }) async {
    await _post(
      '/actions/tournaments/join',
      {'tournament_id': tournamentId},
    );
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

  Future<void> claimSignupReward() async {
    await _post('/actions/onboarding/claim-signup', const {});
  }

  Future<void> applyReferralCode(String referralCode) async {
    await _post(
      '/actions/referrals/apply',
      {'referral_code': referralCode},
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await firebaseAuth.currentUser?.getIdToken();
    if (token == null) {
      throw StateError('Firebase ID token is required.');
    }

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
}
