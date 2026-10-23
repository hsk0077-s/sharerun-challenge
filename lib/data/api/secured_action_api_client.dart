import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_exception.dart';
import '../../features/crew/crew_emblem_status.dart';
import '../../features/crew/crew_ranking.dart';
import '../../features/crew/crew_membership.dart';
import '../../features/donation/funding_summary.dart';
import '../../features/donation/sponsorship_records.dart';
import '../../features/iap/dia_refund.dart';
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
    this.tokenTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 15),
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  /// 서버가 응답하지 않을 때 화면이 영원히 "진행 중"에 묶이지 않게 하는 상한.
  final Duration tokenTimeout;
  final Duration requestTimeout;

  final Uri baseUri;
  final FirebaseAuth firebaseAuth;
  http.Client _httpClient;
  final bool _ownsHttpClient;

  /// 오래 백그라운드에 있다 오면 keep-alive 연결이 죽어 있어 요청이 멈출 수 있다.
  /// 직접 만든 클라이언트만 새로 갈아 끼운다(테스트에서 주입한 것은 그대로 둔다).
  void _renewHttpClient() {
    if (!_ownsHttpClient) return;
    final old = _httpClient;
    _httpClient = http.Client();
    try {
      old.close();
    } catch (_) {}
  }
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
        if (entryMethod == 'ticket' || entryMethod == 'tier_ticket')
          'entry_method': entryMethod,
      },
    );
    return TournamentJoinResult.fromJson(json);
  }

  Future<CompanyTournamentConfig> fetchCompanyTournamentConfig() async {
    final json = await _get('/actions/company-tournament/config');
    return CompanyTournamentConfig.fromJson(json);
  }

  /// Records this install as a signed-in device (model, OS, app version only).
  Future<void> registerLoginDevice({
    required String deviceId,
    required String model,
    required String osVersion,
    required String appVersion,
    String fcmToken = '',
  }) async {
    await _post('/actions/security/devices/register', {
      if (fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      'device_id': deviceId,
      'model': model,
      'os_version': osVersion,
      'app_version': appVersion,
    });
  }

  Future<List<Map<String, dynamic>>> fetchLoginDevices(String deviceId) async {
    final json = await _get(
      '/actions/security/devices?device_id=${Uri.encodeQueryComponent(deviceId)}',
    );
    final rows = json['devices'];
    if (rows is! List) return const [];
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  /// Sends an appeal with one proof photo. The server checks the run, keeps
  /// the photo for 14 days and locks the run while it is under review.
  Future<void> submitAppeal({
    required String activityId,
    required String reasonCategory,
    required String reasonDetail,
    required List<int> proofBytes,
  }) async {
    await _post('/actions/appeals', {
      'activity_id': activityId,
      'reason_category': reasonCategory,
      'reason_detail': reasonDetail,
      'proof_base64': base64Encode(proofBytes),
    });
  }

  Future<String> fetchIntegrityNonce() async {
    final json = await _get('/actions/integrity/nonce');
    return json['nonce'] as String? ?? '';
  }

  /// Hands the server an integrity token. The server only records it.
  Future<void> reportIntegrity(String token) async {
    await _post('/actions/integrity/report', {'token': token});
  }

  /// Signs the account out on every device, this one included.
  Future<void> signOutEverywhere() async {
    await _post('/actions/security/sign-out-everywhere', const {});
  }

  /// Server value of the "use my data to improve AI" switch (default off).
  Future<bool> fetchAiLearning() async {
    final json = await _get('/actions/privacy/settings');
    return json['ai_learning'] == true;
  }

  /// Saves the switch on the server and returns the value it stored.
  Future<bool> setAiLearning(bool enabled) async {
    final json = await _post('/actions/privacy/ai-learning', {
      'enabled': enabled,
    });
    return json['ai_learning'] == true;
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
    // claimed_steps 는 절대값이라 같은 요청을 다시 보내도 중복 지급되지 않는다.
    Future<Map<String, dynamic>> send() => _post(
          '/actions/pedometer/harvest',
          {'claimed_steps': claimedSteps},
        );
    Map<String, dynamic> json;
    try {
      json = await send();
    } on TimeoutException {
      _renewHttpClient();
      json = await send();
    } on SocketException {
      _renewHttpClient();
      json = await send();
    } on http.ClientException {
      _renewHttpClient();
      json = await send();
    }
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

  /// The server checks [purchaseToken] with Google Play before it grants Coach+.
  Future<void> activateCoachPlus(String productId, String purchaseToken) async {
    await _post(
      '/actions/coach-plus/activate',
      {'product_id': productId, 'purchase_token': purchaseToken},
    );
  }

  /// Records when the user ticked "I am 14 or older" (server keeps the first).
  Future<void> confirmAgeOver14() async {
    await _post('/actions/onboarding/confirm-age14', const {});
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

  /// Buys one accessory or skin with DIA or SHARE. A retry charges once.
  Future<PedometerHarvestResult> purchaseAccessory(String itemId) async {
    final json = await _postWithRequest(
      '/actions/shop/purchase',
      {'item_id': itemId},
      'buy:$itemId',
    );
    return PedometerHarvestResult.fromJson(json);
  }

  /// Wears an owned accessory in [slot], or takes the slot off when [itemId] is empty.
  Future<void> equipAccessory({
    required String slot,
    required String itemId,
  }) async {
    await _post('/actions/shop/accessories/equip', {
      'slot': slot,
      'item_id': itemId,
    });
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
    final json =
        await _post('/actions/profile/nickname', {'nickname': nickname});
    return PedometerHarvestResult.fromJson(json);
  }

  /// Changes the emblem of the crew this account owns. Free. 404 without a crew.
  Future<PedometerHarvestResult> changeCrewEmblem(String emblem) async {
    final json = await _post('/actions/crew/emblem', {'emblem': emblem});
    return PedometerHarvestResult.fromJson(json);
  }

  /// 이번 달 크루 순위와 내 크루의 자리.
  Future<CrewRanking> crewRanking() async =>
      CrewRanking.fromJson(await _get('/actions/crew/ranking'));

  /// 이번 달 운영자 기부금과 지금 목표. 모두에게 같은 값이다.
  Future<FundingSummary> fundingSummary() async =>
      FundingSummary.fromJson(await _get('/actions/funding/summary'));

  /// 모두에게 보이는 후원 현황(참여 인원이 모자라면 금액은 비어 있다).
  Future<SponsorshipSummary> sponsorshipSummary() async =>
      SponsorshipSummary.fromJson(await _get('/actions/sponsorship/summary'));

  /// 내 후원 내역. 다른 사람의 것은 오지 않는다.
  Future<MySponsorship> mySponsorship() async =>
      MySponsorship.fromJson(await _get('/actions/sponsorship/mine'));

  /// 환불 기간 안에 산 DIA 팩과, 지금 환불하면 얼마인지.
  Future<DiaPurchases> diaPurchases() async {
    final json = await _get('/actions/wallet/dia-purchases');
    final list = json['purchases'];
    return DiaPurchases(
      refundDays: (json['refund_days'] as num?)?.toInt() ?? 7,
      purchases: [
        if (list is List)
          for (final p in list)
            if (p is Map<String, dynamic>) DiaPurchase.fromJson(p),
      ],
    );
  }

  /// 산 지 7일 안의 DIA 팩 하나를 환불한다. 쓰지 않은 유료 DIA만, 덤은 함께 빠진다.
  Future<DiaRefundResult> requestDiaRefund(String purchaseId) async {
    final json = await _post('/actions/wallet/dia-refund', {'purchase_id': purchaseId});
    return DiaRefundResult(
      status: json['status'] as String? ?? '',
      refundKrw: (json['refund_krw'] as num?)?.toInt() ?? 0,
      playRefunded: json['play_refunded'] == true,
    );
  }

  /// 크루 목록·검색. [query]가 비면 인원이 많은 크루부터.
  Future<CrewListResult> listCrews(String query) async {
    final path = query.trim().isEmpty
        ? '/actions/crew/list'
        : '/actions/crew/list?query=${Uri.encodeQueryComponent(query.trim())}';
    final json = await _get(path);
    final crews = json['crews'];
    return CrewListResult(
      crews: [
        if (crews is List)
          for (final c in crews)
            if (c is Map<String, dynamic>) CrewSummary.fromJson(c),
      ],
      pendingCrewId: json['pending_crew_id'] as String? ?? '',
    );
  }

  /// 내 크루와 내 역할, 크루원. 크루가 없으면 null.
  Future<MyCrew?> myCrew() async => MyCrew.fromJson(await _get('/actions/crew/mine'));

  /// 크루에 가입한다. 자유 가입이면 `joined`, 승인 크루면 `requested`.
  /// 이미 다른 크루에 있거나 가득 차면 409.
  Future<String> joinCrew(String crewId) async {
    final json = await _post('/actions/crew/join', {'crew_id': crewId});
    return json['status'] as String? ?? 'joined';
  }

  /// 크루장: 가입 방식을 `open`(자유) 또는 `approval`(승인)으로 바꾼다.
  Future<void> setCrewJoinMode(String mode) async {
    await _post('/actions/crew/join-mode', {'mode': mode});
  }

  /// 크루장: 인원 한도를 10명 늘린다(300 DIA). 새 한도와 DIA 잔액을 돌려준다.
  Future<({int maxMembers, int? diamondBalance})> expandCrew() async {
    final json = await _postWithRequest('/actions/crew/expand', const {}, 'crew-expand');
    return (
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 0,
      diamondBalance: (json['diamond_balance'] as num?)?.toInt(),
    );
  }

  /// 크루장: 크루 이름을 바꾼다. 처음 한 번은 무료, 그다음부터 300 DIA. 새 DIA 잔액을 돌려준다.
  Future<int?> renameCrew(String name) async {
    final json = await _postWithRequest(
      '/actions/crew/rename',
      {'name': name},
      'crew-rename:$name',
    );
    return (json['diamond_balance'] as num?)?.toInt();
  }

  /// 크루장·부크루장: 가입 신청 목록.
  Future<List<CrewJoinRequest>> crewJoinRequests() async {
    final json = await _get('/actions/crew/requests');
    final list = json['requests'];
    return [
      if (list is List)
        for (final r in list)
          if (r is Map<String, dynamic>)
            CrewJoinRequest(
              uid: r['uid'] as String? ?? '',
              nickname: r['nickname'] as String? ?? '러너',
            ),
    ];
  }

  /// 크루장·부크루장: 신청을 받아들이거나 거절한다.
  Future<void> decideCrewRequest(String uid, {required bool approve}) async {
    await _post('/actions/crew/requests/decide', {'uid': uid, 'approve': approve});
  }

  /// 내가 한 가입 신청을 거둔다.
  Future<void> cancelCrewRequest() async {
    await _post('/actions/crew/requests/cancel', const {});
  }

  /// 크루 이름이나 닉네임을 신고한다. 운영자가 확인한다. 같은 대상은 한 번만 접수된다.
  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    await _post('/actions/reports', {
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
    });
  }

  /// 크루장·부크루장: 크루원을 내보낸다(부크루장은 일반 크루원만).
  Future<void> kickCrewMember(String uid) async {
    await _post('/actions/crew/kick', {'uid': uid});
  }

  /// 크루장: 크루장 자리를 크루원에게 넘긴다. 나는 부크루장이 된다.
  Future<void> transferCrew(String uid) async {
    await _post('/actions/crew/transfer', {'uid': uid});
  }

  /// 크루장: 크루를 없앤다. 모든 크루원과 크루장 자신이 함께 크루에서 나온다.
  Future<void> disbandCrew() async {
    await _post('/actions/crew/disband', const {});
  }

  /// 크루에서 나간다. 크루장은 나갈 수 없다(400).
  Future<void> leaveCrew() async {
    await _post('/actions/crew/leave', const {});
  }

  /// 크루장만: 크루원을 부크루장(`sub`)으로 올리거나 일반(`member`)으로 돌린다.
  Future<void> setCrewRole(String uid, String role) async {
    await _post('/actions/crew/role', {'uid': uid, 'role': role});
  }

  /// 엠블럼 상태(해금한 테두리·진행도·산 유료 엠블럼). 크루가 없으면 404.
  Future<CrewEmblemStatus> crewEmblemStatus() async {
    final json = await _get('/actions/crew/emblem/status');
    return CrewEmblemStatus.fromJson(json);
  }

  /// 유료 일러스트 엠블럼을 DIA로 산다. 크루장만. 같은 요청은 한 번만 차감된다.
  Future<PedometerHarvestResult> purchaseCrewPaidEmblem(String emblemId) async {
    final retryKey = 'crew-emblem-$emblemId';
    final requestId = _requestIds.begin(retryKey);
    try {
      final json = await _post('/actions/crew/emblem/purchase', {
        'emblem_id': emblemId,
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

  /// Creates a crew. [payWith] is `dia` or `share`. The server debits the price.
  Future<PedometerHarvestResult> foundCrew(
    String name, {
    required String payWith,
    String? emblem,
  }) async {
    const retryKey = 'crew-create';
    final requestId = _requestIds.begin(retryKey);
    try {
      final json = await _post('/actions/crew/found', {
        'name': name,
        'pay_with': payWith,
        'request_id': requestId,
        if (emblem != null) 'emblem': emblem,
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

  /// 크루장: 크루원 한 명(또는 [targetUid]가 비면 나를 뺀 전체)에게 심폐소생권·세이프가드를
  /// 하나씩 준다. 한 명당 30 DIA. 받은 사람 수와 새 DIA 잔액을 돌려준다.
  Future<({int recipients, int? diamondBalance})> giftCrewItems({
    String targetUid = '',
  }) async {
    final json = await _postWithRequest(
      '/actions/crew/gift',
      {'target_uid': targetUid},
      'crew-gift:$targetUid',
    );
    return (
      recipients: (json['recipients'] as num?)?.toInt() ?? 0,
      diamondBalance: (json['diamond_balance'] as num?)?.toInt(),
    );
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
    ).timeout(requestTimeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _firebaseIdToken();
    final response = await _httpClient.get(
      baseUri.resolve(path),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(requestTimeout);
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
    final token = await user.getIdToken(true).timeout(tokenTimeout);
    if (token == null || token.isEmpty) {
      throw StateError('Firebase ID token is required.');
    }
    return token;
  }
}
