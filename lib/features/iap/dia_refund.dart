import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crew/crew_membership.dart';

/// 환불 기간 안에 산 DIA 팩 한 건과, 지금 환불하면 얼마인지.
@immutable
class DiaPurchase {
  const DiaPurchase({
    required this.purchaseId,
    required this.productId,
    required this.priceKrw,
    required this.createdAt,
    required this.status,
    required this.eligible,
    required this.reason,
    required this.paidDia,
    required this.bonusRevoked,
    required this.bonusSpent,
    required this.refundKrw,
  });

  final String purchaseId;
  final String productId;
  final int priceKrw;
  final DateTime? createdAt;

  /// 비면 환불 전, `requested`(신청함) · `refunded`(환불됨).
  final String status;
  final bool eligible;

  /// 환불할 수 없는 까닭: `nothing_left` · `period_over` · `already_refunded` ...
  final String reason;
  final int paidDia;
  final int bonusRevoked;
  final int bonusSpent;
  final int refundKrw;

  factory DiaPurchase.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return DiaPurchase(
      purchaseId: json['purchase_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      priceKrw: n('price_krw'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      status: json['status'] as String? ?? '',
      eligible: json['eligible'] == true,
      reason: json['reason'] as String? ?? '',
      paidDia: n('paid_dia'),
      bonusRevoked: n('bonus_revoked'),
      bonusSpent: n('bonus_spent'),
      refundKrw: n('refund_krw'),
    );
  }

  /// `dia_pack_130` → 130
  int get packDia => int.tryParse(productId.split('_').last) ?? 0;
}

@immutable
class DiaRefundResult {
  const DiaRefundResult({
    required this.status,
    required this.refundKrw,
    required this.playRefunded,
  });

  /// `refunded`(구글 플레이가 바로 돌려줌) 또는 `refund_requested`(담당자 확인 대기).
  final String status;
  final int refundKrw;
  final bool playRefunded;

  bool get done => status == 'refunded';
}

class DiaPurchases {
  const DiaPurchases({this.refundDays = 7, this.purchases = const []});

  final int refundDays;
  final List<DiaPurchase> purchases;
}

/// 서버에 닿지 못하면 null(서버 연결 전에는 환불 목록을 못 본다).
final diaPurchasesProvider = FutureProvider.autoDispose<DiaPurchases?>((ref) async {
  final api = ref.watch(crewApiProvider);
  if (api == null) return null;
  try {
    return await api.diaPurchases();
  } catch (_) {
    return null;
  }
});
