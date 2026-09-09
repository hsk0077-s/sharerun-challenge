enum IapUiKind {
  pending,
  verifying,
  verified,
  error,
  canceled,
  unavailable,
}

class IapUiEvent {
  const IapUiEvent({
    required this.kind,
    required this.message,
    this.shareAmount = 0,
    this.purchaseDocId,
  });

  final IapUiKind kind;
  final String message;
  final int shareAmount;
  final String? purchaseDocId;

  bool get isVerified => kind == IapUiKind.verified;
}
