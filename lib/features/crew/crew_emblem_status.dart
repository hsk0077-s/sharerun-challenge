import 'package:flutter/foundation.dart';

/// 서버가 알려 주는 엠블럼 상태: 해금한 테두리, 진행도, 산 유료 엠블럼, 바꿀 수 있는 시각.
@immutable
class CrewEmblemStatus {
  const CrewEmblemStatus({
    this.earnedBorders = const {},
    this.progress = const {},
    this.thresholds = const {},
    this.paidOwned = const {},
    this.paidPrices = const {},
    this.paidSaleEnabled = false,
    this.cooldownSeconds = 0,
  });

  final Set<String> earnedBorders;

  /// distance(km) · donation(원) · members(명) · ranking(월간 최고 순위, 0=없음)
  final Map<String, double> progress;

  /// 종류별 동·은·금 기준. ranking은 "이 순위 이내".
  final Map<String, List<int>> thresholds;
  final Set<String> paidOwned;
  final Map<String, int> paidPrices;
  final bool paidSaleEnabled;
  final int cooldownSeconds;

  factory CrewEmblemStatus.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? v) =>
        v is List ? [for (final e in v) if (e is String) e] : const [];
    return CrewEmblemStatus(
      earnedBorders: strings(json['earned_borders']).toSet(),
      progress: {
        if (json['progress'] is Map)
          for (final e in (json['progress'] as Map).entries)
            e.key as String: (e.value as num).toDouble(),
      },
      thresholds: {
        if (json['thresholds'] is Map)
          for (final e in (json['thresholds'] as Map).entries)
            e.key as String: [
              for (final n in e.value as List) (n as num).toInt(),
            ],
      },
      paidOwned: strings(json['paid_owned']).toSet(),
      paidPrices: {
        if (json['paid_prices'] is Map)
          for (final e in (json['paid_prices'] as Map).entries)
            e.key as String: (e.value as num).toInt(),
      },
      paidSaleEnabled: json['paid_sale_enabled'] == true,
      cooldownSeconds: (json['cooldown_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}
