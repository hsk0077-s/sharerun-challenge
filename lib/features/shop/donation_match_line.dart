/// Company won added for this user. VALUE spent is not won.
String donationMatchContributionLine({
  required String sponsorName,
  required String contributorName,
  required int companyWon,
}) {
  final sponsor = sponsorName.trim();
  if (sponsor.isEmpty || companyWon <= 0) return '';
  final name = contributorName.trim().isEmpty ? '회원' : contributorName.trim();
  return '$sponsor 명의 ${_grouped(companyWon)}원 · $name 기여';
}

/// Sum of this month's company matches, shown under the company name.
String donationMatchSummary(
  List<DonationMatchEntry> entries,
  String monthKey,
) {
  final month = [
    for (final entry in entries)
      if (entry.monthKey == monthKey && entry.companyWon > 0) entry,
  ];
  if (month.isEmpty) return '';
  final won = month.fold<int>(0, (sum, entry) => sum + entry.companyWon);
  final latest = month.last;
  return donationMatchContributionLine(
    sponsorName: latest.sponsorName,
    contributorName: latest.contributorName,
    companyWon: won,
  );
}

class DonationMatchEntry {
  const DonationMatchEntry({
    required this.sponsorName,
    required this.contributorName,
    required this.companyWon,
    required this.monthKey,
    required this.valueSpent,
  });

  final String sponsorName;
  final String contributorName;
  final int companyWon;
  final String monthKey;
  final int valueSpent;

  static DonationMatchEntry? fromDoc(Map<String, dynamic>? data) {
    if (data == null || data['type'] != 'donation_match') return null;
    final won = data['companyWon'];
    if (won is! num || won <= 0) return null;
    final spent = data['valueAmount'];
    return DonationMatchEntry(
      sponsorName: data['sponsorName'] as String? ?? '',
      contributorName: data['contributorName'] as String? ?? '',
      companyWon: won.toInt(),
      monthKey: data['monthKey'] as String? ?? '',
      valueSpent: spent is num ? spent.toInt().abs() : 0,
    );
  }
}

String _grouped(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
