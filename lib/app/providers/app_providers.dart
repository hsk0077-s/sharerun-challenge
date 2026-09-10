import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../core/auth/local_auth_session.dart';
import '../../core/auth/local_auth_store.dart';
import '../../data/api/secured_action_api_client.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/firestore_service.dart';
import '../../data/firebase/push_notification_service.dart';
import '../../data/local/mock_demo_data.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/crew_member_ranking_model.dart';
import '../../data/models/crew_ranking_model.dart';
import '../../data/models/diamond_box_model.dart';
import '../../data/models/payment_intent_status_model.dart';
import '../../data/models/sponsor_live_buff_model.dart';
import '../../data/models/tournament_model.dart';
import '../../data/models/tournament_participation_model.dart';
import '../../data/models/economy_state_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../data/repositories/activity_repository.dart';
import '../../features/appeal/appeal_repository.dart';
import '../../data/repositories/crew_repository.dart';
import '../../data/repositories/diamond_box_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../features/jena_validation/services/activity_validation_service.dart';
import '../../features/run_tracking/services/abusing_defense_sensor_skeleton.dart';
import '../../features/run_tracking/services/accelerometer_collector_service.dart';
import '../../features/run_tracking/services/gps_tracking_service.dart';
import '../../features/run_tracking/services/gyro_stability_service.dart';
import '../../features/run_tracking/services/health_data_service.dart';
import '../../features/run_tracking/services/run_session_service.dart';
import '../../features/run_tracking/services/watch_runtime_permissions_service.dart';
import '../../features/watch_link/services/garmin_cloud_oauth_adapter.dart';
import '../../features/watch_link/services/watch_link_telemetry_service.dart';

UserModel _emptyUserProfile() {
  return UserModel(
    uid: '',
    watchType: WatchType.none,
    wallet: WalletModel.empty(),
    tier: 1,
    healthDataConsent: false,
    sensitiveDataConsent: false,
    termsAccepted: false,
    pushNotificationsEnabled: false,
    nickname: '',
    preliminaryRunsCount: 0,
    economy: EconomyStateModel.empty(),
  );
}

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(FirebaseMessaging.instance),
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(firebaseAuth: ref.watch(firebaseAuthProvider)),
);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(authServiceProvider).authStateChanges();
});

final localAuthStoreProvider = Provider<LocalAuthStore>(
  (ref) => LocalAuthStore(),
);

class PersistedAuthSessionNotifier extends Notifier<LocalAuthSession?> {
  LocalAuthSession? _seed;

  @override
  LocalAuthSession? build() => _seed;

  void seed(LocalAuthSession? session) {
    _seed = session;
  }

  void replace(LocalAuthSession? session) {
    state = session;
  }
}

/// Device-persisted session restored on cold start (SharedPreferences).
final persistedAuthSessionProvider =
    NotifierProvider<PersistedAuthSessionNotifier, LocalAuthSession?>(
  PersistedAuthSessionNotifier.new,
);

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(
    ref.watch(firestoreServiceProvider),
    ref.watch(securedActionApiClientProvider),
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(
    ref.watch(firestoreServiceProvider),
    securedActionApiClient: ref.watch(securedActionApiClientProvider),
  ),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(firestoreServiceProvider)),
);

final appealRepositoryProvider = Provider<AppealRepository>(
  (ref) => AppealRepository(ref.watch(firestoreServiceProvider)),
);

final diamondBoxRepositoryProvider = Provider<DiamondBoxRepository>(
  (ref) => DiamondBoxRepository(
    ref.watch(firestoreServiceProvider),
    ref.watch(securedActionApiClientProvider),
  ),
);

final crewRepositoryProvider = Provider<CrewRepository>(
  (ref) => CrewRepository(ref.watch(firestoreServiceProvider)),
);

final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => TournamentRepository(
    ref.watch(firestoreServiceProvider),
    ref.watch(securedActionApiClientProvider),
  ),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(firestoreServiceProvider)),
);

final rewardRepositoryProvider = Provider<RewardRepository>(
  (ref) => RewardRepository(ref.watch(securedActionApiClientProvider)),
);

final activeUserTierProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(1);
      }
      return ref.watch(userRepositoryProvider).watchUserTier(user.uid);
    },
    loading: () => Stream.value(1),
    error: (_, __) => Stream.value(1),
  );
});

final activeUserProfileProvider = StreamProvider<UserModel>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.userProfile());
  }

  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(_emptyUserProfile());
      }
      return ref.watch(userRepositoryProvider).watchUserProfile(user.uid);
    },
    loading: () => Stream.value(_emptyUserProfile()),
    error: (_, __) => Stream.value(_emptyUserProfile()),
  );
});

/// 미소명 Jena 보류 세션이 1건 이상일 때 마이페이지 탭 Red Dot.
final hasPendingJenaAppealProvider = Provider<bool>((ref) {
  final activities =
      ref.watch(recentActivitiesProvider).asData?.value ?? const [];
  return activities.any((activity) => activity.needsJenaAppeal);
});

final recentActivitiesProvider = StreamProvider<List<ActivityModel>>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(
      ActivityModel.withLatestForcedPending(MockDemoData.activities()),
    );
  }

  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const []);
      }
      return ref.watch(activityRepositoryProvider).watchRecentActivities(user.uid).map(
            ActivityModel.withLatestForcedPending,
          );
    },
    loading: () => Stream.value(const []),
    error: (_, __) => Stream.value(const []),
  );
});

final activeDiamondBoxesProvider = StreamProvider<List<DiamondBoxModel>>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.diamondBoxes());
  }
  return ref.watch(diamondBoxRepositoryProvider).watchActiveBoxes();
});

final topCrewsProvider = StreamProvider<List<CrewRankingModel>>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.crews());
  }
  return ref.watch(crewRepositoryProvider).watchTopCrews();
});

final crewMemberRankingsProvider =
    StreamProvider<List<CrewMemberRankingModel>>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.crewMemberRankings());
  }
  return Stream.value(const []);
});

final tournamentRoomsProvider = StreamProvider<List<TournamentModel>>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.tournaments());
  }
  return ref.watch(tournamentRepositoryProvider).watchTournamentRooms();
});

final tournamentByIdProvider =
    StreamProvider.family<TournamentModel?, String>((ref, tournamentId) {
  if (AppEnv.useLocalMockData) {
    TournamentModel? match;
    for (final room in MockDemoData.tournaments()) {
      if (room.id == tournamentId) {
        match = room;
        break;
      }
    }
    return Stream.value(match);
  }
  return ref.watch(tournamentRepositoryProvider).watchTournament(tournamentId);
});

final joinedTournamentIdsProvider = StreamProvider<Set<String>>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<String>{});
      }
      return ref.watch(tournamentRepositoryProvider).watchJoinedTournamentIds(user.uid);
    },
    loading: () => Stream.value(<String>{}),
    error: (_, __) => Stream.value(<String>{}),
  );
});

final joinedTournamentParticipationsProvider =
    StreamProvider<List<TournamentParticipationModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const []);
      }
      return ref
          .watch(tournamentRepositoryProvider)
          .watchJoinedParticipations(user.uid);
    },
    loading: () => Stream.value(const []),
    error: (_, __) => Stream.value(const []),
  );
});

final paymentIntentStatusProvider =
    StreamProvider.family<PaymentIntentStatusModel?, String>((ref, intentId) {
  return ref.watch(paymentRepositoryProvider).watchPaymentIntentStatus(intentId);
});

final activeWalletProvider = StreamProvider<WalletModel>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.userProfile().wallet);
  }

  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(WalletModel.empty());
      }
      return ref.watch(walletRepositoryProvider).watchWallet(user.uid);
    },
    loading: () => Stream.value(WalletModel.empty()),
    error: (_, __) => Stream.value(WalletModel.empty()),
  );
});

