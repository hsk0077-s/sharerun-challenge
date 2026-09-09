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
        'Share 잔액이 부족합니다.',
      );
    });

    test('returns unknown detail unchanged', () {
      expect(
        ApiErrorMessage.forDetail('Unexpected backend error.'),
        'Unexpected backend error.',
      );
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
  });
}
