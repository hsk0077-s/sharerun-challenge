import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/watch_link/services/garmin_cloud_oauth_adapter.dart';

void main() {
  test('a release build never hands out a mock Garmin session', () async {
    final adapter = GarminCloudOAuthAdapter(enabled: false);
    expect(
      () => adapter.authorize(email: 'a@b.co', password: 'secret'),
      throwsA(isA<GarminOAuthException>()),
    );
  });

  test('the debug mock still works for development', () async {
    final session = await GarminCloudOAuthAdapter(enabled: true)
        .authorize(email: 'a@b.co', password: 'secret');
    expect(session.accessToken, startsWith('garmock_'));
  });
}
