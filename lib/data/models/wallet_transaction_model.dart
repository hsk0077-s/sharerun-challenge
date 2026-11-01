import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/remaining_surface.dart';

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.shareAmount,
    required this.valueAmount,
    required this.diamondAmount,
    required this.createdAt,
    required this.tournamentId,
    this.itemId,
    this.ticketAmount = 0,
  });

  final String id;
  final String type;
  final int shareAmount;
  final int valueAmount;
  final int diamondAmount;
  final DateTime? createdAt;
  final String? tournamentId;
  final String? itemId;
  final int ticketAmount;

  String get displayLabel {
    if (type == 'shop_purchase' && itemId == 'rest_day_ticket') {
      return RemainingSurface.trNow('items.rest_day_ticket', '휴식일 지정권');
    }
    if (type == 'shop_item_use' && itemId == 'rest_day_ticket') {
      return RemainingSurface.trNow('wallet_transaction_model.body', '휴식일 지정');
    }
    return switch (type) {
      'share_top_up' => RemainingSurface.trNow('wallet_transaction_model.body.2', 'SHARE 충전'),
      'tournament_entry' => RemainingSurface.trNow('wallet_transaction_model.body.3', '대회 참가'),
      'tournament_prize_dia' => RemainingSurface.trNow('wallet_transaction_model.body.4', '대회 보너스 DIA'),
      'tournament_top_percent_share' => RemainingSurface.trNow('wallet_transaction_model.body.5', '대회 상위 완주 SHARE'),
      'tournament_finisher_value' => RemainingSurface.trNow('wallet_transaction_model.body.6', '대회 완주 VALUE'),
      'cash_refund_requested' => RemainingSurface.trNow('wallet_transaction_model.body.7', '현금 환불 요청'),
      'bep_refund' => RemainingSurface.trNow('wallet_transaction_model.body.8', '모집 미달 환불'),
      'diamond_box_collect' => RemainingSurface.trNow('wallet_transaction_model.body.9', '다이아 수집'),
      'effort_value_mint' => RemainingSurface.trNow('wallet_transaction_model.body.10', '러닝 땀방울 적립'),
      'onboarding_signup_reward' => RemainingSurface.trNow('wallet_transaction_model.body.11', '신규 가입 보상'),
      'signup_free_ticket' => RemainingSurface.trNow('wallet_transaction_model.body.12', '첫 경기 무료 참가권'),
      'trial_milestone_reward' => RemainingSurface.trNow('wallet_transaction_model.body.13', '예비 러닝 3회 달성'),
      'referral_reward' => RemainingSurface.trNow('wallet_transaction_model.body.14', '추천인 보상 (지연 지급)'),
      'referral_redeem' => RemainingSurface.trNow('wallet_transaction_model.body.15', '초대 코드 등록'),
      'referral_trial_referee_1' => RemainingSurface.trNow('wallet_transaction_model.body.16', '체험 런 1회'),
      'referral_trial_referee' => RemainingSurface.trNow('wallet_transaction_model.body.17', '체험 런 3회 완료'),
      'referral_trial_referrer' => RemainingSurface.trNow('wallet_transaction_model.body.18', '친구 체험 런 3회'),
      'referral_trial_referrer_hold' => RemainingSurface.trNow('wallet_transaction_model.body.19', '친구 체험 런 3회 대기'),
      'mercy_rule_donation' => RemainingSurface.trNow('wallet_transaction_model.body.20', '자비로운 실패 기부'),
      'winner_reward_claim_all' => RemainingSurface.trNow('wallet_transaction_model.body.21', '우승 상금 수령'),
      'winner_reward_donate_half' => RemainingSurface.trNow('wallet_transaction_model.body.22', '우승 상금 50% 기부'),
      'winner_reward_donate_all' => RemainingSurface.trNow('wallet_transaction_model.body.23', '우승 상금 전액 기부'),
      'sponsor_payment_verified' => RemainingSurface.trNow('wallet_transaction_model.body.24', '스폰서 결제'),
      'web3_transfer' => RemainingSurface.trNow('wallet_transaction_model.body.25', 'Web3 외부 전송'),
      'deposit_forfeiture_fraud' => RemainingSurface.trNow('wallet_transaction_model.body.26', '부정 러닝 예치금 몰수'),
      'pedometer_harvest' => RemainingSurface.trNow('wallet_transaction_model.body.27', '워킹챌린지 코인 줍기'),
      'step_incubator_hatch' => RemainingSurface.trNow('wallet_transaction_model.body.28', '만보기 부화'),
      'donation_match' => RemainingSurface.trNow('items.donation_match_ticket', '기부 매칭권'),
      'personal_sponsor_donation' => RemainingSurface.trNow('wallet_transaction_model.body.29', '기부 완료'),
      'personal_sponsor_prize' => RemainingSurface.trNow('wallet_transaction_model.body.30', '챌린지 상금 지원 후원'),
      'cosmetic_equip' => RemainingSurface.trNow('wallet_transaction_model.body.31', '코스메틱 장착'),
      'debug_test_grant_1m' => RemainingSurface.trNow('wallet_transaction_model.body.32', '디버그 테스트 지급'),
      'share_to_dia' => RemainingSurface.trNow('wallet_transaction_model.body.33', 'SHARE → 다이아 전환'),
      'dia_pack_purchase' => RemainingSurface.trNow('wallet_transaction_model.body.34', '다이아 구매'),
      'streak_bonus' => RemainingSurface.trNow('wallet_transaction_model.body.35', '연속 달리기 보너스'),
      'nickname_change' => RemainingSurface.trNow('wallet_transaction_model.body.36', '닉네임 변경'),
      'crew_create' => RemainingSurface.trNow('running_crew.button', '크루 만들기'),
      'crew_item_gift' => RemainingSurface.trNow('wallet_transaction_model.body.37', '크루 선물'),
      'crew_cheer_share' => RemainingSurface.trNow('wallet_transaction_model.body.38', '크루 응원 SHARE'),
      'challenge_room_create' => RemainingSurface.trNow('wallet_transaction_model.body.39', '대회 열기'),
      'hall_of_fame_donation' => RemainingSurface.trNow('wallet_transaction_model.body.40', '명예의 전당 기부'),
      'free_entry' => RemainingSurface.trNow('wallet_transaction_model.body.41', '무료 대회 참가'),
      'ticket_grant' => RemainingSurface.trNow('wallet_transaction_model.body.42', '참가권 지급'),
      'ticket_share_fallback' => RemainingSurface.trNow('wallet_transaction_model.body.43', '참가권 대신 SHARE 지급'),
      'referral_trial_referrer_clawback' => RemainingSurface.trNow('wallet_transaction_model.body.44', '친구 체험 보상 회수'),
      'trial_referrer' => RemainingSurface.trNow('wallet_transaction_model.body.18', '친구 체험 런 3회'),
      'cpr_coach_plus_grant' => RemainingSurface.trNow('wallet_transaction_model.body.45', 'Coach+ 심폐소생권 지급'),
      _ => type,
    };
  }

  String get amountSummary {
    final parts = <String>[];
    final debit = _isDebitType;

    if (shareAmount != 0) {
      parts.add(_formatAmount(shareAmount, 'SHARE', debit: debit || shareAmount < 0));
    }
    if (valueAmount != 0) {
      parts.add(_formatAmount(valueAmount, 'VALUE', debit: valueAmount < 0));
    }
    if (diamondAmount != 0) {
      parts.add(_formatAmount(diamondAmount, 'DIA', debit: diamondAmount < 0));
    }
    if (ticketAmount != 0) {
      parts.add(_formatAmount(ticketAmount, RemainingSurface.trNow('wallet_transaction_model.body.46', '참가권'), debit: ticketAmount < 0));
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  bool get _isDebitType {
    return switch (type) {
      'tournament_entry' ||
      'cash_refund_requested' ||
      'shop_purchase' ||
      'web3_transfer' ||
      'personal_sponsor_donation' ||
      'personal_sponsor_prize' =>
        true,
      _ => false,
    };
  }

  String _formatAmount(int amount, String unit, {required bool debit}) {
    final absolute = amount.abs();
    final sign = debit ? '-' : '+';
    return '$sign$absolute $unit';
  }

  factory WalletTransactionModel.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final createdAt = data['createdAt'];
    DateTime? createdDate;
    if (createdAt is Timestamp) {
      createdDate = createdAt.toDate();
    }

    return WalletTransactionModel(
      id: id,
      type: data['type'] as String? ?? 'unknown',
      shareAmount: (data['shareAmount'] as num?)?.toInt() ?? 0,
      valueAmount: (data['valueAmount'] as num?)?.toInt() ?? 0,
      diamondAmount: (data['diamondAmount'] as num?)?.toInt() ?? 0,
      createdAt: createdDate,
      tournamentId: data['tournamentId'] as String?,
      itemId: data['itemId'] as String?,
      ticketAmount: (data['ticketAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 서버 원장 한 쪽. [cursor]를 다음 쪽 요청에 그대로 넘긴다.
class WalletHistoryPage {
  const WalletHistoryPage({
    required this.rows,
    required this.cursor,
    required this.hasMore,
  });

  final List<WalletTransactionModel> rows;
  final Object? cursor;
  final bool hasMore;
}
