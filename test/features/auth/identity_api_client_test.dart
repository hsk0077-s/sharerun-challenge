import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/data/api/identity_api_client.dart';

void main() {
  final base = Uri.parse('https://example.test');

  IdentityApiClient client(
    Future<http.Response> Function(http.Request) handler, {
    String? token = 'id-token',
  }) {
    return IdentityApiClient(
      baseUri: base,
      idToken: () async => token,
      httpClient: MockClient(handler),
    );
  }

  test('login goes out without a Firebase token and returns the key', () async {
    late http.Request seen;
    final api = client((request) async {
      seen = request;
      return http.Response(
        jsonEncode({'custom_token': 'abc', 'new_account': true}),
        200,
      );
    }, token: null);

    final result = await api.kakaoLogin('kakao-token-12345');
    expect(result.customToken, 'abc');
    expect(result.newAccount, isTrue);
    expect(seen.url.path, '/auth/kakao/login');
    expect(seen.headers.containsKey('Authorization'), isFalse);
    expect(jsonDecode(seen.body), {'access_token': 'kakao-token-12345'});
  });

  test('link, unlink and the list carry the Firebase token', () async {
    final seen = <http.Request>[];
    final api = client((request) async {
      seen.add(request);
      if (request.url.path == '/auth/identities') {
        return http.Response(
          jsonEncode({
            'providers': ['google', 'kakao']
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'linked': true}), 200);
    });

    await api.linkKakao('kakao-token-12345');
    await api.unlinkKakao();
    expect(await api.fetchProviders(), ['google', 'kakao']);

    expect(seen.map((r) => r.url.path), [
      '/auth/kakao/link',
      '/auth/kakao/unlink',
      '/auth/identities',
    ]);
    for (final request in seen) {
      expect(request.headers['Authorization'], 'Bearer id-token');
    }
    expect(seen.last.method, 'GET');
  });

  test('a signed-in call without a Firebase token is refused locally',
      () async {
    var called = false;
    final api = client((request) async {
      called = true;
      return http.Response('{}', 200);
    }, token: null);
    await expectLater(api.unlinkKakao(), throwsStateError);
    expect(called, isFalse);
  });

  test('server errors become messages a person can read', () async {
    final api = client(
      (request) async => http.Response(
        jsonEncode({'detail': 'identity_belongs_to_another_account'}),
        409,
      ),
    );
    await expectLater(
      api.linkKakao('kakao-token-12345'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 409)
            .having((e) => e.userMessage, 'message', contains('다른 쉐어런 계정')),
      ),
    );
  });

  test('every identity error has a friendly message', () {
    for (final detail in const [
      'identity_belongs_to_another_account',
      'provider_already_linked',
      'last_login_method',
      'not_linked',
      'invalid_provider_token',
      'provider_token_for_other_app',
      'provider_unreachable',
      'kakao_not_configured',
      'custom_token_unavailable',
      'too_many_attempts',
    ]) {
      expect(ApiErrorMessage.forDetail(detail), isNot(detail), reason: detail);
    }
  });
}
