import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'UserProfileNotifier.build does not throw when auth is still loading',
    () {
      final container = ProviderContainer(
        overrides: [
          // Cold-start relaunch: Firebase auth stream has not emitted yet.
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
          activeUserProfileProvider.overrideWith(
            (ref) => Stream.value(UserModel.dashboardDefault(uid: '')),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(userProfileNotifierProvider),
        returnsNormally,
      );
      expect(container.read(userProfileNotifierProvider).uid, isEmpty);
    },
  );
}
