/// Server-confirmed personal sponsor (angel) donation.
class PersonalSponsorDonation {
  const PersonalSponsorDonation({
    required this.status,
    required this.shareSpent,
    required this.donationCount,
    required this.cumulativeDonationAmount,
    required this.angelTierCode,
    required this.isSponsored,
    this.shareBalance,
    this.diamondBalance,
    this.valueTokenBalance,
  });

  final String status;
  final int shareSpent;
  final int donationCount;
  final int cumulativeDonationAmount;
  final String angelTierCode;
  final bool isSponsored;
  final int? shareBalance;
  final int? diamondBalance;
  final int? valueTokenBalance;

  factory PersonalSponsorDonation.fromJson(Map<String, dynamic> json) {
    return PersonalSponsorDonation(
      status: json['status'] as String? ?? '',
      shareSpent: _readInt(json['share_spent']) ?? 0,
      donationCount: _readInt(json['donation_count']) ?? 0,
      cumulativeDonationAmount:
          _readInt(json['cumulative_donation_amount']) ?? 0,
      angelTierCode: json['angel_tier_code'] as String? ?? 'pre_angel',
      isSponsored: json['is_sponsored'] == true,
      shareBalance: _readInt(json['share_balance']),
      diamondBalance: _readInt(json['diamond_balance']),
      valueTokenBalance: _readInt(json['value_token_balance']),
    );
  }

  static int? _readInt(Object? value) {
    if (value is num) return value.toInt();
    return null;
  }
}
