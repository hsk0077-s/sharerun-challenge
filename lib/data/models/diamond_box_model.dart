class DiamondBoxModel {
  const DiamondBoxModel({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.rewardDiamond,
    required this.active,
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final int rewardDiamond;
  final bool active;

  factory DiamondBoxModel.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    return DiamondBoxModel(
      id: id,
      title: json['title'] as String? ?? 'Diamond Box',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      rewardDiamond: (json['rewardDiamond'] as num?)?.toInt() ?? 1,
      active: json['active'] as bool? ?? true,
    );
  }
}
