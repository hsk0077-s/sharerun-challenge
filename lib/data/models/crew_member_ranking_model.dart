class CrewMemberRankingModel {
  const CrewMemberRankingModel({
    required this.id,
    required this.name,
    required this.attendanceRate,
    required this.averagePaceSecondsPerKm,
    required this.weeklyDistanceKm,
  });

  final String id;
  final String name;
  final double attendanceRate;
  final double averagePaceSecondsPerKm;
  final double weeklyDistanceKm;

  String get formattedPace {
    final pace = averagePaceSecondsPerKm;
    if (pace <= 0) {
      return '—';
    }
    final minutes = pace ~/ 60;
    final seconds = (pace % 60).round().clamp(0, 59);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory CrewMemberRankingModel.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    return CrewMemberRankingModel(
      id: id,
      name: json['name'] as String? ?? 'Crew Member',
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0,
      averagePaceSecondsPerKm:
          (json['averagePaceSecondsPerKm'] as num?)?.toDouble() ?? 0,
      weeklyDistanceKm: (json['weeklyDistanceKm'] as num?)?.toDouble() ?? 0,
    );
  }
}
