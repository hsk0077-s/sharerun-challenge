import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'watch_platform.dart';

/// 서버 주소와 Firebase 웹 키. 빌드할 때 `--dart-define`으로 넣는다(저장소에 두지 않는다).
///   flutter build apk --dart-define=JENA_BASE_URL=https://... --dart-define=FIREBASE_API_KEY=...
const kJenaBaseUrl = String.fromEnvironment('JENA_BASE_URL');
const kFirebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');

class HttpReply {
  const HttpReply(this.status, this.body);

  final int status;
  final Map<String, Object?> body;

  bool get ok => status >= 200 && status < 300;
}

/// 네트워크 한 번. 실제로는 `dart:io`, 시험에서는 가짜.
abstract class JsonPoster {
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers,
  });
}

class IoJsonPoster implements JsonPoster {
  IoJsonPoster({Duration timeout = const Duration(seconds: 15)}) : _timeout = timeout;

  final Duration _timeout;

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.postUrl(uri).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.write(jsonEncode(body));
      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join().timeout(_timeout);
      Map<String, Object?> parsed = const {};
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) parsed = decoded.cast<String, Object?>();
      } catch (_) {}
      return HttpReply(response.statusCode, parsed);
    } finally {
      client.close(force: true);
    }
  }
}

/// 6자리 코드가 틀렸거나 만료됐을 때.
class PairingRejected implements Exception {
  const PairingRejected(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 코드 확인 요청이 가지 못했을 때(네트워크, 서버 설정 없음).
class PairingUnavailable implements Exception {
  const PairingUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 워치가 휴대폰 없이 계정에 붙는 방법.
///
/// 휴대폰 앱이 6자리 코드를 만들어 주면(`POST /actions/watch-pairing/code`),
/// 워치에서 그 코드를 `POST /auth/watch-pair`로 보내 Firebase 맞춤 토큰을 받고,
/// Firebase 로그인 REST로 ID 토큰과 갱신 토큰으로 바꾼다. 그 뒤 기록 올리기는
/// 휴대폰 앱과 같은 `Authorization: Bearer <ID 토큰>`을 쓴다.
class WatchAccount {
  WatchAccount({
    required KeyValueStore store,
    JsonPoster? poster,
    DateTime Function()? clock,
    String baseUrl = kJenaBaseUrl,
    String apiKey = kFirebaseApiKey,
  })  : _store = store,
        _poster = poster ?? IoJsonPoster(),
        _clock = clock ?? DateTime.now,
        _baseUrl = baseUrl,
        _apiKey = apiKey;

  static const _refreshKey = 'watch.refresh_token';
  static const _nicknameKey = 'watch.nickname';
  static const _deviceKey = 'watch.device_id';

  final KeyValueStore _store;
  final JsonPoster _poster;
  final DateTime Function() _clock;
  final String _baseUrl;
  final String _apiKey;

  String? _refreshToken;
  String? _idToken;
  DateTime _idTokenExpires = DateTime.fromMillisecondsSinceEpoch(0);
  String nickname = '';

  bool get isPaired => _refreshToken != null && _refreshToken!.isNotEmpty;

  bool get configured => _baseUrl.isNotEmpty && _apiKey.isNotEmpty;

  Future<void> load() async {
    _refreshToken = await _store.read(_refreshKey);
    nickname = await _store.read(_nicknameKey) ?? '';
  }

  /// 이 워치의 고유 번호. 한 번 만들어 계속 쓰므로 다시 연결해도 자리를 더 쓰지 않는다.
  Future<String> deviceId() async {
    final saved = await _store.read(_deviceKey);
    if (saved != null && saved.length >= 8) return saved;
    final random = Random.secure();
    final fresh = base64Url
        .encode(List<int>.generate(16, (_) => random.nextInt(256)))
        .replaceAll('=', '');
    await _store.write(_deviceKey, fresh);
    return fresh;
  }

  Future<void> unpair() async {
    _refreshToken = null;
    _idToken = null;
    nickname = '';
    await _store.delete(_refreshKey);
    await _store.delete(_nicknameKey);
  }

  /// 6자리 코드를 계정으로 바꾼다. 성공하면 [isPaired]가 true.
  Future<void> pair(String code) async {
    if (!configured) {
      throw const PairingUnavailable('no_server');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const PairingRejected('need_six_digits');
    }
    final HttpReply paired;
    try {
      paired = await _poster.post(
        Uri.parse('$_baseUrl/auth/watch-pair'),
        {'code': code, 'device_id': await deviceId(), 'device_label': 'Wear OS'},
      );
    } catch (_) {
      throw const PairingUnavailable('offline');
    }
    if (paired.status == 429) {
      throw const PairingRejected('rate_limited');
    }
    if (paired.status == 409) {
      throw const PairingRejected('watch_limit');
    }
    final custom = paired.body['custom_token'];
    if (!paired.ok || custom is! String || custom.isEmpty) {
      throw const PairingRejected('bad_code');
    }
    final HttpReply signedIn;
    try {
      signedIn = await _poster.post(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=$_apiKey',
        ),
        {'token': custom, 'returnSecureToken': true},
      );
    } catch (_) {
      throw const PairingUnavailable('offline');
    }
    final refresh = signedIn.body['refreshToken'];
    final idToken = signedIn.body['idToken'];
    if (!signedIn.ok || refresh is! String || idToken is! String) {
      throw const PairingUnavailable('sign_in_failed');
    }
    _remember(idToken, signedIn.body['expiresIn']);
    _refreshToken = refresh;
    nickname = (paired.body['nickname'] as String?) ?? '';
    await _store.write(_refreshKey, refresh);
    await _store.write(_nicknameKey, nickname);
  }

  void _remember(String idToken, Object? expiresIn) {
    final seconds = int.tryParse('$expiresIn') ?? 3600;
    _idToken = idToken;
    // 만료 직전에 쓰다 실패하지 않게 1분 일찍 새로 받는다.
    _idTokenExpires = _clock().add(Duration(seconds: seconds - 60));
  }

  /// 서버에 보낼 ID 토큰. 짝지어지지 않았거나 받지 못하면 null.
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (!isPaired || !configured) return null;
    if (!forceRefresh && _idToken != null && _clock().isBefore(_idTokenExpires)) {
      return _idToken;
    }
    final HttpReply reply;
    try {
      reply = await _poster.post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=$_apiKey'),
        {'grant_type': 'refresh_token', 'refresh_token': _refreshToken},
      );
    } catch (_) {
      return null;
    }
    final fresh = reply.body['id_token'];
    if (!reply.ok || fresh is! String) {
      // 계정이 지워졌거나 로그아웃됐다면 갱신 토큰은 더 못 쓴다.
      if (reply.status == 400 || reply.status == 401) {
        await unpair();
      }
      return null;
    }
    final rotated = reply.body['refresh_token'];
    if (rotated is String && rotated.isNotEmpty && rotated != _refreshToken) {
      _refreshToken = rotated;
      await _store.write(_refreshKey, rotated);
    }
    _remember(fresh, reply.body['expires_in']);
    return fresh;
  }

  /// 로그인된 계정으로 서버에 본문을 보낸다. 토큰이 만료돼 401이면 한 번 새로 받아 다시 보낸다.
  Future<HttpReply?> postSigned(String path, Map<String, Object?> body) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await idToken(forceRefresh: attempt > 0);
      if (token == null) return null;
      final HttpReply reply;
      try {
        reply = await _poster.post(
          Uri.parse('$_baseUrl$path'),
          body,
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        return null;
      }
      if (reply.status != 401) return reply;
      // 휴대폰에서 "워치 모두 해제"를 눌렀다. 이 워치의 연결은 더 못 쓰므로 지운다.
      if (reply.body['detail'] == 'watch_revoked') {
        await unpair();
        return null;
      }
    }
    return null;
  }
}
