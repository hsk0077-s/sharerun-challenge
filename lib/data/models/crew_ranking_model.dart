import '../../l10n/remaining_surface.dart';
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
      name: json['name'] as String? ?? RemainingSurface.trNow('crew_ranking_model.body', '쉐어런 크루'),
      totalValue: (json['totalValue'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}
