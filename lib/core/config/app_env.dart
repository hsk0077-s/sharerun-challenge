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

  static bool get useFirebaseEmulator =>
      _bool('USE_FIREBASE_EMULATOR', defaultValue: false);

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

  static String get jenaBaseUrl => _get(
        'JENA_BASE_URL',
        defaultValue: 'http://10.0.2.2:8080',
      );

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
}
