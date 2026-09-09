import 'dart:convert';

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
      'Lower-tier room is locked.' => '내 등급보다 낮은 방은 참가할 수 없습니다.',
      'Insufficient Share balance.' => 'Share 잔액이 부족합니다.',
      'Refund exceeds Share balance.' => '환불 가능한 Share 잔액을 초과했습니다.',
      'Move closer to collect.' => '다이아 상자에 더 가까이 이동해 주세요.',
      'Diamond box already collected.' => '이미 수집한 다이아 상자입니다.',
      'Verified own activity required.' => '본인의 검증 완료 러닝만 처리할 수 있습니다.',
      'Reward already processed.' => '이미 처리된 우승 보상입니다.',
      'No reward available.' => '수령 가능한 보상이 없습니다.',
      'Insufficient Value to donate.' => '기부할 Value Token이 부족합니다.',
      'Activity belongs to another user.' => '다른 사용자의 활동입니다.',
      'User or tournament not found.' => '사용자 또는 대회 정보를 찾을 수 없습니다.',
      'User or activity not found.' => '사용자 또는 활동 정보를 찾을 수 없습니다.',
      'Email verification is required.' => '이메일 인증을 완료해 주세요.',
      _ => detail,
    };
  }
}
