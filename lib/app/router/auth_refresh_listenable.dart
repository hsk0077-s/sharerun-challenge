import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Stream<User?> authStateStream) {
    _subscription = authStateStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class SessionRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
