import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';

void main() {
  test('golden-hour copy uses 5km / 50 SRV and walks to solo pedometer', () {
    final profile = UserModel.dashboardDefault(uid: 'u1').copyWith(
      preferredRunHour: 19,
    );
    final now = DateTime(2026, 9, 12, 19, 10);
    final payloads = RetentionAlertEngine.evaluate(
      profile: profile,
      activities: const [],
      now: now,
      dailyKm: 0,
      shoeKm: 0,
    );

    final golden = payloads.singleWhere((p) => p.code == 'golden_hour');
    expect(golden.body, contains('5km'));
    expect(golden.body, contains('50 SRV'));
    expect(golden.body, isNot(contains('500원')));
    expect(golden.routeName, RouteNames.soloPedometer);
  });
}
