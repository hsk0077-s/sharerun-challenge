import '../../core/strings/app_strings.dart';
import 'stamp_landmark.dart';

/// Small official Seoul demo set. Not a worldwide ops-curated catalog.
abstract final class SeedStampLandmarkCatalog {
  static const seoulDemo = <StampLandmark>[
    StampLandmark(
      id: 'gangbyeon',
      name: AppStrings.stampTourLandmarkGangbyeon,
      latitude: 37.5283,
      longitude: 126.9326,
      isVisited: false,
      diamondReward: 1,
      origin: StampLandmarkOrigin.officialSeed,
    ),
    StampLandmark(
      id: 'namsan',
      name: AppStrings.stampTourLandmarkNamsan,
      latitude: 37.5512,
      longitude: 126.9882,
      isVisited: false,
      diamondReward: 1,
      origin: StampLandmarkOrigin.officialSeed,
    ),
    StampLandmark(
      id: 'modoil',
      name: AppStrings.stampTourLandmarkModoil,
      latitude: 37.5443,
      longitude: 127.0374,
      isVisited: false,
      diamondReward: 1,
      origin: StampLandmarkOrigin.officialSeed,
    ),
  ];
}

/// Loads official + optional personal/nearby lists. Remote config replaces seed.
class StampLandmarkCatalog {
  const StampLandmarkCatalog({
    required this.remote,
    this.nearby = const DisabledNearbyPoiStampLandmarkSource(),
    this.proposals = const DisabledStampProposalSource(),
    this.seed = SeedStampLandmarkCatalog.seoulDemo,
  });

  final StampOfficialLandmarkSource remote;
  final NearbyPoiStampLandmarkSource nearby;
  final StampProposalSource proposals;
  final List<StampLandmark> seed;

  /// Official list is remote-if-present, else Seoul seed. Nearby/proposals
  /// are optional overlays and never replace official rewards.
  Future<List<StampLandmark>> load({
    double? latitude,
    double? longitude,
    String? uid,
  }) async {
    final remoteOfficial = await remote.loadOfficial();
    final official = remoteOfficial.isNotEmpty ? remoteOfficial : seed;
    final auto = (latitude != null && longitude != null)
        ? await nearby.fetchNearby(
            latitude: latitude,
            longitude: longitude,
          )
        : const <StampLandmark>[];
    final personal = uid == null || uid.isEmpty
        ? const <StampLandmark>[]
        : await proposals.loadPersonal(uid: uid);
    return [
      ...official,
      ...auto,
      ...personal,
    ].where(StampLandmark.isUsable).toList(growable: false);
  }
}

abstract class StampOfficialLandmarkSource {
  Future<List<StampLandmark>> loadOfficial();
}

/// In-memory / test source.
class MemoryOfficialLandmarkSource implements StampOfficialLandmarkSource {
  const MemoryOfficialLandmarkSource(this.landmarks);

  final List<StampLandmark> landmarks;

  @override
  Future<List<StampLandmark>> loadOfficial() async => landmarks;
}

/// Nearby auto POIs (OSM / Places). Empty until a provider is plugged in.
abstract class NearbyPoiStampLandmarkSource {
  Future<List<StampLandmark>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 1500,
  });
}

class DisabledNearbyPoiStampLandmarkSource
    implements NearbyPoiStampLandmarkSource {
  const DisabledNearbyPoiStampLandmarkSource();

  @override
  Future<List<StampLandmark>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 1500,
  }) async {
    return const [];
  }
}

/// User/crew proposed stamps. Personal only — no official DIA.
abstract class StampProposalSource {
  Future<List<StampLandmark>> loadPersonal({required String uid});
}

class DisabledStampProposalSource implements StampProposalSource {
  const DisabledStampProposalSource();

  @override
  Future<List<StampLandmark>> loadPersonal({required String uid}) async {
    return const [];
  }
}
