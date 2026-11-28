import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../app/router/route_names.dart';
import '../repositories/user_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background push received: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  static String tournamentTopic(String tournamentId) {
    return 'tournament_$tournamentId';
  }

  /// Where a tapped push opens, from its data payload. Only known push types
  /// open a screen; any other payload opens nothing (the app just comes up).
  static String? routeForTap(Map<String, dynamic> data) {
    return switch (data['type']) {
      'friend_cheers' => RouteNames.cheerInbox,
      _ => null,
    };
  }

  /// Calls [open] with the route of a push the user tapped: the one that
  /// launched the app, and every later one while it runs.
  Future<void> listenForOpenedPushes(void Function(String route) open) async {
    void handle(RemoteMessage message) {
      final route = routeForTap(message.data);
      if (route != null) open(route);
    }

    final initial = await _messaging.getInitialMessage();
    if (initial != null) handle(initial);
    FirebaseMessaging.onMessageOpenedApp.listen(handle);
  }

  Future<void> initializeForegroundHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'Foreground push: ${message.notification?.title ?? message.messageId}',
      );
    });
  }

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// 이 기기의 푸시 토큰. 없거나 오래 걸리면 null.
  Future<String?> currentToken() async {
    try {
      return await _messaging.getToken().timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  Future<void> syncTokenForUser({
    required String uid,
    required UserRepository userRepository,
    bool requestPermission = false,
  }) async {
    if (requestPermission) {
      final granted = await this.requestPermission();
      if (!granted) {
        await userRepository.updatePushSettings(uid: uid, enabled: false);
        return;
      }
    }

    final token = await _messaging.getToken();
    if (token == null) {
      return;
    }

    await userRepository.updatePushSettings(
      uid: uid,
      enabled: true,
      fcmToken: token,
    );
  }

  void listenForTokenRefresh({
    required String uid,
    required UserRepository userRepository,
  }) {
    _messaging.onTokenRefresh.listen((token) {
      userRepository.updatePushSettings(
        uid: uid,
        enabled: true,
        fcmToken: token,
      );
    });
  }

  Future<void> subscribeToTournament(String tournamentId) {
    return _messaging.subscribeToTopic(tournamentTopic(tournamentId));
  }

  Future<void> unsubscribeFromTournament(String tournamentId) {
    return _messaging.unsubscribeFromTopic(tournamentTopic(tournamentId));
  }

  Future<void> syncTournamentTopics(Set<String> tournamentIds) async {
    for (final tournamentId in tournamentIds) {
      await subscribeToTournament(tournamentId);
    }
  }

  Future<void> clearTournamentTopics(Set<String> tournamentIds) async {
    for (final tournamentId in tournamentIds) {
      await unsubscribeFromTournament(tournamentId);
    }
  }
}
