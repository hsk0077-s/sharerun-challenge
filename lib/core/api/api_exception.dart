import 'dart:convert';

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
  static String from(Object error) {
    if (error is ApiException) {
      return error.userMessage;
    }
    return error.toString();
  }

  static String forDetail(String detail) {
    return switch (detail) {
      'Tournament is full.' => '대회 정원이 가득 찼습니다.',
      'Tournament is not recruiting.' => '현재 모집 중인 대회가 아닙니다.',
      'Prize races accept only SHARE or free tickets.' =>
        '상금 대회는 SHARE 또는 무료 참가권만 사용할 수 있습니다.',
      'Extra entry daily use cap is 2.' => '추가 참가권은 하루에 2번까지 사용할 수 있습니다.',
      'No extra entry ticket.' => '사용할 추가 참가권이 없습니다.',
      'Coach one-point daily use cap is 1.' => '코치 원포인트권은 하루에 1번까지 사용할 수 있습니다.',
      'Lower-tier room is locked.' => '내 등급보다 낮은 방은 참가할 수 없습니다.',
      'Insufficient Share balance.' => 'SHARE가 부족합니다.',
      'Insufficient free tickets.' => '무료 참가권이 부족합니다.',
      'No valid entry ticket for this tier.' => '이 등급에 쓸 수 있는 참가권이 없어요.',
      'This entry ticket is not valid for this edition.' =>
        '이 참가권은 이번 회차에는 쓸 수 없어요.',
      'This race has no edition, so an entry ticket cannot be used.' =>
        '회차가 없는 대회에는 참가권을 쓸 수 없어요.',
      'Ticket seats for this race are full. You can still join with SHARE.' =>
        '참가권 자리가 다 찼습니다. SHARE로는 참가할 수 있어요.',
      'This tier does not accept free tickets.' => '이 대회는 무료 참가권을 사용할 수 없습니다.',
      'Season qualification is required.' => '시즌 진출 자격이 있어야 참가할 수 있습니다.',
      'Boost run already used today.' => '부스트 런은 하루에 1번까지 사용할 수 있습니다.',
      'An incubator is already active.' => '만보기 부화기는 한 번에 하나만 동작합니다.',
      'Insufficient Diamond balance.' => 'DIA가 부족합니다. 상점에서 구매해 주세요.',
      'Insufficient paid Diamond balance.' =>
        '유료 DIA가 부족합니다. 무료 DIA로는 배틀런 패스를 살 수 없습니다.',
      'Battle pass already owned for this season.' =>
        '이번 시즌 배틀런 패스는 이미 구매했습니다.',
      'Battle pass is not spent.' => '배틀런 패스는 사용해서 사라지지 않습니다.',
      'Pass upgrade price is invalid.' => '패스+ 가격이 패스보다 낮아 업그레이드할 수 없습니다.',
      'No crew.' => '소속 크루가 없습니다.',
      'No item to use.' => '사용할 아이템이 없습니다.',
      'Crew not found.' => '크루를 찾지 못했습니다.',
      'Cheer flag is already up for this crew today.' =>
        '이 크루의 응원 깃발은 오늘 이미 걸려 있습니다.',
      'Friend recorded run is required.' => '친구의 검증된 기록을 선택해 주세요.',
      'Refund exceeds Share balance.' => '환불 가능한 Share 잔액을 초과했습니다.',
      'Move closer to collect.' => '다이아 상자에 더 가까이 이동해 주세요.',
      'Diamond box already collected.' => '이미 수집한 다이아 상자입니다.',
      'Verified own activity required.' => '본인의 검증 완료 러닝만 처리할 수 있습니다.',
      'Reward already processed.' => '이미 처리된 우승 보상입니다.',
      'No reward available.' => '수령 가능한 보상이 없습니다.',
      'Insufficient Value to donate.' => '기부할 Value Token이 부족합니다.',
      'Insufficient Value balance.' => 'VALUE가 부족합니다.',
      'That day already counts.' => '이미 기록이 있는 날은 휴식일로 지정할 수 없습니다.',
      'That day is already a rest day.' => '그 날은 이미 휴식일입니다.',
      'Rest day must be today or yesterday.' => '휴식일은 오늘 또는 어제로만 지정할 수 있습니다.',
      'Donation match monthly cap reached.' => '이번 달 기부 매칭 횟수를 모두 사용했습니다.',
      'Donation match company cap reached.' =>
        '이번 달 회사 기부 한도에 도달했습니다. VALUE는 차감되지 않았습니다.',
      'Activity belongs to another user.' => '다른 사용자의 활동입니다.',
      'User or tournament not found.' => '사용자 또는 대회 정보를 찾을 수 없습니다.',
      'User or activity not found.' => '사용자 또는 활동 정보를 찾을 수 없습니다.',
      'Email verification is required.' => '이메일 인증을 완료해 주세요.',
      'Invalid Firebase ID token.' => '로그인 인증이 만료되었습니다. 다시 로그인해 주세요.',
      'invalid' => AppStrings.referralRedeemInvalid,
      'self' => AppStrings.referralRedeemSelf,
      'already' => AppStrings.referralRedeemAlready,
      'expired' => AppStrings.referralRedeemExpired,
      _ => detail,
    };
  }
}
