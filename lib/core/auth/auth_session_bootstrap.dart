import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../app/router/route_names.dart';
import 'local_auth_session.dart';
import 'local_auth_store.dart';

class AuthBootstrapResult {
  const AuthBootstrapResult({
    required this.initialRoute,
    required this.session,
  });

  final String initialRoute;
  final LocalAuthSession? session;
}

/// What Firebase says about the signed-in user right now.
/// [known] is false when Firebase cannot be asked (not started, or too slow).
typedef FirebaseUserProbe = Future<({bool known, String uid, bool anonymous})>
    Function();

Future<({bool known, String uid, bool anonymous})> _probeFirebaseUser() async {
  if (Firebase.apps.isEmpty) return (known: false, uid: '', anonymous: false);
  try {
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 3));
    return (
      known: true,
      uid: user?.uid ?? '',
      anonymous: user?.isAnonymous ?? false
    );
  } catch (e) {
    debugPrint('AuthSessionBootstrap firebase user: $e');
    return (known: false, uid: '', anonymous: false);
  }
}

/// Decides the first screen. The server login (Firebase) is the truth: a
/// login note left on the phone is only trusted while Firebase agrees.
/// A phone that received the note without the login (for example from an
/// app-data restore) goes to the login screen instead of an empty home.
abstract final class AuthSessionBootstrap {
  static Future<AuthBootstrapResult> run({FirebaseUserProbe? probe}) async {
    final store = LocalAuthStore();
    var session = await store.read();

    final firebase = await (probe ?? _probeFirebaseUser)();
    if (firebase.known) {
      if (firebase.uid.isEmpty) {
        if (session != null) await store.clear();
        session = null;
      } else if (session == null || session.uid != firebase.uid) {
        session = LocalAuthSession(
          uid: firebase.uid,
          isGuest: firebase.anonymous,
        );
        await store.saveSession(uid: session.uid, isGuest: session.isGuest);
      }
    }

    if (session == null || session.uid.isEmpty) {
      return const AuthBootstrapResult(
        initialRoute: RouteNames.login,
        session: null,
      );
    }

    return AuthBootstrapResult(
      initialRoute: RouteNames.home,
      session: session,
    );
  }
}
