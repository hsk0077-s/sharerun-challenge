import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime config from `--dart-define` / `--dart-define-from-file=.env`.
/// Project-root `.env` is not a Flutter asset (gitignored; omitted from
/// pubspec so CI can build). Do not load it via dotenv at startup.
abstract final class AppEnv {
  static var _loaded = false;

  static Future<void> load() async {
    if (_loaded) {
      return;
    }
    // `.env` is gitignored and is not a Flutter asset (removed so CI can
    // build the bundle). Do not call dotenv.load(fileName: '.env') — a missing
    // asset throws FlutterError/FileNotFoundError on every cold start.
    // Runtime values come from --dart-define / --dart-define-from-file=.env.
    if (!dotenv.isInitialized) {
      try {
        dotenv.loadFromString(envString: 'APP_ENV_LOADED=1');
      } catch (_) {
        // Getter still guards with isInitialized.
      }
    }
    _loaded = true;
  }

  // `String.fromEnvironment` only sees a const literal. A runtime key is ''.
  static const _jenaBaseUrlDefine = String.fromEnvironment('JENA_BASE_URL');
  static const _googleWebClientIdDefine =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _firebaseProjectIdDefine =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _firebaseApiKeyDefine =
      String.fromEnvironment('FIREBASE_API_KEY');
  static const _firebaseAppIdDefine = String.fromEnvironment('FIREBASE_APP_ID');
  static const _firebaseMessagingSenderIdDefine =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _firebaseEmulatorHostDefine =
      String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  static const _firebaseAuthEmulatorPortDefine =
      String.fromEnvironment('FIREBASE_AUTH_EMULATOR_PORT');
  static const _firebaseFirestoreEmulatorPortDefine =
      String.fromEnvironment('FIREBASE_FIRESTORE_EMULATOR_PORT');
  static const _localDevModeDefine = String.fromEnvironment('LOCAL_DEV_MODE');
  static const _sponsorshipEnabledDefine =
      String.fromEnvironment('SPONSORSHIP_ENABLED');
  static const _diaPacksEnabledDefine =
      String.fromEnvironment('DIA_PACKS_ENABLED');
  static const _useFirebaseEmulatorDefine =
      String.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const _androidEmulatorDefine =
      String.fromEnvironment('ANDROID_EMULATOR');

