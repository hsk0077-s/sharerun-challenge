import 'dart:convert';

import '../../l10n/remaining_surface.dart';
import '../strings/app_strings.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.detail,
  });

  final int statusCode;
  final String detail;

  String get userMessage => ApiErrorMessage.forDetail(detail);

  static ApiException fromHttpResponse({
    required int statusCode,
    required String body,
  }) {
    return ApiException(
      statusCode: statusCode,
      detail: _parseDetail(body),
    );
  }

  static String _parseDetail(String body) {
    if (body.isEmpty) {
      return 'Request failed.';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return body;
      }

      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return first['msg'] as String;
        }
        return first.toString();
      }
    } catch (_) {
      return body;
    }

    return body;
  }

  @override
  String toString() => userMessage;
}

abstract final class ApiErrorMessage {
  static String get _genericFailure => RemainingSurface.trNow('api_exception.body', '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.');

  static String from(Object error) {
    if (error is ApiException) {
      return error.userMessage;
    }
    return error.toString();
  }

  static String forDetail(String detail) {
    return switch (detail) {
      'Tournament is full.' => RemainingSurface.trNow('api_exception.body.2', '대회 정원이 가득 찼습니다.'),
      'Tournament is not recruiting.' => RemainingSurface.trNow('api_exception.body.3', '현재 모집 중인 대회가 아닙니다.'),
      'Prize races accept only SHARE or free tickets.' =>
        RemainingSurface.trNow('api_exception.body.4', '상금 대회는 SHARE 또는 무료 참가권만 사용할 수 있습니다.'),
      'Extra entry daily use cap is 2.' => RemainingSurface.trNow('api_exception.body.5', '추가 참가권은 하루에 2번까지 사용할 수 있습니다.'),
      'No extra entry ticket.' => RemainingSurface.trNow('api_exception.body.6', '사용할 추가 참가권이 없습니다.'),
      'Coach one-point daily use cap is 1.' => RemainingSurface.trNow('api_exception.body.7', '코치 원포인트권은 하루에 1번까지 사용할 수 있습니다.'),
      'Lower-tier room is locked.' => RemainingSurface.trNow('api_exception.body.8', '내 등급보다 낮은 대회는 참가할 수 없습니다.'),
      'Insufficient Share balance.' => 'SHARE가 부족합니다.',
      'Insufficient free tickets.' => RemainingSurface.trNow('api_exception.body.9', '무료 참가권이 부족합니다.'),
      'No valid entry ticket for this tier.' => RemainingSurface.trNow('api_exception.body.10', '이 등급에 쓸 수 있는 참가권이 없어요.'),
      'This entry ticket is not valid for this edition.' =>
        RemainingSurface.trNow('api_exception.body.11', '이 참가권은 이번 회차에는 쓸 수 없어요.'),
      'This race has no edition, so an entry ticket cannot be used.' =>
        RemainingSurface.trNow('api_exception.body.12', '회차가 없는 대회에는 참가권을 쓸 수 없어요.'),
      'Ticket seats for this race are full. You can still join with SHARE.' =>
        RemainingSurface.trNow('api_exception.body.13', '참가권 자리가 다 찼습니다. SHARE로는 참가할 수 있어요.'),
      'This tier does not accept free tickets.' => RemainingSurface.trNow('api_exception.body.14', '이 대회는 무료 참가권을 사용할 수 없습니다.'),
      'Season qualification is required.' => RemainingSurface.trNow('api_exception.body.15', '시즌 진출 자격이 있어야 참가할 수 있습니다.'),
      'Boost run already used today.' => RemainingSurface.trNow('api_exception.body.16', '부스트 런은 하루에 1번까지 사용할 수 있습니다.'),
      'An incubator is already active.' => RemainingSurface.trNow('api_exception.body.17', '만보기 부화기는 한 번에 하나만 동작합니다.'),
      'Insufficient Diamond balance.' => 'DIA가 부족합니다. 상점에서 구매해 주세요.',
      'Insufficient paid Diamond balance.' =>
        RemainingSurface.trNow('api_exception.body.18', '유료 DIA가 부족합니다. 무료 DIA로는 배틀런 패스를 살 수 없습니다.'),
      'Battle pass already owned for this season.' =>
        RemainingSurface.trNow('api_exception.body.19', '이번 시즌 배틀런 패스는 이미 구매했습니다.'),
      'Battle pass is not spent.' => RemainingSurface.trNow('api_exception.body.20', '배틀런 패스는 사용해서 사라지지 않습니다.'),
      'Pass upgrade price is invalid.' => RemainingSurface.trNow('api_exception.body.21', '패스+ 가격이 패스보다 낮아 업그레이드할 수 없습니다.'),
      'No crew.' => RemainingSurface.trNow('api_exception.body.22', '소속 크루가 없습니다.'),
      'No item to use.' => RemainingSurface.trNow('api_exception.body.23', '사용할 아이템이 없습니다.'),
      'Crew not found.' => RemainingSurface.trNow('api_exception.body.24', '크루를 찾지 못했습니다.'),
      'Cheer flag is already up for this crew today.' =>
        RemainingSurface.trNow('api_exception.body.25', '이 크루의 응원 깃발은 오늘 이미 걸려 있습니다.'),
      'Friend recorded run is required.' => RemainingSurface.trNow('api_exception.body.26', '친구의 검증된 기록을 선택해 주세요.'),
      'Refund exceeds Share balance.' => RemainingSurface.trNow('api_exception.body.27', '환불 가능한 SHARE 잔액을 초과했습니다.'),
      'Move closer to collect.' => RemainingSurface.trNow('api_exception.body.28', '다이아 상자에 더 가까이 이동해 주세요.'),
      'Diamond box already collected.' => RemainingSurface.trNow('api_exception.body.29', '이미 수집한 다이아 상자입니다.'),
      'Verified own activity required.' => RemainingSurface.trNow('api_exception.body.30', '본인의 검증 완료 러닝만 처리할 수 있습니다.'),
      'Reward already processed.' => RemainingSurface.trNow('api_exception.body.31', '이미 처리된 우승 보상입니다.'),
      'No reward available.' => RemainingSurface.trNow('api_exception.body.32', '수령 가능한 보상이 없습니다.'),
      'Insufficient Value to donate.' => RemainingSurface.trNow('api_exception.body.33', '기부할 VALUE가 부족합니다.'),
      'Insufficient Value balance.' => 'VALUE가 부족합니다.',
      'That day already counts.' => RemainingSurface.trNow('api_exception.body.34', '이미 기록이 있는 날은 휴식일로 지정할 수 없습니다.'),
      'That day is already a rest day.' => RemainingSurface.trNow('api_exception.body.35', '그 날은 이미 휴식일입니다.'),
      'Rest day must be today or yesterday.' => RemainingSurface.trNow('api_exception.body.36', '휴식일은 오늘 또는 어제로만 지정할 수 있습니다.'),
      'Donation match monthly cap reached.' => RemainingSurface.trNow('api_exception.body.37', '이번 달 기부 매칭 횟수를 모두 사용했습니다.'),
      'Donation match company cap reached.' =>
        RemainingSurface.trNow('api_exception.body.38', '이번 달 운영자 기부 한도에 도달했습니다. VALUE는 차감되지 않았습니다.'),
      'Activity belongs to another user.' => RemainingSurface.trNow('api_exception.body.39', '다른 사용자의 활동입니다.'),
      'User or tournament not found.' => RemainingSurface.trNow('api_exception.body.40', '사용자 또는 대회 정보를 찾을 수 없습니다.'),
      'User or activity not found.' => RemainingSurface.trNow('api_exception.body.41', '사용자 또는 활동 정보를 찾을 수 없습니다.'),
      'Email verification is required.' => RemainingSurface.trNow('api_exception.body.42', '이메일 인증을 완료해 주세요.'),
      'Invalid Firebase ID token.' => RemainingSurface.trNow('api_exception.body.43', '로그인 인증이 만료되었습니다. 다시 로그인해 주세요.'),
      'invalid' => AppStrings.referralRedeemInvalid,
      'self' => AppStrings.referralRedeemSelf,
      'already' => AppStrings.referralRedeemAlready,
      'expired' => AppStrings.referralRedeemExpired,
      'identity_belongs_to_another_account' =>
        RemainingSurface.trNow('api_exception.body.44', '이 계정은 이미 다른 쉐어런 계정에 연결돼 있어요.'),
      'empty_account' => AppStrings.existingAccountEmpty,
      'provider_already_linked' => RemainingSurface.trNow('api_exception.body.45', '이미 같은 종류의 계정이 연결돼 있어요.'),
      'last_login_method' => RemainingSurface.trNow('api_exception.body.46', '마지막 로그인 방법은 해제할 수 없어요.'),
      'not_linked' => RemainingSurface.trNow('api_exception.body.47', '연결된 계정이 아니에요.'),
      'invalid_provider_token' => RemainingSurface.trNow('api_exception.body.48', '로그인 확인에 실패했어요. 다시 시도해 주세요.'),
      'provider_token_for_other_app' => RemainingSurface.trNow('api_exception.body.48', '로그인 확인에 실패했어요. 다시 시도해 주세요.'),
      'provider_unreachable' => RemainingSurface.trNow('api_exception.body.49', '로그인 서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.'),
      'kakao_not_configured' => RemainingSurface.trNow('api_exception.body.50', '카카오 로그인이 아직 준비되지 않았어요.'),
      'google_not_configured' => RemainingSurface.trNow('api_exception.body.51', '구글 로그인이 아직 준비되지 않았어요.'),
      'email_lookup_unavailable' => RemainingSurface.trNow('api_exception.body.52', '계정을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.'),
      'try_again' => RemainingSurface.trNow('api_exception.body.53', '잠시 후 다시 시도해 주세요.'),
      'custom_token_unavailable' => RemainingSurface.trNow('api_exception.body.53', '잠시 후 다시 시도해 주세요.'),
      'too_many_attempts' => RemainingSurface.trNow('api_exception.body.54', '시도가 너무 많아요. 잠시 후 다시 시도해 주세요.'),
      'A challenge ticket can be used once a week.' =>
        RemainingSurface.trNow('api_exception.body.55', '챌린지 참가권은 일주일에 한 번만 쓸 수 있어요.'),
      'No challenge ticket.' => RemainingSurface.trNow('api_exception.body.56', '챌린지 참가권이 없어요.'),
      'Choose SHARE or free DIA.' => RemainingSurface.trNow('api_exception.body.57', 'SHARE 또는 무료 DIA로 결제해 주세요.'),
      'Insufficient Diamond deposit.' => RemainingSurface.trNow('api_exception.body.58', 'DIA 예치금이 부족해요.'),
      'Insufficient SRV (Value Token) balance.' => 'VALUE가 부족합니다.',
      'Invalid crew emblem.' => RemainingSurface.trNow('api_exception.body.59', '엠블럼을 확인해 주세요.'),
      'Invalid crew name.' => RemainingSurface.trNow('api_exception.body.60', '크루 이름을 확인해 주세요.'),
      'Invalid crew payment.' => RemainingSurface.trNow('api_exception.body.61', '크루 결제 방법을 확인해 주세요.'),
      'Invalid nickname.' => RemainingSurface.trNow('api_exception.body.62', '닉네임을 확인해 주세요.'),
      'Invalid room title.' => RemainingSurface.trNow('api_exception.body.63', '대회 제목을 확인해 주세요.'),
      'You do not own a crew.' => RemainingSurface.trNow('api_exception.body.64', '내 크루가 없어요.'),
      'Cannot use your own referral code.' => AppStrings.referralRedeemSelf,
      'Referral code not found.' => AppStrings.referralRedeemInvalid,
      'Referral code is required.' => RemainingSurface.trNow('api_exception.body.65', '초대 코드를 입력해 주세요.'),
      'Referral code can only be applied before trial completion.' =>
        RemainingSurface.trNow('api_exception.body.66', '체험 런을 끝내기 전에만 초대 코드를 쓸 수 있어요.'),
      'Diamond box not found.' => RemainingSurface.trNow('api_exception.body.67', '다이아 상자를 찾지 못했어요.'),
      'Diamond box is inactive.' => RemainingSurface.trNow('api_exception.body.68', '이 다이아 상자는 지금 쓸 수 없어요.'),
      'Weekly prize-race entry limit reached.' =>
        RemainingSurface.trNow('api_exception.body.69', '이번 주 상금 대회 참가 한도에 도달했어요.'),
      'Prize race entry does not accept DIA.' => RemainingSurface.trNow('api_exception.body.70', '상금 대회는 DIA로 참가할 수 없어요.'),
      'Streak is not broken.' => RemainingSurface.trNow('api_exception.body.71', '연속 기록이 끊기지 않았어요.'),
      'Streak break is outside 72 hours.' => RemainingSurface.trNow('api_exception.body.72', '끊긴 지 72시간이 지나 지킬 수 없어요.'),
      'No missed day to protect.' => RemainingSurface.trNow('api_exception.body.73', '지킬 빠진 날이 없어요.'),
      'Safeguard hold cap is 2.' => RemainingSurface.trNow('api_exception.body.74', '보호권은 2개까지 보관할 수 있어요.'),
      'CPR monthly use cap is 2.' => RemainingSurface.trNow('api_exception.body.75', 'CPR은 한 달에 2번까지 쓸 수 있어요.'),
      'Purchase token already used.' => RemainingSurface.trNow('api_exception.body.76', '이미 처리된 결제예요.'),
      'Purchase is not completed.' => RemainingSurface.trNow('api_exception.body.77', '결제가 아직 끝나지 않았어요.'),
      'Purchase token could not be verified.' => RemainingSurface.trNow('api_exception.body.78', '결제를 확인하지 못했어요.'),
      'Unknown DIA pack.' => RemainingSurface.trNow('api_exception.body.79', '알 수 없는 DIA 상품이에요.'),
      'Unknown Coach+ product.' => RemainingSurface.trNow('api_exception.body.80', '알 수 없는 코치+ 상품이에요.'),
      'Shop item not found.' => RemainingSurface.trNow('api_exception.body.81', '상점 아이템을 찾지 못했어요.'),
      'Extra entry ticket is spent by joining a race.' ||
      'Friend ghost pack is spent as single uses.' =>
        RemainingSurface.trNow('api_exception.body.82', '이 아이템은 한 번 쓸 때마다 하나씩 사라져요.'),
      'User not found.' => RemainingSurface.trNow('api_exception.body.83', '사용자 정보를 찾을 수 없어요.'),
      'Not found.' => RemainingSurface.trNow('api_exception.body.84', '찾을 수 없어요.'),
      'Missing Firebase ID token.' ||
      'Firebase token did not include uid.' =>
        RemainingSurface.trNow('api_exception.body.43', '로그인 인증이 만료되었습니다. 다시 로그인해 주세요.'),
      'Tournament does not exist.' ||
      'Tournament document does not exist.' =>
        RemainingSurface.trNow('api_exception.body.85', '대회 정보를 찾을 수 없습니다.'),
      'Tournament participation not found.' => RemainingSurface.trNow('api_exception.body.86', '참가 기록을 찾을 수 없어요.'),
      'Recorded run belongs to another runner.' => RemainingSurface.trNow('api_exception.body.87', '다른 사람의 기록이에요.'),
      'Recorded run has no pace.' ||
      'Recorded run is not verified.' ||
      'Recorded run not found.' =>
        RemainingSurface.trNow('api_exception.body.26', '친구의 검증된 기록을 선택해 주세요.'),
      'Mission completed. Mercy settlement is not required.' =>
        RemainingSurface.trNow('api_exception.body.88', '미션을 이미 완료해서 기부 정산이 필요 없어요.'),
      'Signed out.' => RemainingSurface.trNow('api_exception.body.89', '로그아웃되었어요.'),
      _ when !RegExp(r'[가-힣]').hasMatch(detail) => _genericFailure,
      _ => detail,
    };
  }
}
