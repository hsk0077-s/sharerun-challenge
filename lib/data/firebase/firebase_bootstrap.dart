import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';

Future<void> bootstrapFirebase() async {
  if (AppEnv.useLocalMockData) {
    debugPrint('Firebase skipped: USE_LOCAL_MOCK_DATA=true');
    return;
  }

  final options = FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey,
    appId: AppEnv.firebaseAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
  );

  try {
    // Release + demo dart-define keys: do not bind the default app to
    // demo-src-local. Native google-services.json tokens match Cloud Run.
    if (AppEnv.preferNativeFirebaseOptions()) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: options);
    }
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') {
      await _initializeExistingDefaultApp(error);
    }
  } catch (error) {
    await _initializeExistingDefaultApp(error);
  }

  if (!AppEnv.useFirebaseEmulator || AppEnv.useLocalMockData) {
    debugPrint(
      AppEnv.useLocalMockData
          ? 'Firebase mock UI mode: emulators skipped'
          : 'Firebase production config (no emulator)',
    );
    return;
  }

  final host = AppEnv.firebaseEmulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(
    host,
    AppEnv.firebaseAuthEmulatorPort,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    host,
    AppEnv.firebaseFirestoreEmulatorPort,
  );
  debugPrint(
    'Firebase emulators: auth=$host:${AppEnv.firebaseAuthEmulatorPort} '
    'firestore=$host:${AppEnv.firebaseFirestoreEmulatorPort}',
  );
}

/// Native `google-services.json` / GoogleService-Info.plist may already have
/// created the default app. AppEnv demo keys (no bundled `.env`) must not
/// crash cold start — keep the existing app if Dart options disagree.
Future<void> _initializeExistingDefaultApp(Object error) async {
  debugPrint('Firebase initializeApp(options) failed: $error');
  if (Firebase.apps.isNotEmpty) {
    return;
  }
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (fallback) {
    if (fallback.code != 'duplicate-app') {
      rethrow;
    }
  }
}
