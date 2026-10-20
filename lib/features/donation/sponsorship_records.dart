import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crew/crew_membership.dart';

/// 모두에게 보이는 후원 현황. 후원한 사람이 [minSponsors]명이 되기 전에는 금액이 비어 있다.
@immutable
class SponsorshipSummary {
  const SponsorshipSummary({
    this.sponsorCount = 0,
    this.showAmounts = false,
    this.minSponsors = 5,
    this.totalWon,
    this.monthWon,
    this.monthCount,
  });

  final int sponsorCount;
  final bool showAmounts;
  final int minSponsors;
  final int? totalWon;
  final int? monthWon;
  final int? monthCount;

  factory SponsorshipSummary.fromJson(Map<String, dynamic> json) {
    int? n(String key) => (json[key] as num?)?.toInt();
    return SponsorshipSummary(
      sponsorCount: n('sponsor_count') ?? 0,
      showAmounts: json['show_amounts'] == true,
      minSponsors: n('min_sponsors') ?? 5,
      totalWon: n('total_won'),
      monthWon: n('month_won'),
      monthCount: n('month_count'),
    );
  }
}

/// 내 후원 한 건. 나만 볼 수 있다.
@immutable
class SponsorshipEntry {
  const SponsorshipEntry({
    required this.purpose,
    required this.share,
    required this.won,
    required this.createdAt,
  });

  /// `donation`(기부 후원) 또는 `prize`(상금 후원)
  final String purpose;
  final int share;
  final int won;
  final DateTime? createdAt;

  bool get isDonation => purpose == 'donation';
}

@immutable
class MySponsorship {
  const MySponsorship({
    this.entries = const [],
    this.donationCount = 0,
    this.donationWon = 0,
  });

  final List<SponsorshipEntry> entries;
  final int donationCount;
  final int donationWon;

  factory MySponsorship.fromJson(Map<String, dynamic> json) {
    final list = json['entries'];
    return MySponsorship(
      entries: [
        if (list is List)
          for (final e in list)
            if (e is Map<String, dynamic>)
              SponsorshipEntry(
                purpose: e['purpose'] as String? ?? 'donation',
                share: (e['share'] as num?)?.toInt() ?? 0,
                won: (e['won'] as num?)?.toInt() ?? 0,
                createdAt: DateTime.tryParse(e['created_at'] as String? ?? ''),
              ),
      ],
      donationCount: (json['donation_count'] as num?)?.toInt() ?? 0,
      donationWon: (json['donation_won'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 서버에 닿지 못하면 null(그러면 화면은 현황 줄을 숨긴다).
final sponsorshipSummaryProvider =
    FutureProvider.autoDispose<SponsorshipSummary?>((ref) async {
  final api = ref.watch(crewApiProvider);
  if (api == null) return null;
  try {
    return await api.sponsorshipSummary();
  } catch (_) {
    return null;
  }
});

final mySponsorshipProvider = FutureProvider.autoDispose<MySponsorship?>((ref) async {
  final api = ref.watch(crewApiProvider);
  if (api == null) return null;
  try {
    return await api.mySponsorship();
  } catch (_) {
    return null;
  }
});
