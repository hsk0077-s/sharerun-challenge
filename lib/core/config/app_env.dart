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

  static String _get(String key, {required String defaultValue}) {
    final fromDotenv =
        dotenv.isInitialized ? dotenv.maybeGet(key) : null;
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return fromDotenv;
    }
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return defaultValue;
  }

  static bool _bool(String key, {required bool defaultValue}) {
    final raw = _get(key, defaultValue: defaultValue ? 'true' : 'false');
    return raw.toLowerCase() == 'true' || raw == '1';
  }

  static bool get localDevMode => _bool('LOCAL_DEV_MODE', defaultValue: kDebugMode);

  /// Auth/Firestore emulators are debug-only. Release/profile must mint
  /// production ID tokens so Cloud Run `verify_id_token` accepts them —
  /// a baked `.env` `USE_FIREBASE_EMULATOR=true` is ignored when
  /// [kDebugMode] is false.
  static bool get useFirebaseEmulator => resolveUseFirebaseEmulator(
        debugMode: kDebugMode,
        configured: _bool('USE_FIREBASE_EMULATOR', defaultValue: false),
      );

  static bool resolveUseFirebaseEmulator({
    required bool debugMode,
    required bool configured,
  }) =>
      debugMode && configured;

  static bool get useLocalMockData =>
      _bool('USE_LOCAL_MOCK_DATA', defaultValue: false);

  static bool get allowAnonymousBootstrap =>
      _bool('ALLOW_ANONYMOUS_BOOTSTRAP', defaultValue: false);

  static String get firebaseProjectId =>
      _get('FIREBASE_PROJECT_ID', defaultValue: 'demo-src-local');

  static String get firebaseApiKey =>
      _get('FIREBASE_API_KEY', defaultValue: 'demo-api-key');

  static String get firebaseAppId =>
      _get('FIREBASE_APP_ID', defaultValue: '1:demo-src-local:android:local');

  static String get firebaseMessagingSenderId =>
      _get('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789012');

  /// Web OAuth client ID for Google Sign-In on Android.
  /// Required when `google-services.json` is absent.
  static String get googleWebClientId =>
      _get('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static String get firebaseEmulatorHost {
    final configured = _get('FIREBASE_EMULATOR_HOST', defaultValue: '');
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
      int.tryParse(_get('FIREBASE_AUTH_EMULATOR_PORT', defaultValue: '9099')) ??
      9099;

  static int get firebaseFirestoreEmulatorPort => int.tryParse(
        _get('FIREBASE_FIRESTORE_EMULATOR_PORT', defaultValue: '8085'),
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
    final emulator =
        androidEmulator ?? _bool('ANDROID_EMULATOR', defaultValue: false);
    if (android && emulator) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  /// Public Cloud Run URL for release/profile when `JENA_BASE_URL` is unset
  /// or still a debug loopback. Not a secret. Set via
  /// `--dart-define=JENA_CLOUD_RUN_BASE_URL=https://<service>` or replace
  /// the empty default after:
  /// `gcloud run services describe src-jena-ai --region asia-northeast3 --format='value(status.url)'`
  static const String shippedJenaCloudRunUrl = String.fromEnvironment(
    'JENA_CLOUD_RUN_BASE_URL',
    defaultValue: '',
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

    if (trimmed.isNotEmpty && !isLoopbackJenaUrl(trimmed)) {
      return trimmed;
    }
    final production = productionUrl.trim();
    if (production.isNotEmpty && !isLoopbackJenaUrl(production)) {
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
        configured: _get('JENA_BASE_URL', defaultValue: ''),
        productionUrl: shippedJenaCloudRunUrl.isNotEmpty
            ? shippedJenaCloudRunUrl
            : _get('JENA_CLOUD_RUN_BASE_URL', defaultValue: ''),
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
