import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/data/firebase/push_notification_service.dart';

void main() {
  test('a tapped friend-cheer push opens the cheer inbox', () {
    expect(
      PushNotificationService.routeForTap(
        {'type': 'friend_cheers', 'route': '/friends/cheers'},
      ),
      RouteNames.cheerInbox,
    );
    expect(RouteNames.cheerInbox, '/friends/cheers');
  });

  test('an unknown push opens nothing, whatever route it names', () {
    expect(PushNotificationService.routeForTap({}), isNull);
    expect(
      PushNotificationService.routeForTap(
        {'type': 'other', 'route': '/wallet'},
      ),
      isNull,
    );
    expect(PushNotificationService.routeForTap({'route': '/friends/cheers'}), isNull);
  });
}
