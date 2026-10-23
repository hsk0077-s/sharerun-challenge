import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cold start without an auth user follows the persisted uid', () {
    expect(
      profileSubscriptionTarget(
        authResolved: false,
        authUid: null,
        persistedUid: 'previous',
      ),
      'previous',
    );
  });

  test('a signed-in user replaces the persisted uid', () {
    expect(
      profileSubscriptionTarget(
        authResolved: true,
        authUid: 'next',
        persistedUid: 'previous',
      ),
      'next',
    );
  });

  test('logout does not keep listening to the previous account', () {
    expect(
      profileSubscriptionTarget(
        authResolved: true,
        authUid: null,
        persistedUid: 'previous',
      ),
      isNull,
    );
    expect(
      profileSubscriptionTarget(
        authResolved: true,
        authUid: '',
        persistedUid: 'previous',
      ),
      isNull,
    );
  });

  test('permission-denied is logged only for the account still signed in', () {
    expect(
      shouldReportProfileSubscriptionError(
        subscribedUid: 'previous',
        liveAuthUid: null,
      ),
      isFalse,
    );
    expect(
      shouldReportProfileSubscriptionError(
        subscribedUid: 'previous',
        liveAuthUid: 'next',
      ),
      isFalse,
    );
    expect(
      shouldReportProfileSubscriptionError(
        subscribedUid: 'next',
        liveAuthUid: 'next',
      ),
      isTrue,
    );
    expect(
        isFirestorePermissionDenied(StateError('permission-denied')), isTrue);
    expect(isFirestorePermissionDenied(StateError('offline')), isFalse);
  });
}
