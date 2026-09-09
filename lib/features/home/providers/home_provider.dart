import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_env.dart';
import '../../../data/local/mock_demo_data.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/models/user_model.dart';

UserModel _emptyDashboardUser({String uid = ''}) {
  return UserModel.dashboardDefault(uid: uid);
}

/// Live Firestore user profile for the main dashboard.
///
/// Missing / malformed `users/{uid}` docs yield a zeroed [UserModel] instead of
/// an [AsyncError], and optionally seed Firestore for brand-new users.
final userProfileProvider = StreamProvider<UserModel>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.userProfile());
  }

  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(_emptyDashboardUser());
      }

      final uid = user.uid;
      // Best-effort seed so subsequent reads see a real document.
      unawaited(() async {
        try {
          await ref.read(userRepositoryProvider).ensureUserDocument(uid: uid);
        } catch (e) {
          debugPrint('ensureUserDocument failed: $e');
        }
      }());

      return ref
          .watch(userRepositoryProvider)
          .watchUserProfile(uid)
          .transform(
            StreamTransformer<UserModel, UserModel>.fromHandlers(
              handleData: (profile, sink) => sink.add(profile),
              handleError: (error, stack, sink) {
                debugPrint('userProfileProvider stream error: $error');
                sink.add(_emptyDashboardUser(uid: uid));
              },
            ),
          );
    },
    loading: () => Stream.value(_emptyDashboardUser()),
    error: (error, stack) {
      debugPrint('userProfileProvider auth error: $error');
      return Stream.value(_emptyDashboardUser());
    },
  );
});

/// Active / recruiting challenge rooms shown on the main dashboard.
final activeTournamentsProvider = StreamProvider<List<TournamentModel>>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.tournaments());
  }
  return ref.watch(tournamentRepositoryProvider).watchTournamentRooms().transform(
        StreamTransformer<List<TournamentModel>, List<TournamentModel>>.fromHandlers(
          handleData: (rooms, sink) => sink.add(rooms),
          handleError: (error, stack, sink) {
            debugPrint('activeTournamentsProvider error: $error');
            sink.add(const <TournamentModel>[]);
          },
        ),
      );
});
