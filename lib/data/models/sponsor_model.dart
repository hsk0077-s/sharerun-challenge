enum SponsorPaymentOption {
  directPrizeSupport,
  winnerNamedUnicefDonation,
}

extension SponsorPaymentOptionCode on SponsorPaymentOption {
  String get code {
    return switch (this) {
      SponsorPaymentOption.directPrizeSupport => 'direct_prize_support',
      SponsorPaymentOption.winnerNamedUnicefDonation =>
        'winner_named_unicef_donation',
    };
  }
}

class SponsorPaymentIntent {
  const SponsorPaymentIntent({
    required this.uid,
    required this.sponsorId,
    required this.tournamentId,
    required this.amountShare,
    required this.option,
  });

  final String uid;
  final String sponsorId;
  final String tournamentId;
  final int amountShare;
  final SponsorPaymentOption option;
}
