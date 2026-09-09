import 'package:firebase_auth/firebase_auth.dart';

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

/// Reads device-local guest login only — no Firebase or network calls.
abstract final class AuthSessionBootstrap {
  static Future<AuthBootstrapResult> run() async {
    final store = LocalAuthStore();
    var session = await store.read();

    if (session == null || session.uid.isEmpty) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
        session = LocalAuthSession(
          uid: firebaseUser.uid,
          isGuest: firebaseUser.isAnonymous,
        );
        await store.saveSession(
          uid: session.uid,
          isGuest: session.isGuest,
        );
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