  static String _get(
    String key, {
    required String defaultValue,
    String fromDefine = '',
  }) {
    final fromDotenv = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return fromDotenv;
    }
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return defaultValue;
  }

  static bool _bool(
    String key, {
    required bool defaultValue,
    String fromDefine = '',
  }) {
    final raw = _get(
      key,
      defaultValue: defaultValue ? 'true' : 'false',
      fromDefine: fromDefine,
    );
    return raw.toLowerCase() == 'true' || raw == '1';
  }

  static bool get localDevMode => _bool(
        'LOCAL_DEV_MODE',
        defaultValue: kDebugMode,
        fromDefine: _localDevModeDefine,
      );

  /// Auth/Firestore emulators are debug-only. Release/profile must mint
  /// production ID tokens so Cloud Run `verify_id_token` accepts them —
  /// a baked `.env` `USE_FIREBASE_EMULATOR=true` is ignored when
  /// [kDebugMode] is false.
  static bool get useFirebaseEmulator => resolveUseFirebaseEmulator(
        debugMode: kDebugMode,
        configured: _bool(
          'USE_FIREBASE_EMULATOR',
          defaultValue: false,
          fromDefine: _useFirebaseEmulatorDefine,
        ),
      );

  static bool resolveUseFirebaseEmulator({
    required bool debugMode,
    required bool configured,
  }) =>
      debugMode && configured;

  /// 이용자 후원(대회 후원, 러너 후원 배너와 결제)을 보여 줄지. 후원은 보류라
  /// 기본값은 꺼짐이다. 다시 열 때만 `.env`나 `--dart-define`에
  /// `SPONSORSHIP_ENABLED=true`를 넣는다.
  static bool get sponsorshipEnabled => _bool(
        'SPONSORSHIP_ENABLED',
        defaultValue: false,
        fromDefine: _sponsorshipEnabledDefine,
      );

  /// DIA 팩(돈으로 사는 DIA)을 보여 줄지. 1.0은 판매가 없어 기본값은 꺼짐이다.
  /// 판매를 시작할 때만 `--dart-define`에 `DIA_PACKS_ENABLED=true`를 넣는다.
  static bool get diaPacksEnabled => _bool(
        'DIA_PACKS_ENABLED',
        defaultValue: false,
        fromDefine: _diaPacksEnabledDefine,
      );

  static bool get useLocalMockData =>
      _bool('USE_LOCAL_MOCK_DATA', defaultValue: false);

  static bool get allowAnonymousBootstrap =>
      _bool('ALLOW_ANONYMOUS_BOOTSTRAP', defaultValue: false);

  static String get firebaseProjectId => _get(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'demo-src-local',
        fromDefine: _firebaseProjectIdDefine,
      );

  static String get firebaseApiKey => _get(
        'FIREBASE_API_KEY',
        defaultValue: 'demo-api-key',
        fromDefine: _firebaseApiKeyDefine,
      );

  static String get firebaseAppId => _get(
        'FIREBASE_APP_ID',
        defaultValue: '1:demo-src-local:android:local',
        fromDefine: _firebaseAppIdDefine,
      );

  static String get firebaseMessagingSenderId => _get(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '123456789012',
        fromDefine: _firebaseMessagingSenderIdDefine,
      );

  /// Web OAuth client ID for Google Sign-In on Android.
  /// Required when `google-services.json` is absent.
  static String get googleWebClientId => _get(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue: '',
        fromDefine: _googleWebClientIdDefine,
      );

  static String get firebaseEmulatorHost {
    final configured = _get(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '',
      fromDefine: _firebaseEmulatorHostDefine,
    );
    if (configured.isNotEmpty) {
      return configured;
    }
    if (kIsWeb) {
      return 'localhost';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static int get firebaseAuthEmulatorPort =>
      int.tryParse(
        _get(
          'FIREBASE_AUTH_EMULATOR_PORT',
          defaultValue: '9099',
          fromDefine: _firebaseAuthEmulatorPortDefine,
        ),
      ) ??
      9099;

  static int get firebaseFirestoreEmulatorPort =>
      int.tryParse(
        _get(
          'FIREBASE_FIRESTORE_EMULATOR_PORT',
          defaultValue: '8085',
          fromDefine: _firebaseFirestoreEmulatorPortDefine,
        ),
      ) ??
      8085;

  /// Local Jena URL when `JENA_BASE_URL` is unset **in debug**.
  ///
  /// Android emulator: `http://10.0.2.2:8080` (`--dart-define=ANDROID_EMULATOR=true`
  /// or `--dart-define=JENA_BASE_URL=http://10.0.2.2:8080`).
  /// Physical Android debug: `http://127.0.0.1:8080` with
  /// `adb reverse tcp:8080 tcp:8080`. iOS/desktop: loopback.
  ///
  /// Release/profile never uses this fallback (see [resolveJenaBaseUrl]).
  static String defaultJenaBaseUrl({
    bool? isAndroid,
    bool? androidEmulator,
  }) {
    final android = isAndroid ?? (!kIsWeb && Platform.isAndroid);
    final emulator = androidEmulator ??
        _bool(
          'ANDROID_EMULATOR',
          defaultValue: false,
          fromDefine: _androidEmulatorDefine,
        );
    if (android && emulator) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  /// Public Cloud Run URL for release/profile when `JENA_BASE_URL` is unset
  /// or still a debug loopback. Not a secret. Override with
  /// `--dart-define=JENA_CLOUD_RUN_BASE_URL=https://<service>`.
  /// Debug builds ignore this unless `JENA_BASE_URL` is set.
  static const String shippedJenaCloudRunUrl = String.fromEnvironment(
    'JENA_CLOUD_RUN_BASE_URL',
    defaultValue: 'https://src-jena-ai-1089697395275.asia-northeast3.run.app',
  );

  static bool isLoopbackJenaUrl(String url) {
    final parsed = Uri.tryParse(url.trim());
    final host = (parsed != null && parsed.host.isNotEmpty)
        ? parsed.host.toLowerCase()
        : url.toLowerCase();
    return host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '10.0.2.2' ||
        host == '::1' ||
        host == '[::1]' ||
        host.contains('127.0.0.1') ||
        host.contains('localhost') ||
        host.contains('10.0.2.2');
  }

  /// 이 폰 밖에서는 닿지 않는 개발용 주소인지. 자기 자신(127.0.0.1)뿐 아니라
  /// 집·사무실 안 주소(192.168.x.x, 10.x.x.x, 172.16~31.x.x, 169.254.x.x, *.local)도 포함한다.
  /// 개발 PC 주소가 `.env`에 남은 채로 릴리스 빌드가 나가면 줍기 같은 서버 요청이 전부 실패한다.
  static bool isLocalNetworkJenaUrl(String url) {
    if (isLoopbackJenaUrl(url)) return true;
    final parsed = Uri.tryParse(url.trim());
    final host = (parsed != null && parsed.host.isNotEmpty)
        ? parsed.host.toLowerCase()
        : url.trim().toLowerCase();
    if (host.endsWith('.local') || host == 'local') return true;
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final nums = <int>[];
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
      nums.add(n);
    }
    final a = nums[0];
    final b = nums[1];
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 169 && b == 254);
  }

  /// Debug: `JENA_BASE_URL` or loopback. Release: never loopback — Cloud Run
  /// via `JENA_BASE_URL` / `JENA_CLOUD_RUN_BASE_URL` / [shippedJenaCloudRunUrl].
  static String resolveJenaBaseUrl({
    required bool debugMode,
    String configured = '',
    String productionUrl = '',
    bool? isAndroid,
    bool? androidEmulator,
  }) {
    final trimmed = configured.trim();
    if (debugMode) {
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
      return defaultJenaBaseUrl(
        isAndroid: isAndroid,
        androidEmulator: androidEmulator,
      );
    }

    if (trimmed.isNotEmpty && !isLocalNetworkJenaUrl(trimmed)) {
      return trimmed;
    }
    final production = productionUrl.trim();
    if (production.isNotEmpty && !isLocalNetworkJenaUrl(production)) {
      return production;
    }
    throw StateError(
      'Release/profile build has no Cloud Run Jena URL. '
      'Pass --dart-define=JENA_BASE_URL=https://<src-jena-ai> '
      'or --dart-define=JENA_CLOUD_RUN_BASE_URL=https://<src-jena-ai>.',
    );
  }

  static String get jenaBaseUrl => resolveJenaBaseUrl(
        debugMode: kDebugMode,
        configured: _get(
          'JENA_BASE_URL',
          defaultValue: '',
          fromDefine: _jenaBaseUrlDefine,
        ),
        productionUrl: shippedJenaCloudRunUrl,
      );

  static const _demoFirebaseProjectId = 'demo-src-local';
  static const _demoFirebaseApiKey = 'demo-api-key';

  static bool isPlaceholderFirebaseConfig({
    String? projectId,
    String? apiKey,
  }) {
    final project = (projectId ?? firebaseProjectId).trim();
    final key = (apiKey ?? firebaseApiKey).trim();
    return project.isEmpty ||
        project == _demoFirebaseProjectId ||
        key.isEmpty ||
        key == _demoFirebaseApiKey;
  }

  /// Release/profile with demo `.env` keys must use native
  /// `google-services.json` / `GoogleService-Info.plist` so ID tokens
  /// match Cloud Run's GCP project.
  static bool preferNativeFirebaseOptions({
    bool? debugMode,
    bool? placeholder,
    bool? emulator,
  }) {
    final debug = debugMode ?? kDebugMode;
    if (debug) {
      return false;
    }
    return (placeholder ?? isPlaceholderFirebaseConfig()) &&
        !(emulator ?? useFirebaseEmulator);
  }

  static String get pgBaseUrl => _get(
        'PG_BASE_URL',
        defaultValue: 'https://pg.example.com',
      );

  static String get googleMapsApiKey =>
      _get('GOOGLE_MAPS_API_KEY', defaultValue: '');

  static bool get googleMapsNativeConfigured =>
      _bool('GOOGLE_MAPS_NATIVE_CONFIGURED', defaultValue: false);

  /// True when Dart config indicates Maps may be attempted safely.
  static bool get isGoogleMapsConfigured {
    final key = googleMapsApiKey.trim();
    if (key.isNotEmpty &&
        key != 'your-google-maps-api-key' &&
        key != 'demo-maps-key') {
      return true;
    }
    return googleMapsNativeConfigured;
  }

  /// Optional override for the debug 1M grant secret.
  /// Empty = use the baked debug-client secret (kDebugMode only).
  static String get testWalletGrantSecret =>
      _get('TEST_WALLET_GRANT_SECRET', defaultValue: '').trim();
}
