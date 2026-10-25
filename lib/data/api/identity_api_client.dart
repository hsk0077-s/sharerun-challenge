import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_exception.dart';

class ProviderLoginResult {
  const ProviderLoginResult({
    this.customToken = '',
    this.newAccount = false,
    this.needsAccountChoice = false,
  });

  final String customToken;
  final bool newAccount;

  /// 확인된 이메일로 기존 계정을 못 찾았을 때. 계정을 만들지 않았다는 뜻이다.
  final bool needsAccountChoice;
}

class WatchPairingCode {
  const WatchPairingCode({required this.code, required this.expiresIn});

  final String code;
  final Duration expiresIn;
}

/// 예전 이름. 카카오만 있던 때의 이름을 그대로 쓰는 곳을 위해 남긴다.
typedef KakaoLoginResult = ProviderLoginResult;

/// 연결 직전에 보여 주는 대상 계정. 닉네임과 SHARE만 담는다.
class AccountLinkPreview {
  const AccountLinkPreview({
    required this.nickname,
    required this.shareBalance,
    required this.canLink,
  });

  final String nickname;
  final int shareBalance;
  final bool canLink;
}

/// 로그인 방법을 계정에 잇는 서버 API. 로그인 요청만 Firebase 인증 없이 부른다.
class IdentityApiClient {
  IdentityApiClient({
    required this.baseUri,
    Future<String?> Function()? idToken,
    FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
  })  : _idToken = idToken ??
            (() async => (firebaseAuth ?? FirebaseAuth.instance)
                .currentUser
                ?.getIdToken(true)),
        _httpClient = httpClient ?? http.Client();

  final Uri baseUri;
  final Future<String?> Function() _idToken;
  final http.Client _httpClient;

  static const _timeout = Duration(seconds: 20);

  /// 카카오 토큰을 서버에 보내고 Firebase 로그인 열쇠를 받는다.
  /// [createAccount]는 사람이 새 계정을 만들겠다고 고른 뒤에만 true.
  Future<ProviderLoginResult> kakaoLogin(
    String accessToken, {
    bool createAccount = false,
  }) =>
      _login('kakao', accessToken, createAccount: createAccount);

  /// 네이버 토큰을 서버에 보내고 Firebase 로그인 열쇠를 받는다.
  Future<ProviderLoginResult> naverLogin(
    String accessToken, {
    bool createAccount = false,
  }) =>
      _login('naver', accessToken, createAccount: createAccount);

  /// 구글 ID 토큰을 서버에 보낸다. 전화가 Firebase 사용자를 먼저 만들지 않는다.
  Future<ProviderLoginResult> googleLogin(
    String idToken, {
    bool createAccount = false,
  }) =>
      _login(
        'google',
        idToken,
        createAccount: createAccount,
        tokenField: 'id_token',
      );

  /// 애플 ID 토큰(iOS는 identityToken, 안드로이드는 Firebase ID 토큰)을 서버에 보낸다.
  Future<ProviderLoginResult> appleLogin(
    String idToken, {
    bool createAccount = false,
  }) =>
      _login(
        'apple',
        idToken,
        createAccount: createAccount,
        tokenField: 'id_token',
      );

  Future<void> linkKakao(String accessToken) => _link('kakao', accessToken);

  Future<void> linkNaver(String accessToken) => _link('naver', accessToken);

  Future<void> linkGoogle(String idToken) =>
      _signedIn('POST', '/auth/google/link', {'id_token': idToken});

  Future<void> linkApple(String idToken) =>
      _signedIn('POST', '/auth/apple/link', {'id_token': idToken});

  Future<void> unlinkApple() => _unlink('apple');

  /// 워치에 입력할 6자리 페어링 코드를 받는다. 5분 안에 한 번만 쓸 수 있다.
  Future<WatchPairingCode> requestWatchPairingCode() async {
    final json = await _signedIn('POST', '/actions/watch-pairing/code', const {});
    final code = json['code'];
    final expiresIn = json['expires_in'];
    if (code is! String || code.isEmpty) {
      throw StateError('Watch pairing code is missing.');
    }
    return WatchPairingCode(
      code: code,
      expiresIn: Duration(seconds: expiresIn is int ? expiresIn : 300),
    );
  }

  /// 이 계정에 연결된 워치를 모두 해제한다. 휴대폰 로그인은 그대로 유지된다.
  Future<void> revokeWatches() =>
      _signedIn('POST', '/actions/watch-pairing/revoke', const {});

  Future<void> unlinkKakao() => _unlink('kakao');

  Future<void> unlinkNaver() => _unlink('naver');

  Future<void> unlinkGoogle() => _unlink('google');

  /// 지금 로그인된 계정의 닉네임과 SHARE. 연결 확인 전에만 쓴다.
  Future<AccountLinkPreview> fetchLinkPreview() async {
    final json = await _signedIn('GET', '/auth/link-preview', null);
    final nickname = json['nickname'];
    final share = json['share_balance'];
    return AccountLinkPreview(
      nickname: nickname is String ? nickname.trim() : '',
      shareBalance: share is num ? share.toInt() : 0,
      canLink: json['can_link'] == true,
    );
  }

  Future<ProviderLoginResult> _login(
    String provider,
    String token, {
    bool createAccount = false,
    String tokenField = 'access_token',
  }) async {
    final response = await _httpClient
        .post(
          baseUri.resolve('/auth/$provider/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            tokenField: token,
            if (createAccount) 'create_account': true,
          }),
        )
        .timeout(_timeout);
    final json = _decode(response);
    if (json['needs_account_choice'] == true) {
      return const ProviderLoginResult(needsAccountChoice: true);
    }
    final custom = json['custom_token'];
    if (custom is! String || custom.isEmpty) {
      throw StateError('Login token missing from server response.');
    }
    return ProviderLoginResult(
      customToken: custom,
      newAccount: json['new_account'] == true,
    );
  }

  Future<void> _link(String provider, String accessToken) async {
    await _signedIn(
        'POST', '/auth/$provider/link', {'access_token': accessToken});
  }

  Future<void> _unlink(String provider) async {
    await _signedIn('POST', '/auth/$provider/unlink', const {});
  }

  /// 이 계정으로 로그인할 수 있는 방법. 예: ['google', 'kakao'].
  Future<List<String>> fetchProviders() async {
    final json = await _signedIn('GET', '/auth/identities', null);
    final list = json['providers'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is String) item
    ];
  }

  Future<Map<String, dynamic>> _signedIn(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final token = await _idToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase ID token is required.');
    }
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final uri = baseUri.resolve(path);
    final response = method == 'GET'
        ? await _httpClient.get(uri, headers: headers).timeout(_timeout)
        : await _httpClient
            .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(_timeout);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}
