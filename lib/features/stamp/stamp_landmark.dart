import 'package:flutter/foundation.dart';

/// Who published the landmark. Official DIA is only for platform/seed/auto.
enum StampLandmarkOrigin {
  officialSeed,
  officialRemote,
  nearbyAuto,
  userProposal,
  crewProposal,
}

extension StampLandmarkOriginX on StampLandmarkOrigin {
  String get code => switch (this) {
        StampLandmarkOrigin.officialSeed => 'official_seed',
        StampLandmarkOrigin.officialRemote => 'official_remote',
        StampLandmarkOrigin.nearbyAuto => 'nearby_auto',
        StampLandmarkOrigin.userProposal => 'user_proposal',
        StampLandmarkOrigin.crewProposal => 'crew_proposal',
      };

  bool get isOfficial =>
      this == StampLandmarkOrigin.officialSeed ||
      this == StampLandmarkOrigin.officialRemote ||
      this == StampLandmarkOrigin.nearbyAuto;

  bool get isPersonal =>
      this == StampLandmarkOrigin.userProposal ||
      this == StampLandmarkOrigin.crewProposal;

  static StampLandmarkOrigin fromCode(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'official_remote' || 'remote' || 'config' =>
        StampLandmarkOrigin.officialRemote,
      'nearby_auto' || 'nearby' || 'poi' || 'osm' || 'places' =>
        StampLandmarkOrigin.nearbyAuto,
      'user_proposal' || 'user' || 'personal' =>
        StampLandmarkOrigin.userProposal,
      'crew_proposal' || 'crew' => StampLandmarkOrigin.crewProposal,
      _ => StampLandmarkOrigin.officialSeed,
    };
  }
}

@immutable
class StampLandmark {
  const StampLandmark({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isVisited,
    this.diamondReward = 1,
    this.origin = StampLandmarkOrigin.officialSeed,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isVisited;
  final int diamondReward;
  final StampLandmarkOrigin origin;

  /// Official DIA only for platform/seed and future auto POIs.
  bool get awardsOfficialDia => origin.isOfficial && diamondReward > 0;

  bool get isPersonalStamp => origin.isPersonal;

  StampLandmark copyWith({
    bool? isVisited,
    StampLandmarkOrigin? origin,
    int? diamondReward,
  }) {
    return StampLandmark(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      isVisited: isVisited ?? this.isVisited,
      diamondReward: diamondReward ?? this.diamondReward,
      origin: origin ?? this.origin,
    );
  }

  factory StampLandmark.fromJson(
    Map<String, dynamic> json, {
    StampLandmarkOrigin fallbackOrigin = StampLandmarkOrigin.officialRemote,
  }) {
    final id = (json['id'] as String? ?? '').trim();
    final name = (json['name'] as String? ?? '').trim();
    final lat = _coord(json['latitude'] ?? json['lat']);
    final lng = _coord(json['longitude'] ?? json['lng'] ?? json['lon']);
    final reward = (json['diamondReward'] as num?)?.toInt() ??
        (json['dia'] as num?)?.toInt() ??
        1;
    final rawOrigin = (json['origin'] ?? json['source']) as String?;
    final origin = rawOrigin == null || rawOrigin.trim().isEmpty
        ? fallbackOrigin
        : StampLandmarkOriginX.fromCode(rawOrigin);
    return StampLandmark(
      id: id,
      name: name,
      latitude: lat,
      longitude: lng,
      isVisited: json['isVisited'] == true,
      diamondReward: reward < 0 ? 0 : reward,
      origin: origin,
    );
  }

  static double _coord(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse('$raw') ?? 0;
  }

  static bool isUsable(StampLandmark landmark) {
    return landmark.id.isNotEmpty &&
        landmark.name.isNotEmpty &&
        landmark.latitude.isFinite &&
        landmark.longitude.isFinite;
  }
}
