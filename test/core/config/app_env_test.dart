import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_run_challenge/core/config/app_env.dart';

void main() {
  test('AppEnv.load succeeds when .env is not a Flutter asset', () async {
    await AppEnv.load();
    await AppEnv.load();

    expect(dotenv.isInitialized, isTrue);
    expect(AppEnv.firebaseProjectId, isNotEmpty);
    expect(AppEnv.jenaBaseUrl, isNotEmpty);
    expect(AppEnv.useLocalMockData, isFalse);
    expect(AppEnv.useFirebaseEmulator, isFalse);
  });

  test('jena default prefers loopback on physical Android; emulator keeps 10.0.2.2',
      () {
    expect(
      AppEnv.defaultJenaBaseUrl(isAndroid: true, androidEmulator: false),
      'http://127.0.0.1:8080',
    );
    expect(
      AppEnv.defaultJenaBaseUrl(isAndroid: true, androidEmulator: true),
      'http://10.0.2.2:8080',
    );
    expect(
      AppEnv.defaultJenaBaseUrl(isAndroid: false, androidEmulator: false),
      'http://127.0.0.1:8080',
    );
  });

  test('debug Jena keeps loopback when JENA_BASE_URL is unset', () {
    expect(
      AppEnv.resolveJenaBaseUrl(
        debugMode: true,
        isAndroid: true,
        androidEmulator: false,
      ),
      'http://127.0.0.1:8080',
    );
    expect(
      AppEnv.resolveJenaBaseUrl(
        debugMode: true,
        configured: 'http://127.0.0.1:8080',
      ),
      'http://127.0.0.1:8080',
    );
  });

  test('release Jena uses Cloud Run and never loopback', () {
    const cloudRun = 'https://src-jena-ai-hash.asia-northeast3.run.app';
    expect(
      AppEnv.resolveJenaBaseUrl(
        debugMode: false,
        configured: cloudRun,
      ),
      cloudRun,
    );
    expect(
      AppEnv.resolveJenaBaseUrl(
        debugMode: false,
        configured: 'http://127.0.0.1:8080',
        productionUrl: cloudRun,
      ),
      cloudRun,
    );
    expect(
      AppEnv.resolveJenaBaseUrl(
        debugMode: false,
        configured: '',
        productionUrl: cloudRun,
      ),
      cloudRun,
    );
    expect(
      () => AppEnv.resolveJenaBaseUrl(debugMode: false),
      throwsA(isA<StateError>()),
    );
    expect(AppEnv.isLoopbackJenaUrl('http://10.0.2.2:8080'), isTrue);
    expect(AppEnv.isLoopbackJenaUrl(cloudRun), isFalse);
  });

  test('Firebase emulator is debug-only so release mints production ID tokens',
      () {
    expect(
      AppEnv.resolveUseFirebaseEmulator(debugMode: true, configured: true),
      isTrue,
    );
    expect(
      AppEnv.resolveUseFirebaseEmulator(debugMode: false, configured: true),
      isFalse,
    );
    expect(
      AppEnv.isPlaceholderFirebaseConfig(
        projectId: 'demo-src-local',
        apiKey: 'demo-api-key',
      ),
      isTrue,
    );
    expect(
      AppEnv.isPlaceholderFirebaseConfig(
        projectId: 'sharerun-prod',
        apiKey: 'AIza-real-looking-key',
      ),
      isFalse,
    );
    expect(
      AppEnv.preferNativeFirebaseOptions(
        debugMode: false,
        placeholder: true,
        emulator: false,
      ),
      isTrue,
    );
    expect(
      AppEnv.preferNativeFirebaseOptions(
        debugMode: true,
        placeholder: true,
        emulator: false,
      ),
      isFalse,
    );
  });
}