final recentWalletTransactionsProvider =
    StreamProvider<List<WalletTransactionModel>>((ref) {
  if (AppEnv.useLocalMockData) {
    return Stream.value(MockDemoData.walletTransactions());
  }

  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(const []);
      }
      return ref.watch(walletRepositoryProvider).watchRecentTransactions(user.uid);
    },
    loading: () => Stream.value(const []),
    error: (_, __) => Stream.value(const []),
  );
});

final activeEconomyStateProvider = StreamProvider<EconomyStateModel>((ref) {
  return ref.watch(activeUserProfileProvider).when(
        data: (profile) => Stream.value(profile.economy),
        loading: () => Stream.value(EconomyStateModel.empty()),
        error: (_, __) => Stream.value(EconomyStateModel.empty()),
      );
});

final jenaBaseUriProvider = Provider<Uri>((ref) {
  return Uri.parse(AppEnv.jenaBaseUrl);
});

final securedActionApiClientProvider = Provider<SecuredActionApiClient>(
  (ref) => SecuredActionApiClient(
    baseUri: ref.watch(jenaBaseUriProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  ),
);

final activityValidationServiceProvider = Provider<ActivityValidationService>(
  (ref) => ActivityValidationService(
    securedActionApiClient: ref.watch(securedActionApiClientProvider),
  ),
);

final gpsTrackingServiceProvider = Provider<GpsTrackingService>(
  (ref) => GpsTrackingService(),
);

final healthDataServiceProvider = Provider<HealthDataService>(
  (ref) => HealthDataService(),
);

final garminCloudOAuthAdapterProvider = Provider<GarminCloudOAuthAdapter>(
  (ref) => GarminCloudOAuthAdapter(),
);

final watchLinkTelemetryServiceProvider = Provider<WatchLinkTelemetryService>(
  (ref) {
    final service = WatchLinkTelemetryService(
      healthDataService: ref.watch(healthDataServiceProvider),
    );
    ref.onDispose(service.dispose);
    return service;
  },
);

final jenaPipelineReadyEventsProvider =
    StreamProvider<JenaPipelineReadyEvent>((ref) {
  return ref.watch(watchLinkTelemetryServiceProvider).readyEvents;
});

final watchRuntimePermissionsServiceProvider =
    Provider<WatchRuntimePermissionsService>(
  (ref) => WatchRuntimePermissionsService(
    healthDataService: ref.watch(healthDataServiceProvider),
  ),
);

final gyroStabilityServiceProvider = Provider.autoDispose<GyroStabilityService>(
  (ref) {
    final service = GyroStabilityService();
    ref.onDispose(() {
      unawaited(service.stop());
    });
    return service;
  },
);

final accelerometerCollectorServiceProvider =
    Provider.autoDispose<AccelerometerCollectorService>(
  (ref) {
    final service = AccelerometerCollectorService();
    ref.onDispose(() {
      unawaited(service.stop());
    });
    return service;
  },
);

final runSessionServiceProvider = Provider.autoDispose<RunSessionService>(
  (ref) {
    final service = RunSessionService(
      gpsTrackingService: ref.watch(gpsTrackingServiceProvider),
      healthDataService: ref.watch(healthDataServiceProvider),
      gyroStabilityService: ref.watch(gyroStabilityServiceProvider),
      accelerometerCollectorService:
          ref.watch(accelerometerCollectorServiceProvider),
    );
    ref.onDispose(() {
      unawaited(service.dispose());
    });
    return service;
  },
);

final activeSponsorBuffProvider = Provider<SponsorLiveBuffModel?>((ref) {
  if (AppEnv.useLocalMockData) {
    return MockDemoData.activeSponsorBuff();
  }
  return null;
});

/// [3단계] 어뷰징 방어 센서 스켈레톤 (휘발성 수집 → 검증 후 폐기).
final abusingDefenseSensorSkeletonProvider =
    Provider.autoDispose<AbusingDefenseSensorSkeleton>((ref) {
  return AbusingDefenseSensorSkeleton(
    gpsTrackingService: ref.watch(gpsTrackingServiceProvider),
    healthDataService: ref.watch(healthDataServiceProvider),
    gyroStabilityService: ref.watch(gyroStabilityServiceProvider),
  );
});
