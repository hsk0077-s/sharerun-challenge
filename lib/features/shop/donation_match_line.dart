import 'package:flutter/widgets.dart';

/// Company won added for this user. VALUE spent is not won.
///
/// No locale keeps the Korean line the first screens shipped.
String donationMatchContributionLine({
  required String sponsorName,
  required String contributorName,
  required int companyWon,
  Locale? locale,
}) {
  final sponsor = sponsorName.trim();
  if (sponsor.isEmpty || companyWon <= 0) return '';
  final code = _line.containsKey(locale?.languageCode) ? locale!.languageCode : 'ko';
  final name = contributorName.trim().isEmpty ? _member[code]! : contributorName.trim();
  return _line[code]!
      .replaceAll('{sponsor}', sponsor)
      .replaceAll('{amount}', _grouped(companyWon))
      .replaceAll('{name}', name);
}

const _member = <String, String>{
  'ko': '회원',
  'en': 'member',
  'ja': '会員',
  'zh': '會員',
  'es': 'miembro',
  'pt': 'membro',
  'de': 'Mitglied',
  'fr': 'membre',
  'vi': 'thành viên',
  'th': 'สมาชิก',
  'id': 'anggota',
};

const _line = <String, String>{
  'ko': '{sponsor} 명의 {amount}원 · {name} 기여',
  'en': '{amount} KRW in {sponsor}\'s name · {name}',
  'ja': '{sponsor} の名義で {amount}ウォン · {name} の貢献',
  'zh': '以 {sponsor} 的名義 {amount} 韓元 · {name} 的貢獻',
  'es': '{amount} KRW a nombre de {sponsor} · aporte de {name}',
  'pt': '{amount} KRW em nome de {sponsor} · contribuição de {name}',
  'de': '{amount} KRW im Namen von {sponsor} · Beitrag von {name}',
  'fr': '{amount} KRW au nom de {sponsor} · apport de {name}',
  'vi': '{amount} KRW dưới tên {sponsor} · đóng góp của {name}',
  'th': '{amount} วอน ในนาม {sponsor} · ส่วนร่วมของ {name}',
  'id': '{amount} KRW atas nama {sponsor} · kontribusi {name}',
};

/// Sum of this month's company matches, shown under the company name.
String donationMatchSummary(
  List<DonationMatchEntry> entries,
  String monthKey, [
  Locale? locale,
]) {
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
    locale: locale,
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
