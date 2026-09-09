enum PaymentIntentType {
  shareTopUp,
  sponsorSupport,
}

class PaymentIntentModel {
  const PaymentIntentModel({
    required this.id,
    required this.type,
    required this.amountKrw,
    required this.pgUrl,
  });

  final String id;
  final PaymentIntentType type;
  final int amountKrw;
  final Uri pgUrl;
}
