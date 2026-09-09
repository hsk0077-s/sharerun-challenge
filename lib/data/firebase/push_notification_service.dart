import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
