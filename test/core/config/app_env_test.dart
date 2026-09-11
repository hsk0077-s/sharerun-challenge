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
}
