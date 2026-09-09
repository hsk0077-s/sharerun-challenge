/// GCP Garmin API 클라우드 연동 어댑터의 로컬 Mock.
///
/// 실제 자격 증명은 네트워크로 유출하지 않으며, POST 패킷 형태만 재현한다.
class GarminOAuthException implements Exception {
  const GarminOAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GarminOAuthSession {
  const GarminOAuthSession({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class GarminCloudOAuthAdapter {
  static const String mockEndpoint =
      'https://europe-west1-src.cloudfunctions.net/garminOAuthAdapter';

  Future<GarminOAuthSession> authorize({
    required String email,
    required String password,
  }) async {
    final id = email.trim();
    if (id.isEmpty || password.isEmpty) {
      throw const GarminOAuthException('이메일과 비밀번호를 입력해 주세요.');
    }
    if (!_looksLikeEmail(id)) {
      throw const GarminOAuthException('올바른 이메일 형식이 아닙니다.');
    }

    await Future<void>.delayed(const Duration(milliseconds: 720));

    // Mock async POST — 비밀번호는 패킷에 실지 않음.
    final packet = <String, Object>{
      'endpoint': mockEndpoint,
      'method': 'POST',
      'headers': const {'Content-Type': 'application/json'},
      'body': <String, Object>{
        'grant_type': 'authorization_code',
        'client_id': 'src-garmin-cloud-adapter',
        'username': id,
      },
    };
    assert(packet['method'] == 'POST');

    if (password.length < 4) {
      throw const GarminOAuthException(
        '인증에 실패했습니다. Garmin 계정 정보를 확인해 주세요.',
      );
    }

    final seed = id.hashCode.abs();
    return GarminOAuthSession(
      accessToken: 'garmock_at_$seed',
      refreshToken: 'garmock_rt_$seed',
    );
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}
