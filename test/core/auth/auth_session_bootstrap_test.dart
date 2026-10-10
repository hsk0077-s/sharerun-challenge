import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/auth/auth_session_bootstrap.dart';
import 'package:share_run_challenge/core/auth/local_auth_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

FirebaseUserProbe _firebase(String uid, {bool known = true}) =>
    () async => (known: known, uid: uid, anonymous: false);

Future<void> _seed(String? uid) async {
  SharedPreferences.setMockInitialValues(
    uid == null
        ? {}
        : {'src.auth.logged_in': true, 'src.auth.uid': uid},
  );
}

void main() {
  test('a note on the phone without a Firebase login goes to login', () async {
    await _seed('uid-from-another-phone');
    final result = await AuthSessionBootstrap.run(probe: _firebase(''));
    expect(result.initialRoute, RouteNames.login);
    expect(result.session, isNull);
    expect(await LocalAuthStore().read(), isNull); // the stale note is removed
  });

  test('note and Firebase login agree: straight to home', () async {
    await _seed('u1');
    final result = await AuthSessionBootstrap.run(probe: _firebase('u1'));
    expect(result.initialRoute, RouteNames.home);
    expect(result.session?.uid, 'u1');
  });

  test('a note for another account follows the real Firebase login', () async {
    await _seed('old');
    final result = await AuthSessionBootstrap.run(probe: _firebase('new'));
    expect(result.initialRoute, RouteNames.home);
    expect(result.session?.uid, 'new');
    expect((await LocalAuthStore().read())?.uid, 'new');
  });

  test('Firebase logged in but no note: home (note is written)', () async {
    await _seed(null);
    final result = await AuthSessionBootstrap.run(probe: _firebase('u2'));
    expect(result.initialRoute, RouteNames.home);
    expect((await LocalAuthStore().read())?.uid, 'u2');
  });

  test('nothing anywhere: login', () async {
    await _seed(null);
    final result = await AuthSessionBootstrap.run(probe: _firebase(''));
    expect(result.initialRoute, RouteNames.login);
  });

  test('when Firebase cannot be asked the saved note is kept', () async {
    await _seed('u1');
    final result =
        await AuthSessionBootstrap.run(probe: _firebase('', known: false));
    expect(result.initialRoute, RouteNames.home);
    expect(result.session?.uid, 'u1');
    expect((await LocalAuthStore().read())?.uid, 'u1');
  });
}
