enum SponsorPaymentOption {
  directPrizeSupport,
  winnerNamedCharityDonation,
}

extension SponsorPaymentOptionCode on SponsorPaymentOption {
  String get code {
    return switch (this) {
      SponsorPaymentOption.directPrizeSupport => 'direct_prize_support',
      // The code is a wire value (firestore.rules and the payment webhook
      // check it, and older apps send it). Rename the enum, not this string.
      SponsorPaymentOption.winnerNamedCharityDonation =>
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
