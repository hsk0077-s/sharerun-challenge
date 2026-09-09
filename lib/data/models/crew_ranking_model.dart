class CrewRankingModel {
  const CrewRankingModel({
    required this.id,
    required this.name,
    required this.totalValue,
    required this.memberCount,
  });

  final String id;
  final String name;
  final int totalValue;
  final int memberCount;

  factory CrewRankingModel.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    return CrewRankingModel(
      id: id,
      name: json['name'] as String? ?? 'SRC Crew',
      totalValue: (json['totalValue'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}
