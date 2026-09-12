import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/stamp/providers/stamp_tour_provider.dart';
import 'package:share_run_challenge/features/stamp/stamp_landmark_catalog.dart';

const _remoteNamsan = StampLandmark(
  id: 'namsan-remote',
  name: 'Namsan remote',
  latitude: 37.5512,
  longitude: 126.9882,
  isVisited: false,
  origin: StampLandmarkOrigin.officialRemote,
);

const _nearbyCafe = StampLandmark(
  id: 'osm-cafe',
  name: 'Nearby cafe',
  latitude: 37.55,
  longitude: 126.99,
  isVisited: false,
  origin: StampLandmarkOrigin.nearbyAuto,
);

const _userBench = StampLandmark(
  id: 'user-bench',
  name: 'Crew bench',
  latitude: 37.54,
  longitude: 126.98,
  isVisited: false,
  diamondReward: 1,
  origin: StampLandmarkOrigin.userProposal,
);

class _NearbySource implements NearbyPoiStampLandmarkSource {
  @override
  Future<List<StampLandmark>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 1500,
  }) async {
    return const [_nearbyCafe];
  }
}

class _ProposalSource implements StampProposalSource {
  @override
  Future<List<StampLandmark>> loadPersonal({required String uid}) async {
    return uid == 'crew-1' ? const [_userBench] : const [];
  }
}

void main() {
  test('empty remote catalog falls back to the Seoul seed set', () async {
    const catalog = StampLandmarkCatalog(
      remote: MemoryOfficialLandmarkSource([]),
    );

    final loaded = await catalog.load();
    expect(
      loaded.map((landmark) => landmark.id),
      SeedStampLandmarkCatalog.seoulDemo.map((landmark) => landmark.id),
    );
    expect(
      loaded.every((landmark) => landmark.origin == StampLandmarkOrigin.officialSeed),
      isTrue,
    );
    expect(loaded.every((landmark) => landmark.awardsOfficialDia), isTrue);
  });

  test('non-empty remote catalog replaces the seed list', () async {
    const catalog = StampLandmarkCatalog(
      remote: MemoryOfficialLandmarkSource([_remoteNamsan]),
    );

    final loaded = await catalog.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'namsan-remote');
    expect(loaded.single.origin, StampLandmarkOrigin.officialRemote);
    expect(loaded.single.awardsOfficialDia, isTrue);
  });

  test('nearby POI and user proposals overlay without replacing official', () async {
    final catalog = StampLandmarkCatalog(
      remote: const MemoryOfficialLandmarkSource([_remoteNamsan]),
      nearby: _NearbySource(),
      proposals: _ProposalSource(),
    );

    final loaded = await catalog.load(
      latitude: 37.55,
      longitude: 126.99,
      uid: 'crew-1',
    );
    expect(loaded.map((landmark) => landmark.id), [
      'namsan-remote',
      'osm-cafe',
      'user-bench',
    ]);
    expect(loaded[1].awardsOfficialDia, isTrue);
    expect(loaded[2].awardsOfficialDia, isFalse);
    expect(loaded[2].isPersonalStamp, isTrue);
  });

  test('personal origins never award official DIA', () {
    expect(
      const StampLandmark(
        id: 'u',
        name: 'User pin',
        latitude: 1,
        longitude: 1,
        isVisited: false,
        origin: StampLandmarkOrigin.userProposal,
      ).awardsOfficialDia,
      isFalse,
    );
    expect(
      const StampLandmark(
        id: 'c',
        name: 'Crew pin',
        latitude: 1,
        longitude: 1,
        isVisited: false,
        origin: StampLandmarkOrigin.crewProposal,
      ).awardsOfficialDia,
      isFalse,
    );
  });

  test('stamp mission completion ignores leftover personal stamps', () {
    const official = StampLandmark(
      id: 'gangbyeon',
      name: '강변 공원',
      latitude: 37.5283,
      longitude: 126.9326,
      isVisited: true,
      origin: StampLandmarkOrigin.officialSeed,
    );
    const personal = StampLandmark(
      id: 'user-bench',
      name: 'Crew bench',
      latitude: 37.54,
      longitude: 126.98,
      isVisited: false,
      origin: StampLandmarkOrigin.userProposal,
    );
    const state = StampTourState(
      landmarks: [official, personal],
      walkMissionCompleted: false,
      walkDistanceKm: 0,
      claiming: false,
      walkOfficialDiaPending: false,
      pendingOfficialRewardIds: {'gangbyeon'},
    );

    expect(state.officialLandmarks, hasLength(1));
    expect(state.stampMissionCompleted, isTrue);
    expect(state.officialStampDiaPending, isTrue);
    expect(personal.awardsOfficialDia, isFalse);
  });

  test('remote JSON accepts lat/lng aliases and origin codes', () {
    final parsed = StampLandmark.fromJson({
      'id': 'hangang',
      'name': '한강',
      'lat': '37.527',
      'lon': 126.934,
      'dia': 2,
      'origin': 'config',
    });
    expect(parsed.id, 'hangang');
    expect(parsed.latitude, 37.527);
    expect(parsed.longitude, 126.934);
    expect(parsed.diamondReward, 2);
    expect(parsed.origin, StampLandmarkOrigin.officialRemote);
    expect(parsed.awardsOfficialDia, isTrue);
  });
}
