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
}
