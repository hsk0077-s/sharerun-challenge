class PaymentIntentStatusModel {
  const PaymentIntentStatusModel({
    required this.id,
    required this.status,
    required this.type,
  });

  final String id;
  final String status;
  final String type;

  bool get isCredited => status == 'credited';

  bool get isPending => status == 'created';

  bool get isTerminalFailure {
    return status == 'amount_mismatch' || status.startsWith('pg_');
  }

  String get userMessage {
    return switch (status) {
      'credited' => '결제가 확인되어 잔액에 반영되었습니다.',
      'created' => 'PG 결제를 완료하면 자동으로 확인됩니다.',
      'amount_mismatch' => '결제 금액이 일치하지 않습니다.',
      _ when status.startsWith('pg_') => 'PG에서 결제가 완료되지 않았습니다.',
      _ => '결제 상태: $status',
    };
  }

  factory PaymentIntentStatusModel.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return PaymentIntentStatusModel(
      id: id,
      status: data['status'] as String? ?? 'created',
      type: data['type'] as String? ?? 'unknown',
    );
  }
}
