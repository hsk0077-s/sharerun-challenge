import 'package:shared_preferences/shared_preferences.dart';

import 'local_auth_session.dart';

/// Persists guest login on device for auto-login on cold start.
class LocalAuthStore {
  static const _loggedInKey = 'src.auth.logged_in';
  static const _uidKey = 'src.auth.uid';
  static const _guestKey = 'src.auth.is_guest';

  Future<bool> hasGuestLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<LocalAuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (!loggedIn) {
      return null;
    }

    final uid = prefs.getString(_uidKey) ?? '';
    if (uid.isEmpty) {
      return null;
    }

    return LocalAuthSession(
      uid: uid,
      isGuest: prefs.getBool(_guestKey) ?? true,
    );
  }

  /// Issues a local-only guest UID and persists it — no server calls.
  Future<LocalAuthSession> signInAsLocalGuest() async {
    final uid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    await saveGuestLogin(uid: uid);
    return LocalAuthSession(uid: uid, isGuest: true);
  }

  Future<void> saveGuestLogin({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_uidKey, uid);
    await prefs.setBool(_guestKey, true);
  }

  Future<void> saveSession({
    required String uid,
    required bool isGuest,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_uidKey, uid);
    await prefs.setBool(_guestKey, isGuest);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_guestKey);
  }
}
