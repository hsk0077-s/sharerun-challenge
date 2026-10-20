import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';

void main() {
  group('ApiException.fromHttpResponse', () {
    test('parses string detail from FastAPI body', () {
      final exception = ApiException.fromHttpResponse(
        statusCode: 409,
        body: '{"detail":"Tournament is full."}',
      );

      expect(exception.statusCode, 409);
      expect(exception.detail, 'Tournament is full.');
      expect(exception.userMessage, '대회 정원이 가득 찼습니다.');
    });

    test('parses validation list detail from FastAPI body', () {
      final exception = ApiException.fromHttpResponse(
        statusCode: 422,
        body: '{"detail":[{"msg":"Field required"}]}',
      );

      expect(exception.detail, 'Field required');
    });

    test('falls back to raw body when detail is missing', () {
      final exception = ApiException.fromHttpResponse(
        statusCode: 500,
        body: 'Internal Server Error',
      );

      expect(exception.detail, 'Internal Server Error');
    });
  });

  group('ApiErrorMessage', () {
    test('maps known backend detail to Korean copy', () {
      expect(
        ApiErrorMessage.forDetail('Insufficient Share balance.'),
        'SHARE가 부족합니다.',
      );
    });

    test('unknown English detail becomes a Korean generic message', () {
      expect(
        ApiErrorMessage.forDetail('Unexpected backend error.'),
        '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    });

    test('Korean detail passes through unchanged', () {
      expect(ApiErrorMessage.forDetail('이미 처리했어요.'), '이미 처리했어요.');
    });

    test('from returns userMessage for ApiException', () {
      const exception = ApiException(
        statusCode: 409,
        detail: 'Tournament is full.',
      );

      expect(ApiErrorMessage.from(exception), '대회 정원이 가득 찼습니다.');
    });

    test('from stringifies non-ApiException errors', () {
      expect(
        ApiErrorMessage.from(StateError('boom')),
        contains('boom'),
      );
    });

    test('maps Invalid Firebase ID token to Korean copy', () {
      expect(
        ApiErrorMessage.forDetail('Invalid Firebase ID token.'),
        '로그인 인증이 만료되었습니다. 다시 로그인해 주세요.',
      );
    });
  });
}
